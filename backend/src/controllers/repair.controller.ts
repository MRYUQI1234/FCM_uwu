import { Request, Response } from "express";
import { v4 as uuidv4 } from "uuid";
import { z } from "zod";
import { db } from "../database";
import { AIService, DBObject } from "../services/ai.service";

const IntentRequestSchema = z.object({
  description: z.string().min(5).max(1000),
});

const TaskUpdateSchema = z.object({
  status: z.enum(["InProgress", "Completed"]),
  task_report: z.string().optional(),
  after_repair_image_url: z.string().url().optional(),
});

const EvaluationSchema = z.object({
  request_id: z.string(),
  rating: z.number().min(1).max(5),
  comment: z.string().max(500).optional(),
});

export class RepairController {
  /**
   * GET /api/repair/history
   * Returns all requests (with tasks) for the resident's property.
   * Security: filtered by property_id derived from user's national_id.
   */
  static async getResidentHistory(req: Request, res: Response) {
    try {
      const userId = (req as any).user.id;

      // 1. Get user's national_id
      const user = db.prepare("SELECT national_id FROM users WHERE id = ?").get(userId) as any;
      if (!user) return res.status(404).json({ success: false, status_code: "USER_NOT_FOUND" });

      // 2. Get house_number from real_estate_records
      const estate = db.prepare("SELECT house_number FROM real_estate_records WHERE national_id = ?").get(user.national_id) as any;
      if (!estate) return res.status(404).json({ success: false, status_code: "PROPERTY_NOT_FOUND" });

      // 3. Get property_id from properties table
      const property = db.prepare("SELECT id FROM properties WHERE house_number = ?").get(estate.house_number) as any;
      if (!property) return res.status(404).json({ success: false, status_code: "PROPERTY_NOT_FOUND" });

      // 4. Fetch all requests for this property with tasks
      const requests = db.prepare(`
        SELECT r.id, r.status, r.technician_id, r.repair_report, r.after_repair_image_url,
               r.completed_at, r.created_at, r.updated_at,
               u_tech.full_name as technician_name
        FROM request r
        LEFT JOIN users u_tech ON r.technician_id = u_tech.id
        WHERE r.property_id = ?
        ORDER BY r.created_at DESC
      `).all(property.id) as any[];

      const result = requests.map((req: any) => {
        const tasks = db.prepare(`
          SELECT t.id, t.description, t.urgency, t.status, t.task_report,
                 t.after_repair_image_url, t.prefer_date,
                 o.object_name, o.category
          FROM task t
          LEFT JOIN object o ON t.object_id = o.id
          WHERE t.request_id = ?
        `).all(req.id);

        return { ...req, tasks };
      });

      return res.status(200).json({ success: true, data: result });

    } catch (error) {
      console.error("History Error:", error);
      return res.status(500).json({ success: false, status_code: "SERVER_ERROR" });
    }
  }

  /**
   * AI Intent Analysis
   */
  static async processIntent(req: Request, res: Response) {
    const startTime = Date.now();
    const mockPropertyId = "prop_200"; // Using seeded property

    try {
      const { description } = IntentRequestSchema.parse(req.body);

      const availableObjects = db.prepare(
        "SELECT id, object_name, category FROM object WHERE property_id = ?"
      ).all(mockPropertyId) as DBObject[];

      const aiResult = await AIService.analyzeRepairIntent(description, availableObjects);
      const processingTimeSec = (Date.now() - startTime) / 1000;

      if (aiResult.fallback_required) {
        return res.status(200).json({
          success: false,
          status_code: "FALLBACK_TO_MANUAL",
          message: aiResult.message
        });
      }

      return res.status(200).json({
        success: true,
        summary: {
          task_count: aiResult.request?.tasks.length || 0,
          confidence: aiResult.confidence_score,
        },
        request_preview: aiResult.request,
        follow_up_message: aiResult.follow_up_message,
        metadata: { processing_time_sec: processingTimeSec }
      });

    } catch (error: any) {
      return res.status(202).json({
        success: false,
        status_code: "FALLBACK_TO_MANUAL",
        message: "ระบบ AI ขัดข้องชั่วคราว โปรดใช้แบบฟอร์มแจ้งซ่อมด้วยตนเองค่ะ"
      });
    }
  }

  /**
   * Confirm Request & Save to DB
   */
  static async confirmRequest(req: Request, res: Response) {
    const user = (req as any).user;
    const residentId = user.id;
    const propertyId = "prop_200"; // Mock property for simplicity or get from user profile
    const requestId = uuidv4();

    try {
      const { request, ai_raw, message_id } = req.body;

      if (!request || !request.tasks || !Array.isArray(request.tasks)) {
        return res.status(400).json({ success: false, status_code: "INVALID_REQUEST", message: "Missing or invalid tasks array" });
      }

      db.transaction(() => {
        if (message_id) {
          db.prepare("UPDATE ai_messages SET action_state = 'confirmed' WHERE id = ?").run(message_id);
        }
        db.prepare(`
          INSERT INTO request (id, resident_id, property_id, status)
          VALUES (?, ?, ?, ?)
        `).run(requestId, residentId, propertyId, 'Created');

        const insertTask = db.prepare(`
          INSERT INTO task (id, request_id, object_id, object_type, description, urgency, status, prefer_date)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `);

        for (const task of request.tasks) {
          const preferDateStr = task.prefer_date ? `${task.prefer_date}${task.prefer_time ? ' ' + task.prefer_time : ''}` : null;
          insertTask.run(uuidv4(), requestId, task.object_id, task.object_type, task.description, task.urgency, 'Pending', preferDateStr);
        }

        if (ai_raw) {
          db.prepare(`
            INSERT INTO ai_log (request_id, raw_prompt, raw_response, tokens_used, success_flag, processing_time_sec)
            VALUES (?, ?, ?, ?, 1, ?)
          `).run(requestId, ai_raw.prompt, ai_raw.response, ai_raw.total_tokens || 0, ai_raw.time);
        }
      })();

      return res.status(201).json({ success: true, request_id: requestId, status_code: "REQUEST_CREATED" });

    } catch (error: any) {
      console.error("[RepairController] confirmRequest Error:", error);
      return res.status(500).json({ success: false, status_code: "DATABASE_ERROR", details: error.message });
    }
  }

  /**
   * Technician: Update Task Status (FE-03)
   */
  static async updateTaskStatus(req: Request, res: Response) {
    try {
      const { taskId } = req.params;
      const { status, task_report, after_repair_image_url } = TaskUpdateSchema.parse(req.body);

      // Validate Task exists
      const task = db.prepare("SELECT request_id FROM task WHERE id = ?").get(taskId) as any;
      if (!task) return res.status(404).json({ success: false, status_code: "TASK_NOT_FOUND" });

      // Update Task
      db.prepare(`
        UPDATE task 
        SET status = ?, task_report = ?, after_repair_image_url = ? 
        WHERE id = ?
      `).run(status, task_report || null, after_repair_image_url || null, taskId);

      // Check if all tasks in the request are completed
      const requestId = task.request_id;
      const pendingTasks = db.prepare("SELECT COUNT(*) as count FROM task WHERE request_id = ? AND status != 'Completed'").get(requestId) as any;

      if (pendingTasks.count === 0) {
        // Automatic Request Completion
        db.prepare(`
          UPDATE request 
          SET status = 'Completed', completed_at = CURRENT_TIMESTAMP 
          WHERE id = ?
        `).run(requestId);

        return res.json({ success: true, status_code: "REQUEST_FULLY_COMPLETED" });
      }

      return res.json({ success: true, status_code: "TASK_UPDATED" });

    } catch (error: any) {
      if (error instanceof z.ZodError) return res.status(400).json({ success: false, errors: error.issues });
      return res.status(500).json({ success: false, status_code: "SERVER_ERROR" });
    }
  }

  /**
   * Resident: Submit Evaluation (Feedback System)
   */
  static async submitEvaluation(req: Request, res: Response) {
    try {
      const { request_id, rating, comment } = EvaluationSchema.parse(req.body);
      const residentId = (req as any).user.id;

      // Validate Request exists and belongs to resident
      const request = db.prepare("SELECT status, completed_at FROM request WHERE id = ? AND resident_id = ?").get(request_id, residentId) as any;

      if (!request) return res.status(404).json({ success: false, status_code: "REQUEST_NOT_FOUND" });
      if (request.status !== 'Completed') return res.status(400).json({ success: false, status_code: "REQUEST_NOT_COMPLETED" });

      // Business Rule: Close evaluation after 7 days
      const completedAt = new Date(request.completed_at);
      const now = new Date();
      const diffDays = (now.getTime() - completedAt.getTime()) / (1000 * 3600 * 24);

      if (diffDays > 7) {
        return res.status(403).json({ success: false, status_code: "EVALUATION_PERIOD_EXPIRED" });
      }

      // Save Evaluation
      const evalId = uuidv4();
      db.prepare(`
        INSERT INTO evaluation (id, request_id, rating, comment)
        VALUES (?, ?, ?, ?)
      `).run(evalId, request_id, rating, comment || null);

      // Mark Request as Reviewed
      db.prepare("UPDATE request SET status = 'Reviewed' WHERE id = ?").run(request_id);

      return res.status(201).json({ success: true, status_code: "EVALUATION_SUBMITTED" });

    } catch (error: any) {
      if (error instanceof z.ZodError) return res.status(400).json({ success: false, errors: error.issues });
      console.error("Eval Error:", error);
      return res.status(500).json({ success: false, status_code: "SERVER_ERROR" });
    }
  }
}
