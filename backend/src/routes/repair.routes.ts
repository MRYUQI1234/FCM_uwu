import { Router } from "express";
import { RepairController } from "../controllers/repair.controller";
import { authMiddleware, authorizeRole } from "../middlewares/auth.middleware";

const repairRouter = Router();

// Resident: Service History (filtered by property)
repairRouter.get(
  "/history",
  authMiddleware,
  authorizeRole(["RESIDENT", "JURISTIC", "TECHNICIAN"]),
  RepairController.getResidentHistory
);

// AI Analysis
repairRouter.post("/intent", authMiddleware, RepairController.processIntent);

// Confirmation
repairRouter.post("/confirm", authMiddleware, RepairController.confirmRequest);

/**
 * Technician Module: Task Reporting (FE-03)
 * Access: Technician Only
 */
repairRouter.patch(
  "/task/:taskId",
  authMiddleware,
  authorizeRole(["TECHNICIAN"]),
  RepairController.updateTask
);

/**
 * Resident Module: Evaluation (Feedback System)
 * Access: Resident Only
 */
repairRouter.post(
  "/evaluate",
  authMiddleware,
  authorizeRole(["RESIDENT"]),
  RepairController.submitEvaluation
);

/**
 * Juristic Module: Request Management (FE-02)
 * Access: Juristic Only
 */
repairRouter.patch(
  "/request/:id/assign",
  authMiddleware,
  authorizeRole(["JURISTIC"]),
  RepairController.assignRequest
);

repairRouter.patch(
  "/request/:id/reject",
  authMiddleware,
  authorizeRole(["JURISTIC"]),
  RepairController.rejectRequest
);

export default repairRouter;
