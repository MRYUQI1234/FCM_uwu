import { Router } from "express";
import multer from "multer";
import { UploadController } from "../controllers/upload.controller";
import { authMiddleware } from "../middlewares/auth.middleware";

const uploadRouter = Router();

// Configure multer for memory storage
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
});

/**
 * FE-05: Upload Profile Picture to Cloudflare R2
 */
uploadRouter.post(
  "/profile-pic",
  authMiddleware,
  upload.single("image"), // Frontend should send image in 'image' field
  UploadController.uploadProfilePic
);

/**
 * FE-03: Upload Repair Images (Before/After)
 */
uploadRouter.post(
  "/repair",
  authMiddleware,
  upload.single("image"),
  UploadController.uploadRepairImage
);

export default uploadRouter;
