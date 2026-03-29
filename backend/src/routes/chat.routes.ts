import { Router } from "express";
import { chatController } from "../controllers/chat.controller";
import { authMiddleware, authorizeRole } from "../middlewares/auth.middleware";

const router = Router();

// All chat endpoints are resident-only (since it's an AI Assistant for request creation)
router.use(authMiddleware);
router.use(authorizeRole(["RESIDENT"]));

router.get("/conversations", chatController.getConversations);
router.get("/conversations/:conversationId/messages", chatController.getMessages);
router.post("/message", chatController.sendMessage);
router.post("/conversations/:id/archive", chatController.archiveConversation);
router.delete("/conversations/:id", chatController.deleteConversation);
router.patch("/message/:id/action", chatController.updateMessageActionState);

export default router;
