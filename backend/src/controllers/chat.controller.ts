import { Request, Response } from "express";
import { v4 as uuidv4 } from "uuid";
import { db } from "../database";
import { AIService, DBObject } from "../services/ai.service";

export const chatController = {
    // 1. ดึงรายการบทสนทนาทั้งหมดของ user_id ปัจจุบัน
    getConversations: async (req: Request, res: Response) => {
        try {
            const userId = (req as any).user.id;

            console.log(`[ChatController] Fetching conversations for user: ${userId}`);
            const conversations = db.prepare(`
                SELECT 
                    c.conversation_id as id, 
                    c.user_id as resident_id, 
                    c.title, 
                    c.complete as is_archived, 
                    c.created_at, 
                    c.created_at as updated_at,
                    (SELECT message FROM ai_messages WHERE conversation_id = c.conversation_id ORDER BY created_at DESC LIMIT 1) as last_message
                FROM ai_conversation c
                WHERE c.user_id = ?
                ORDER BY c.created_at DESC
            `).all(userId);

            console.log(`[ChatController] Found ${conversations.length} conversations`);
            return res.status(200).json({ success: true, data: conversations });
        } catch (error: any) {
            console.error("[ChatController] getConversations Error:", error);
            return res.status(500).json({ success: false, error: "Internal Server Error" });
        }
    },

    // 2. ส่งข้อความและประมวลผลด้วย Gemini AI
    sendMessage: async (req: Request, res: Response) => {
        const startTime = Date.now();
        const timeout = 10000;
        const residentId = (req as any).user.id;
        const { content, conversationId, preferredLanguage = "th" } = req.body;
        let activeConvoId = conversationId;

        if (!content) {
            return res.status(400).json({ success: false, error: "Message content is required" });
        }

        try {
            // 1. Identify/Create Conversation
            if (!activeConvoId) {
                activeConvoId = uuidv4();
                const shortTitle = content.length > 20 ? content.substring(0, 20) + "..." : content;
                db.prepare(`
                    INSERT INTO ai_conversation (conversation_id, user_id, title, last_message_id, complete)
                    VALUES (?, ?, ?, 'pending', 0)
                `).run(activeConvoId, residentId, shortTitle);
            } else {
                // Check if archived
                const convo = db.prepare("SELECT complete FROM ai_conversation WHERE conversation_id = ?").get(activeConvoId) as any;
                if (convo?.complete === 1) {
                    return res.status(403).json({ success: false, error: "Conversation is archived/completed" });
                }
            }

            // 2. Save User Message
            const userMsgId = uuidv4();
            db.prepare(`
                INSERT INTO ai_messages (message_id, conversation_id, owner, message, log_id)
                VALUES (?, ?, 'USER', ?, 'USER_MSG')
            `).run(userMsgId, activeConvoId, content);

            // Context Gathering
            const residentInfo = db.prepare(`
                SELECT re.fullname as name, h.house_address as house_number 
                FROM user u
                LEFT JOIN real_estate re ON u.national_id = re.national_id
                LEFT JOIN house h ON u.national_id = h.national_id
                WHERE u.user_id = ?
            `).get(residentId) as any;

            const history = db.prepare(`
                SELECT owner, message 
                FROM ai_messages 
                WHERE conversation_id = ? AND message_id != ?
                ORDER BY created_at DESC 
                LIMIT 5
            `).all(activeConvoId, userMsgId) as any[];
            const chatHistoryStr = history.reverse().map(m => `${m.owner}: ${m.message}`).join("\n");

            // 3. Call Gemini (with timeout protection)
            const aiPromise = AIService.analyzeRepairIntent(
                content,
                residentInfo,
                chatHistoryStr,
                preferredLanguage
            );

            // Timeout wrapper
            const aiResult = await Promise.race([
                aiPromise,
                new Promise<null>((_, reject) => setTimeout(() => reject(new Error("Timeout")), timeout - 500))
            ]) as any;

            console.log(`[ChatController] Result: AI task mapping = ${aiResult.request?.tasks?.length || 0}`);

            const processingTime = (Date.now() - startTime) / 1000;

            // 4. Log Performance
            const logResult = db.prepare(`
                INSERT INTO ai_log (raw_prompt, raw_response, success_flag, processing_time_sec)
                VALUES (?, ?, 1, ?)
            `).run(aiResult.raw_prompt || "N/A", aiResult.raw_response || "N/A", processingTime);
            
            const logId = logResult.lastInsertRowid.toString();

            // 5. Save AI Response
            const aiMsgId = uuidv4();
            const aiReplyText = aiResult.follow_up_message || aiResult.message || "ระบบได้รับข้อมูลของคุณแล้วค่ะ";
            let actionData = aiResult.request && aiResult.request.tasks?.length > 0 ? JSON.stringify(aiResult.request) : null;
            let actionState = actionData ? "pending" : "none";

            db.prepare(`
                INSERT INTO ai_messages (message_id, conversation_id, owner, message, action_data, action_state, log_id)
                VALUES (?, ?, 'AI', ?, ?, ?, ?)
            `).run(aiMsgId, activeConvoId, aiReplyText, actionData, actionState, logId);

            // Update Conversation
            db.prepare(`
                UPDATE ai_conversation SET last_message_id = ? WHERE conversation_id = ?
            `).run(aiMsgId, activeConvoId);

            return res.status(200).json({
                success: true,
                data: {
                    reply_text: aiReplyText,
                    conversation_id: activeConvoId,
                    ai_message_id: aiMsgId,
                    action_data: actionData,
                    action_state: actionState,
                    intent_result: aiResult, // Contains 'request' and 'tasks'
                    resident_info: residentInfo ? {
                        name: residentInfo.name,
                        house_number: residentInfo.house_number
                    } : null
                }
            });

        } catch (error: any) {
            console.error("[ChatController] sendMessage Error:", error);

            // Fallback: If error or timeout
            const processingTime = (Date.now() - startTime) / 1000;
            const logResult = db.prepare(`
                INSERT INTO ai_log (raw_prompt, raw_response, success_flag, error_message, processing_time_sec)
                VALUES (?, ?, 0, ?, ?)
            `).run("N/A", "N/A", error.message || "Unknown Error", processingTime);

            const aiMsgId = uuidv4();
            const fallbackMsg = preferredLanguage === 'zh' ? "抱歉，系统处理出错。请手动通过3D模型提交维修申请，或稍后再试。" :
                preferredLanguage === 'en' ? "Sorry, a processing error occurred. Please report the repair manually via the 3D model or try again later." :
                    "ขออภัยค่ะ ระบบประมวลผลขัดข้อง โปรดดำเนินการแจ้งซ่อมผ่านโมเดล 3 มิติด้วยตนเอง หรือลองใหม่อีกครั้งในภายหลัง";

            if (activeConvoId) {
                db.prepare(`
                    INSERT INTO ai_messages (message_id, conversation_id, owner, message, log_id)
                    VALUES (?, ?, 'AI', ?, ?)
                `).run(aiMsgId, activeConvoId, fallbackMsg, logResult.lastInsertRowid.toString());
            }

            return res.status(200).json({
                success: true,
                data: {
                    reply_text: fallbackMsg,
                    conversation_id: activeConvoId || "new",
                    ai_message_id: aiMsgId,
                    action_data: null,
                    action_state: "none",
                    intent_result: null,
                    resident_info: null
                }
            });
        }
    },

    // 3. อัปเดต action_state ของข้อความ
    updateMessageActionState: async (req: Request, res: Response) => {
        try {
            const { id } = req.params;
            const { action_state } = req.body;
            const userId = (req as any).user.id;

            // Verify ownership
            const msg = db.prepare(`
                SELECT m.message_id 
                FROM ai_messages m
                JOIN ai_conversation c ON m.conversation_id = c.conversation_id
                WHERE m.message_id = ? AND c.user_id = ?
            `).get(id, userId);

            if (!msg) {
                return res.status(404).json({ success: false, error: "Message not found or unauthorized" });
            }

            db.prepare("UPDATE ai_messages SET action_state = ? WHERE message_id = ?").run(action_state, id);

            return res.status(200).json({ success: true, message: "Action state updated" });
        } catch (error: any) {
            console.error("[ChatController] updateAction Error:", error);
            return res.status(500).json({ success: false, error: "Internal Server Error" });
        }
    },

    // 4. ยุติบทสนทนา (Archive)
    archiveConversation: async (req: Request, res: Response) => {
        try {
            const { id } = req.params;
            const userId = (req as any).user.id;

            const convo = db.prepare("SELECT conversation_id FROM ai_conversation WHERE conversation_id = ? AND user_id = ?")
                .get(id, userId);

            if (!convo) {
                return res.status(404).json({ success: false, error: "Conversation not found or unauthorized" });
            }

            db.prepare("UPDATE ai_conversation SET complete = 1 WHERE conversation_id = ?").run(id);

            return res.status(200).json({ success: true, message: "Conversation archived" });
        } catch (error: any) {
            console.error("[ChatController] archive Error:", error);
            return res.status(500).json({ success: false, error: "Internal Server Error" });
        }
    },

    // Added: Get messages for UI
    getMessages: async (req: Request, res: Response) => {
        try {
            const { conversationId } = req.params;
            const userId = (req as any).user.id;

            const convo = db.prepare("SELECT conversation_id FROM ai_conversation WHERE conversation_id = ? AND user_id = ?").get(conversationId, userId);
            if (!convo) return res.status(403).json({ success: false, error: "Unauthorized" });

            const messages = db.prepare(`
                SELECT 
                    message_id as id, 
                    conversation_id, 
                    owner as sender_type, 
                    message as content, 
                    action_data, 
                    action_state, 
                    created_at 
                FROM ai_messages 
                WHERE conversation_id = ? 
                ORDER BY created_at ASC
            `).all(conversationId);
            return res.status(200).json({ success: true, data: messages });
        } catch (error: any) {
            return res.status(500).json({ success: false });
        }
    },

    // 6. ลบบทสนทนา
    deleteConversation: async (req: Request, res: Response) => {
        try {
            const { id } = req.params;
            const userId = (req as any).user.id;

            // Verify ownership
            const convo = db.prepare("SELECT conversation_id FROM ai_conversation WHERE conversation_id = ? AND user_id = ?")
                .get(id, userId);

            if (!convo) {
                return res.status(404).json({ success: false, error: "Conversation not found or unauthorized" });
            }

            // Transactional Delete
            const deleteTx = db.transaction(() => {
                db.prepare("DELETE FROM ai_messages WHERE conversation_id = ?").run(id);
                db.prepare("DELETE FROM ai_conversation WHERE conversation_id = ?").run(id);
            });

            deleteTx();

            return res.status(200).json({ success: true, message: "Conversation deleted successfully" });
        } catch (error: any) {
            console.error("[ChatController] delete Error:", error);
            return res.status(500).json({ success: false, error: "Internal Server Error" });
        }
    }
};
