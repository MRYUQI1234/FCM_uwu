import { GoogleGenerativeAI } from "@google/generative-ai";
import dotenv from "dotenv";
import { db } from "../database";

dotenv.config();

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || "");

export interface DBObject {
  id: string;
  object_name: string;
  category: string;
}

export interface TaskRecord {
  object_id: string | null;
  object_type: string;
  description: string;
  urgency: "normal" | "emergency";
  status: string;
  prefer_date: string;
}

export interface RequestRecord {
  status: string;
  tasks: TaskRecord[];
}

export interface IntentResult {
  request?: RequestRecord;
  confidence_score?: number;
  follow_up_message?: string | null;
  fallback_required?: boolean;
  error_type?: string;
  message?: string;
  raw_prompt?: string;
  raw_response?: string;
  usage_metadata?: any;
}

export class AIService {
  private static model = genAI.getGenerativeModel({ model: "gemini-3.1-flash-lite-preview" });

  static async analyzeRepairIntent(
    description: string,
    availableObjects: DBObject[],
    residentInfo?: { name: string; house_number: string },
    chatHistory?: string
  ): Promise<IntentResult> {
    const startTime = Date.now();
    const objectsContext = availableObjects
      .map(obj => `- ID: ${obj.id}, Name: ${obj.object_name}, Category: ${obj.category}`)
      .join("\n");

    const prompt = `
      You are a Senior AI Assistant for Vivorn Villa (High-end Estate).
      Your job is to talk politely with the resident, answer questions based on context, and parse maintenance requests into JSON.

      RESIDENT CONTEXT:
      Name: ${residentInfo?.name || "Unknown"}
      House Number: ${residentInfo?.house_number || "Unknown"}

      AVAILABLE HARDWARE IN RESIDENCE:
      ${objectsContext}

      PREVIOUS CHAT HISTORY:
      ${chatHistory || "No previous history."}

      CURRENT RESIDENT INPUT: "${description}"

      RULES:
      1. URGENCIES: Default 'normal'. 'emergency' ONLY if "Pipe burst" (ท่อแตก) or "Total blackout" (ไฟดับทั้งบ้าน).
      2. TIME SLOTS: Normalized to 09:30:00 or 13:00:00.
      3. prefer_date cannot be in the past. If null, ask for clarification.
      4. LANGUAGE: follow_up_message and descriptions MUST match Input language.
      5. Mapping: Use Context IDs. object_type from Category. Include object_name from Name.
      6. CLARIFICATION: If the user mentions a problem but the description is vague (e.g., 'broken', 'not working', 'ชำรุด'), you MUST ask for specific details about the issue before finalizing the JSON request. Do NOT return the "tasks" array if you do not have a clear description of the damage.

      JSON:
      {
        "request": { "status": "Created", "tasks": [ {"object_id": "...", "object_name": "...", "object_type": "...", "description": "...", "urgency": "normal"} ] },
        "follow_up_message": "...",
        "confidence_score": 0.9
      }
    `;

    console.log("-----------------------------------------");
    console.log("[AIService] GENERATED PROMPT:");
    console.log(prompt);
    console.log("-----------------------------------------");

    try {
      const result = await this.model.generateContent(prompt);
      const response = await result.response;
      let text = response.text();

      // Strip markdown code fences if present
      if (text.includes("```json")) {
        text = text.replace(/```json|```/g, "").trim();
      }

      // Extract JSON block from response — Gemini often wraps it in prose text
      // We look for the first '{' to last '}' to isolate the JSON
      const jsonStart = text.indexOf("{");
      const jsonEnd = text.lastIndexOf("}");

      if (jsonStart !== -1 && jsonEnd !== -1 && jsonEnd > jsonStart) {
        const jsonStr = text.substring(jsonStart, jsonEnd + 1);
        try {
          const parsed = JSON.parse(jsonStr);
          // If there's prose text before the JSON, it may be a fallback message
          // Prefer the follow_up_message from JSON, but log any prefix text
          const prefixText = text.substring(0, jsonStart).trim();
          if (prefixText) {
            console.log("[AIService] Prose prefix before JSON (ignored):", prefixText);
          }
          return {
            ...parsed,
            raw_prompt: prompt,
            raw_response: text,
            usage_metadata: response.usageMetadata
          };
        } catch {
          // JSON extraction failed even though we found braces — fall through to conversational
          console.log("[AIService] JSON extraction failed, treating as conversational.");
        }
      }

      // Gemini gave a purely conversational reply with no JSON
      console.log("[AIService] Conversational reply (no JSON).");
      return {
        follow_up_message: text,
        confidence_score: 1.0,
        raw_prompt: prompt,
        raw_response: text,
        usage_metadata: response.usageMetadata
      };
    } catch (error: any) {
      const processingTime = (Date.now() - startTime) / 1000;
      const errorMessage = error.message || "Unknown Gemini Error";

      // SRS Reliability-1: Log failure to ai_log even on error
      // Using explicit 0 for success_flag
      try {
        db.prepare(`
          INSERT INTO ai_log (raw_prompt, raw_response, success_flag, error_message, processing_time_sec)
          VALUES (?, ?, 0, ?, ?)
        `).run(prompt, "N/A", errorMessage, processingTime);
      } catch (logErr) {
        console.error("Failed to log AI error to DB:", logErr);
      }

      // Elegant Fallback for 503/429
      if (errorMessage.includes("503") || errorMessage.includes("429") || errorMessage.includes("overloaded")) {
        return {
          request: { status: "Created", tasks: [] },
          follow_up_message: null,
          confidence_score: 0,
          fallback_required: true,
          error_type: "API_OVERLOAD",
          message: "ขออภัยค่ะตอนนี้ระบบมีการใช้งานมากเกินไป โปรดรอสักครู่แล้วลองใหม่ค่ะ",
          raw_prompt: prompt,
          raw_response: errorMessage
        };
      }

      throw error;
    }
  }
}
