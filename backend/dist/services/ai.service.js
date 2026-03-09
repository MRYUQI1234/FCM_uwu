"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AIService = void 0;
const generative_ai_1 = require("@google/generative-ai");
const dotenv_1 = __importDefault(require("dotenv"));
dotenv_1.default.config();
const genAI = new generative_ai_1.GoogleGenerativeAI(process.env.GEMINI_API_KEY || "");
class AIService {
    static model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
    static async analyzeRepairIntent(description) {
        const prompt = `
      You are an AI assistant for a Facility Management System (FCM) at Vivorn Villa.
      Categorize the following repair request from a resident into a JSON object.

      Categories: Electrical, Plumbing, Structural, Common Area, Pest Control, Appliance Repair, Other.
      Urgency levels: Low, Medium, High.

      Resident Request: "${description}"

      The JSON object MUST follow this structure:
      {
        "category": string,
        "urgency": "Low" | "Medium" | "High",
        "location": string,
        "confidence_score": number (0 to 1)
      }

      Provide ONLY the raw JSON output. No conversational text.
    `;
        try {
            const result = await this.model.generateContent(prompt);
            const response = await result.response;
            let text = response.text();
            // Basic cleanup in case Gemini wraps in markdown
            if (text.startsWith("```json")) {
                text = text.replace(/```json|```/g, "").trim();
            }
            const parsed = JSON.parse(text);
            return {
                category: parsed.category || "Other",
                urgency: parsed.urgency || "Medium",
                location: parsed.location || "Not Specified",
                confidence_score: parsed.confidence_score || 0.5,
            };
        }
        catch (error) {
            console.error("Gemini API Error:", error);
            throw new Error("AI_PROCESSING_FAILED");
        }
    }
}
exports.AIService = AIService;
