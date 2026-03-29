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
  task_report: z.string().optional().nullable(),
  after_repair_image_url: z.string().optional().nullable().or(z.literal("")),
});

const EvaluationSchema = z.object({
  request_id: z.string(),
  rating: z.number().min(1).max(5),
  comment: z.string().max(500).optional(),
});

export class RepairController {

  /**
   * GET /api/repair/history
   * Returns repair requests based on Schema v4.0
   * - Resident: Their own requests.
   * - Staff: All requests.
   */
  static async getResidentHistory(req: Request, res: Response) {
    try {
      const user = (req as any).user;
      const isAdmin = user.role === "JURISTIC" || user.role === "TECHNICIAN";

      let query: string;
      let params: any[] = [];
      if (isAdmin) {
        query = `
          SELECT r.request_id, r.user_id, r.title, r.type, r.status, r.created_at, r.completed_at,
                 r.rejection_reason, r.rejection_template,
                 u.email as requester_email,
                 u.phone as requester_phone,
                 re.fullname as requester_name,
                 h.house_address as requester_house,
                 e.score as eval_score,
                 e.comment as eval_comment,
                 (
                   SELECT GROUP_CONCAT(rs2.fullname, ', ')
                   FROM assignment a2
                   JOIN real_staff rs2 ON a2.technician_id = rs2.national_id
                   WHERE a2.request_id = r.request_id
                 ) as assignedStaffStr
          FROM request r
          LEFT JOIN user u ON r.user_id = u.user_id
          LEFT JOIN real_estate re ON u.national_id = re.national_id
          LEFT JOIN house h ON re.national_id = h.national_id
          LEFT JOIN evaluation e ON r.request_id = e.request_id
        `;
      } else {
      query = `
          SELECT r.request_id, r.user_id, r.title, r.type, r.status, r.created_at, r.completed_at,
                 r.rejection_reason, r.rejection_template,
                 re.fullname as requester_name,
                 h.house_address as requester_house,
                 e.score as eval_score,
                 e.comment as eval_comment,
                 (
                   SELECT GROUP_CONCAT(rs2.fullname, ', ')
                   FROM assignment a2
                   JOIN real_staff rs2 ON a2.technician_id = rs2.national_id
                   WHERE a2.request_id = r.request_id
                 ) as assignedStaffStr
          FROM request r
          LEFT JOIN user u ON r.user_id = u.user_id
          LEFT JOIN real_estate re ON u.national_id = re.national_id
          LEFT JOIN house h ON re.national_id = h.national_id
          LEFT JOIN evaluation e ON r.request_id = e.request_id
          WHERE r.user_id = ?
          ORDER BY r.created_at DESC
        `;
        params = [user.id];
      }

      const requests = db.prepare(query).all(...params) as any[];

    const result = requests.map((req: any) => {
      const tasks = db.prepare(`
          SELECT t.task_id, t.object_id, t.detail, t.prefer_date, t.status, t.task_report,
                 t.after_repair_image_url, o.glb_name, o.name as object_name
          FROM task t
          LEFT JOIN object o ON t.object_id = o.object_id
          WHERE t.request_id = ?
        `).all(req.request_id) as any[];

      const assignedStaff = req.assignedStaffStr ? req.assignedStaffStr.split(', ') : [];

      return {
        id: req.request_id,
        title: req.title,
        status: req.status,
        type: req.type,
        created_at: req.created_at,
        completed_at: req.completed_at,
        rejection_reason: req.rejection_reason,
        rejection_template: req.rejection_template,
        technician_name: assignedStaff.length > 0 ? assignedStaff[0] : null,
        assignedStaff: assignedStaff,
        tasks: tasks.map(t => ({
          id: t.task_id,
          description: t.detail,
          status: t.status,
          prefer_date: t.prefer_date,
          object_id: t.object_id, // Added this
          object_name: t.object_name,
          glb_name: t.glb_name,
          task_report: t.task_report,
          after_repair_image_url: t.after_repair_image_url
        })),
        rating: req.eval_score || null,
        comment: req.eval_comment || null,
        requester_name: req.requester_name,
        requester_email: req.requester_email,
        requester_phone: req.requester_phone,
        requester_house: req.requester_house
      };
    });

      return res.status(200).json({ success: true, data: result });
    } catch (error: any) {
      console.error("[RepairController] getResidentHistory Error:", error);
      return res.status(500).json({ success: false, status_code: "SERVER_ERROR", message: error.message });
    }
  }

  /**
   * POST /repair/evaluate
   * Resident evaluates a COMPLETED repair within 7 days.
   */
  static async submitEvaluation(req: Request, res: Response) {
  try {
    const { request_id, rating, comment } = EvaluationSchema.parse(req.body);

    // 1. Fetch Request to validate status and time
    const request = db.prepare(`
        SELECT status, completed_at FROM request WHERE request_id = ?
      `).get(request_id) as any;

    if (!request) {
      return res.status(404).json({ success: false, message: "ไม่พบคำขอแจ้งซ่อม" });
    }

    if (request.status !== "COMPLETED") {
      return res.status(400).json({ success: false, message: "คำขอยังไม่เสร็จสิ้น ไม่สามารถประเมินได้" });
    }

    // 2. Validate Time (within 7 days)
    if (!request.completed_at) {
      return res.status(400).json({ success: false, message: "ไม่พบบันทึกเวลาการซ่อมเสร็จสิ้น" });
    }

    const completedDate = new Date(request.completed_at);
    const now = new Date();
    // Calculate diff in milliseconds and convert to days
    const diffTime = Math.abs(now.getTime() - completedDate.getTime());
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays > 7) {
      return res.status(400).json({ success: false, message: "หมดระยะเวลาประเมินผลการซ่อม" });
    }

    // 3. Perform Transactional Save
    const evaluateTx = db.transaction(() => {
      // Insert Evaluation
      db.prepare(`
          INSERT INTO evaluation (evaluation_id, request_id, comment, score, created_at)
          VALUES (?, ?, ?, ?, ?)
        `).run(
        uuidv4(),
        request_id,
        comment || null,
        rating,
        new Date().toISOString().replace("T", " ").substring(0, 19)
      );

      // Update Request Status
      db.prepare(`
          UPDATE request 
          SET status = 'EVALUATED' 
          WHERE request_id = ?
        `).run(request_id);
    });

    evaluateTx();

    return res.status(201).json({
      success: true,
      message: "บันทึกการประเมินสำเร็จ ขอบพระคุณสำหรับความคิดเห็นครับ"
    });

  } catch (error: any) {
    console.error("[RepairController] submitEvaluation Error:", error);
    return res.status(500).json({
      success: false,
      message: "ไม่สามารถบันทึกลงฐานข้อมูลได้ กรุณาลองอีกครั้ง"
    });
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

    const aiResult = await AIService.analyzeRepairIntent(description);
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
   * POST /repair/confirm
   * Step-by-Step Logic per Vivorn Villa FCM Repair Service Agent role.
   */
  static async confirmRequest(req: Request, res: Response) {
  const userId = (req as any).user.id;

  try {
    let { tasks, message_id, isEmergency } = req.body;

    // Handle nested structure from some Frontend versions (e.g., 3D Model Path)
    if (!tasks && req.body.request) {
      tasks = req.body.request.tasks;
      message_id = message_id || req.body.request.message_id;
      isEmergency = isEmergency || req.body.request.isEmergency;
    }

    if (!tasks || !Array.isArray(tasks) || tasks.length === 0) {
      return res.status(400).json({ success: false, error: "รายการซ่อมว่างเปล่า กรุณาระบุรายละเอียดการแจ้งซ่อม" });
    }

    // 1. Warranty Check: 5 years from house.activate_date
    const houseInfo = db.prepare(`
        SELECT h.activate_date 
        FROM house h
        JOIN user u ON h.national_id = u.national_id
        WHERE u.user_id = ?
      `).get(userId) as any;

    let warrantyWarning = "";
    if (houseInfo && houseInfo.activate_date) {
      const activateDate = new Date(houseInfo.activate_date);
      const fiveYearsLater = new Date(activateDate);
      fiveYearsLater.setFullYear(fiveYearsLater.getFullYear() + 5);

      if (new Date() > fiveYearsLater) {
        warrantyWarning = " (หมายเหตุ: ระยะเวลาประกันบ้าน 5 ปีของท่านสิ้นสุดลงแล้ว การแจ้งซ่อมนี้อาจมีค่าใช้จ่ายเพิ่มเติมค่ะ)";
      }
    }

    // 2. Transaction Management
    const requestId = uuidv4();
    const createdAt = new Date().toISOString().replace("T", " ").substring(0, 19);

    // Derive Title: Prioritize object_name (Subject) over description
    const firstTask = tasks[0];
    const title = (firstTask.object_name || firstTask.description || "แจ้งซ่อมทั่วไป").substring(0, 100);

    // Derive Type
    let type = 'NORMAL';
    if (isEmergency === true || tasks.some((t: any) => t.urgency === 'URGENT' || t.urgency === 'Emergency')) {
      type = 'URGENT';
    }

    db.transaction(() => {
      // Step 1: Insert request
      db.prepare(`
          INSERT INTO request (request_id, user_id, title, type, status, created_at)
          VALUES (?, ?, ?, ?, ?, ?)
        `).run(requestId, userId, title, type, 'CREATED', createdAt);

      // Step 2: Insert tasks
      const insertTaskStmt = db.prepare(`
          INSERT INTO task (task_id, request_id, object_id, detail, prefer_date, status)
          VALUES (?, ?, ?, ?, ?, ?)
        `);

      for (const task of tasks) {
        const taskId = uuidv4();
        // Validation: Time Slot Coercion (09:30:00 or 13:00:00)
        let finalTime = '09:30:00'; // Default to morning
        if (task.prefer_time) {
          const tStr = String(task.prefer_time).toLowerCase();
          if (tStr.includes('13') || tStr.includes('14') || tStr.includes('afternoon') || tStr.includes('บ่าย')) {
            finalTime = '13:00:00';
          } else if (tStr.includes('09') || tStr.includes('10') || tStr.includes('morning') || tStr.includes('เช้า')) {
            finalTime = '09:30:00';
          } else {
             finalTime = task.prefer_time; // Revert to whatever was passed for fallback checking
          }
        } else {
           // Fallback if AI missed prefer_time completely, set to default
           finalTime = '09:30:00';
        }

        if (finalTime !== '09:30:00' && finalTime !== '13:00:00') {
           // Force standard time slot to prevent DB error if AI outputs random string like "Tomorrow Morning"
           finalTime = '09:30:00'; 
        }
        
        task.prefer_time = finalTime; // reassign for insertion
        const preferDateStr = `${task.prefer_date} ${task.prefer_time}`;

        insertTaskStmt.run(
          taskId,
          requestId,
          task.object_id,
          task.description,
          preferDateStr,
          'Pending'
        );
      }

      // Step 3: Update AI State if message_id provided
      if (message_id) {
        db.prepare("UPDATE ai_messages SET action_state = 'confirmed' WHERE message_id = ?").run(message_id);

        // Get conversation_id and mark as complete
        const msg = db.prepare("SELECT conversation_id FROM ai_messages WHERE message_id = ?").get(message_id) as any;
        if (msg) {
          db.prepare("UPDATE ai_conversation SET complete = 1 WHERE conversation_id = ?").run(msg.conversation_id);
        }
      }
    })();

    return res.status(201).json({
      success: true,
      message: `สร้างคำขอแจ้งซ่อมสำเร็จ${warrantyWarning}`,
      request_id: requestId
    });

  } catch (error: any) {
    console.error("[RepairController] confirmRequest Error:", error);
    return res.status(400).json({ success: false, error: error.message });
  }
}

  /**
   * PATCH /request/:id/assign
   * Business Rules: Juristic assigns technicians to CREATED requests.
   */
  static async assignRequest(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const { staff_names } = req.body;
    const juristicUserId = (req as any).user.id;

    if (!staff_names || !Array.isArray(staff_names) || staff_names.length === 0) {
      return res.status(400).json({ success: false, message: "โปรดระบุชื่อช่างที่ต้องการมอบหมาย" });
    }

    // 1. Get Juristic's national_id
    const juristic = db.prepare("SELECT national_id FROM user WHERE user_id = ?").get(juristicUserId) as any;
    if (!juristic) return res.status(403).json({ success: false, message: "Unauthorized" });

    // 2. Resolve technician names to national_ids
    const technicianIds: string[] = [];
    const resolveStmt = db.prepare("SELECT national_id FROM real_staff WHERE fullname = ?");

    for (const name of staff_names) {
      const staff = resolveStmt.get(name) as any;
      if (staff) {
        technicianIds.push(staff.national_id);
      }
    }

    if (technicianIds.length === 0) {
      return res.status(400).json({ success: false, message: "ไม่พบข้อมูลช่างซ่อมที่ระบุ" });
    }

    // 3. Status Validation & Transaction
    // Note: PK for request table is request_id per your previous view
    const request = db.prepare("SELECT status FROM request WHERE request_id = ?").get(id) as any;
    if (!request) return res.status(404).json({ success: false, message: "ไม่พบคำขอแจ้งซ่อม" });
    if (request.status !== 'CREATED') {
      const statusTH = request.status === 'ASSIGNED' ? 'มอบหมายงานแล้ว' :
        request.status === 'DECLINED' ? 'ถูกปฏิเสธแล้ว' : request.status;
      return res.status(400).json({ success: false, message: `งานอยู่ในสถานะ '${statusTH}' ไม่สามารถดำเนินการได้ในตอนนี้` });
    }

    const assignTx = db.transaction(() => {
      // Update Request Status
      db.prepare("UPDATE request SET status = 'ASSIGNED' WHERE request_id = ?").run(id);

      // Create Assignments
      const insertAssignStmt = db.prepare(`
          INSERT INTO assignment (assignment_id, request_id, juristic_id, technician_id, created_at)
          VALUES (?, ?, ?, ?, ?)
        `);

      for (const tid of technicianIds) {
        const createdAt = new Date().toISOString().replace("T", " ").substring(0, 19);
        insertAssignStmt.run(uuidv4(), id, juristic.national_id, tid, createdAt);
      }
    });

    assignTx();

    return res.status(200).json({ success: true, message: "มอบหมายงานสำเร็จ" });

  } catch (error: any) {
    console.error("[RepairController] assignRequest Error:", error);
    return res.status(500).json({ success: false, message: "ไม่สามารถบันทึกลงฐานข้อมูลได้ กรุณาลองอีกครั้ง" });
  }
}

  /**
   * PATCH /request/:id/reject
   * Business Rules: Juristic rejects a request with reason.
   */
  static async rejectRequest(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const { reason, template } = req.body;

    if (!reason) {
      return res.status(400).json({ success: false, message: "โปรดระบุเหตุผลในการปฏิเสธ" });
    }

    // Status Validation
    const request = db.prepare("SELECT status FROM request WHERE request_id = ?").get(id) as any;
    if (!request) return res.status(404).json({ success: false, message: "ไม่พบคำขอแจ้งซ่อม" });
    if (request.status !== 'CREATED') {
      return res.status(400).json({ success: false, message: "สามารถดำเนินการได้เฉพาะงานที่พึ่งแจ้งเข้ามาใหม่เท่านั้น" });
    }

    db.prepare(`
        UPDATE request 
        SET status = 'DECLINED', rejection_reason = ?, rejection_template = ?
        WHERE request_id = ?
      `).run(reason, template || null, id);

    return res.status(200).json({ success: true, message: "ปฏิเสธคำขอสำเร็จ" });

  } catch (error: any) {
    console.error("[RepairController] rejectRequest Error:", error);
    return res.status(500).json({ success: false, message: "ไม่สามารถบันทึกลงฐานข้อมูลได้ กรุณาลองอีกครั้ง" });
  }
}

  /**
   * PATCH /repair/task/:taskId
   * Business Rules (FE-03): Technician updates a task status/report.
   */
  static async updateTask(req: Request, res: Response) {
  try {
    const { taskId } = req.params;
    const parsed = TaskUpdateSchema.safeParse(req.body);

    if (!parsed.success) {
      return res.status(400).json({ success: false, message: "Invalid request data", errors: parsed.error.format() });
    }

    const { status, task_report, after_repair_image_url } = parsed.data;

    // 1. Fetch Task Info
    const task = db.prepare("SELECT request_id, status FROM task WHERE task_id = ?").get(taskId) as any;
    if (!task) return res.status(404).json({ success: false, message: "Task not found." });

    const requestId = task.request_id;

    // 2. Transactional Update
    const updateTx = db.transaction(() => {
      // Update Task level
      db.prepare(`
          UPDATE task 
          SET status = ?, task_report = ?, after_repair_image_url = ?
          WHERE task_id = ?
        `).run(status, task_report || null, after_repair_image_url || null, taskId);

      // 3. Status Propagation to Request
      if (status === "InProgress") {
        db.prepare("UPDATE request SET status = 'BEGAN' WHERE request_id = ?").run(requestId);
      } else if (status === "Completed") {
        // Check if ALL tasks in this request are Completed
        const remainingTasksCountResult = db.prepare(`
            SELECT COUNT(*) as count FROM task 
            WHERE request_id = ? AND status != 'Completed'
          `).get(requestId) as any;

        if (remainingTasksCountResult.count === 0) {
          const completedAtStr = new Date().toISOString().replace("T", " ").substring(0, 19);
          db.prepare(`
              UPDATE request 
              SET status = 'COMPLETED', completed_at = ? 
              WHERE request_id = ?
            `).run(completedAtStr, requestId);
        }
      }
    });

    updateTx();

    return res.status(200).json({
      success: true,
      message: "สถานะงานได้รับการอัปเดตเรียบร้อย"
    });
  } catch (error: any) {
    console.error("[RepairController] updateTask Error:", error);
    return res.status(500).json({
      success: false,
      message: error.message || "Failed to update task status"
    });
  }
}
}
