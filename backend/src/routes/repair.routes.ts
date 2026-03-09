import { Router } from "express";
import { RepairController } from "../controllers/repair.controller";
import { authMiddleware, authorizeRole } from "../middlewares/auth.middleware";

const repairRouter = Router();

// Resident: Service History (filtered by property)
repairRouter.get(
  "/history",
  authMiddleware,
  authorizeRole(["Resident"]),
  RepairController.getResidentHistory
);

// AI Analysis
repairRouter.post("/intent", authMiddleware, RepairController.processIntent);

// Confirmation
repairRouter.post("/confirm", authMiddleware, RepairController.confirmRequest);

/**
 * Technician Module: Update Status & Report (FE-03)
 * Access: Technician or Jurisdictic
 */
repairRouter.patch(
  "/task/:taskId",
  authMiddleware,
  authorizeRole(["Technician", "Jurisdictic"]),
  RepairController.updateTaskStatus
);

/**
 * Resident Module: Evaluation (Feedback System)
 * Access: Resident Only
 */
repairRouter.post(
  "/evaluate",
  authMiddleware,
  authorizeRole(["Resident"]),
  RepairController.submitEvaluation
);

export default repairRouter;
