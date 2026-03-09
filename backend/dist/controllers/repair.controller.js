"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.RepairController = void 0;
const zod_1 = require("zod");
const ai_service_1 = require("../services/ai.service");
/**
 * Zod Schema for input validation
 * Based on SRS V2.1: description string is required.
 */
const IntentRequestSchema = zod_1.z.object({
    description: zod_1.z.string().min(5, "Description must be at least 5 characters long").max(500),
});
class RepairController {
    /**
     * Post /api/repair/intent
     * Processes natural language repair requests.
     */
    static async processIntent(req, res) {
        const startTime = Date.now();
        try {
            // 1. Validation
            const validated = IntentRequestSchema.parse(req.body);
            // 2. AI Processing (with internal fallback logic)
            const data = await ai_service_1.AIService.analyzeRepairIntent(validated.description);
            // Performance check (SRS requirements: < 10 seconds)
            const totalTime = (Date.now() - startTime) / 1000;
            console.log(`Intent analyzed in ${totalTime}s`);
            return res.status(200).json({
                success: true,
                data,
                metadata: {
                    processing_time_sec: totalTime,
                },
            });
        }
        catch (error) {
            if (error instanceof zod_1.z.ZodError) {
                return res.status(400).json({
                    success: false,
                    error: "INVALID_INPUT",
                    details: error.issues,
                });
            }
            // 3. Fallback logic: "FALLBACK_TO_MANUAL" (Per User Request)
            // Triggered if Gemini fails, rate limited, or any system error occurs.
            console.error("Falling back to manual entry due to error:", error);
            return res.status(202).json({
                success: false,
                status: "FALLBACK_TO_MANUAL",
                message: "AI analysis unavailable. Please fill out form manually.",
            });
        }
    }
}
exports.RepairController = RepairController;
