import { Request, Response } from "express";
import { v4 as uuidv4 } from "uuid";
import { db } from "../database";
import { AIService, DBObject } from "../services/ai.service";

export const chatController = {
    // 1. Get all conversations for a resident
    getConversations: async (req: Request, res: Response) => {
        try {
            const residentId = (req as any).user.id;

            const convos = db.prepare(`
        SELECT * FROM ai_conversations
        WHERE resident_id = ?
        ORDER BY updated_at DESC
      `).all(residentId);

            return res.status(200).json({ success: true, data: convos });
        } catch (error: any) {
            console.error("[ChatController] getConversations Error:", error);
            return res.status(500).json({ success: false, error: "Internal Server Error" });
        }
    },

    // 2. Get messages for a specific conversation
    getMessages: async (req: Request, res: Response) => {
        try {
            const { conversationId } = req.params;
            const residentId = (req as any).user.id;

            // Verify ownership
            const convo = db.prepare(`SELECT id FROM ai_conversations WHERE id = ? AND resident_id = ?`)
                .get(conversationId, residentId);

            if (!convo) {
                return res.status(403).json({ success: false, error: "Access denied or conversation not found." });
            }

            const messages = db.prepare(`
        SELECT * FROM ai_messages
        WHERE conversation_id = ?
        ORDER BY created_at ASC
      `).all(conversationId);

            return res.status(200).json({ success: true, data: messages });
        } catch (error: any) {
            console.error("[ChatController] getMessages Error:", error);
            return res.status(500).json({ success: false, error: "Internal Server Error" });
        }
    },

    // 3. User sends a message (creates conversation if not exists, triggers AI, returns AI reply)
    sendMessage: async (req: Request, res: Response) => {
        try {
            const residentId = (req as any).user.id;
            const { content, conversationId } = req.body;

            if (!content) {
                return res.status(400).json({ success: false, error: "Message content is required" });
            }

            // Handle Conversation Tracking
            let convoId = conversationId;
            if (!convoId) {
                convoId = uuidv4();
                const shortTitle = content.length > 20 ? content.substring(0, 20) + "..." : content;

                db.prepare(`
          INSERT INTO ai_conversations (id, resident_id, title, last_message, is_archived)
          VALUES (?, ?, ?, ?, 0)
        `).run(convoId, residentId, `Chat: ${shortTitle}`, content);
            } else {
                // Check if the conversation is archived
                const existingConvo = db.prepare('SELECT is_archived FROM ai_conversations WHERE id = ?').get(convoId) as any;
                if (existingConvo && existingConvo.is_archived) {
                    return res.status(403).json({ success: false, error: "Cannot send messages to an archived conversation." });
                }
            }

            // Save User Message
            const userMsgId = uuidv4();
            db.prepare(`
        INSERT INTO ai_messages (id, conversation_id, sender_type, content)
        VALUES (?, ?, 'USER', ?)
      `).run(userMsgId, convoId, content);

            // Fetch Objects for Context (Required by AIService)
            const userProp = db.prepare(`
        SELECT id FROM properties
        WHERE house_number = (
          SELECT r.house_number FROM real_estate_records r
          INNER JOIN users u ON u.national_id = r.national_id
          WHERE u.id = ?
        )
      `).get(residentId) as any;

            let objects: DBObject[] = [];
            if (userProp) {
                objects = db.prepare(`SELECT id, object_name, category FROM object WHERE property_id = ?`)
                    .all(userProp.id) as DBObject[];
            }

            // Fetch Resident Info for Context
            const residentInfo = db.prepare(`
              SELECT u.full_name as name, u.email, u.phone, r.house_number 
              FROM users u
              LEFT JOIN real_estate_records r ON u.national_id = r.national_id
              WHERE u.id = ?
            `).get(residentId) as any;

            // Fetch Chat History for Context
            const historyRaw = db.prepare(`
              SELECT sender_type, content 
              FROM ai_messages 
              WHERE conversation_id = ? AND id != ?
              ORDER BY created_at ASC 
              LIMIT 10
            `).all(convoId, userMsgId) as any[];
            const chatHistoryStr = historyRaw.map(m => `${m.sender_type}: ${m.content}`).join("\n");

            // Call AI Service
            const aiResult = await AIService.analyzeRepairIntent(content, objects, residentInfo, chatHistoryStr);

            // Extract AI Reply
            const aiReplyText = aiResult.follow_up_message || aiResult.message || "ระบบได้รับข้อมูลของคุณแล้วค่ะ";

            // Save AI Message with Action Data if present
            const aiMsgId = uuidv4();
            let actionData = null;
            let actionState = 'none';

            if (aiResult.request && aiResult.request.tasks && aiResult.request.tasks.length > 0) {
                actionData = JSON.stringify(aiResult.request);
                actionState = 'pending';
            }

            db.prepare(`
        INSERT INTO ai_messages (id, conversation_id, sender_type, content, action_data, action_state)
        VALUES (?, ?, 'AI', ?, ?, ?)
      `).run(aiMsgId, convoId, aiReplyText, actionData, actionState);

            // Update Conversation Last Message
            db.prepare(`
        UPDATE ai_conversations SET last_message = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?
      `).run(aiReplyText, convoId);

            // Return both the newly created messages and the JSON payload in case the app needs to render a Task Card
            return res.status(200).json({
                success: true,
                data: {
                    conversation_id: convoId,
                    user_message_id: userMsgId,
                    ai_message_id: aiMsgId,
                    reply_text: aiReplyText,
                    intent_result: aiResult,
                    resident_info: residentInfo
                }
            });

        } catch (error: any) {
            console.error("[ChatController] sendMessage Error:", error);
            return res.status(500).json({ success: false, error: "Internal Server Error", details: error.message, stack: error.stack });
        }
    },

    deleteConversation: async (req: Request, res: Response) => {
        try {
            const { conversationId } = req.params;
            const residentId = (req as any).user.id;

            // Verify ownership
            const convo = db.prepare('SELECT id FROM ai_conversations WHERE id = ? AND resident_id = ?').get(conversationId, residentId);
            if (!convo) {
                return res.status(404).json({ success: false, error: "Conversation not found or unauthorized" });
            }

            // Delete messages first (foreign key constraint)
            db.prepare('DELETE FROM ai_messages WHERE conversation_id = ?').run(conversationId);
            // Delete conversation
            db.prepare('DELETE FROM ai_conversations WHERE id = ?').run(conversationId);

            return res.status(200).json({ success: true, message: "Conversation deleted successfully" });
        } catch (error: any) {
            console.error("[ChatController] deleteConversation Error:", error);
            return res.status(500).json({ success: false, error: "Internal Server Error" });
        }
    },

    archiveConversation: async (req: Request, res: Response) => {
        try {
            const { conversationId } = req.params;
            const residentId = (req as any).user.id;

            // Verify ownership
            const convo = db.prepare('SELECT id FROM ai_conversations WHERE id = ? AND resident_id = ?').get(conversationId, residentId);
            if (!convo) {
                return res.status(404).json({ success: false, error: "Conversation not found or unauthorized" });
            }

            db.prepare('UPDATE ai_conversations SET is_archived = 1, updated_at = CURRENT_TIMESTAMP WHERE id = ?').run(conversationId);

            return res.status(200).json({ success: true, message: "Conversation archived successfully" });
        } catch (error: any) {
            console.error("[ChatController] archiveConversation Error:", error);
            return res.status(500).json({ success: false, error: "Internal Server Error" });
        }
    },

    updateMessageActionState: async (req: Request, res: Response) => {
        try {
            const { messageId } = req.params;
            const { action_state } = req.body;
            // The request should come from the resident who owns the conversation
            const residentId = (req as any).user.id;

            // Verify ownership via conversation
            const msg = db.prepare(`
                SELECT m.id 
                FROM ai_messages m
                JOIN ai_conversations c ON m.conversation_id = c.id
                WHERE m.id = ? AND c.resident_id = ?
            `).get(messageId, residentId);

            if (!msg) {
                return res.status(404).json({ success: false, error: "Message not found or unauthorized" });
            }

            db.prepare('UPDATE ai_messages SET action_state = ? WHERE id = ?').run(action_state, messageId);

            return res.status(200).json({ success: true, message: "Action state updated successfully" });
        } catch (error: any) {
            console.error("[ChatController] updateMessageAction Error:", error);
            return res.status(500).json({ success: false, error: "Internal Server Error" });
        }
    }
};
