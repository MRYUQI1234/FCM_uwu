import { Request, Response } from "express";
import { uploadToR2 } from "../utils/r2.storage";

export class UploadController {
  
  /**
   * POST /upload/profile-pic
   * Handles multipart/form-data with multer
   */
  static async uploadProfilePic(req: Request, res: Response) {
    try {
      if (!req.file) {
        return res.status(400).json({ success: false, message: "No file uploaded" });
      }

      const imageUrl = await uploadToR2(
        req.file.buffer,
        req.file.originalname,
        req.file.mimetype
      );

      return res.status(200).json({
        success: true,
        imageUrl: imageUrl,
      });
    } catch (error) {
      console.error("UploadController uploadProfilePic Error:", error);
      return res.status(500).json({ success: false, message: "Upload failed" });
    }
  }

  /**
   * POST /upload/repair
   * Handles repair project images for TECHNICIANS.
   */
  static async uploadRepairImage(req: Request, res: Response) {
    try {
      if (!req.file) {
        return res.status(400).json({ success: false, message: "No file uploaded" });
      }

      const imageUrl = await uploadToR2(
        req.file.buffer,
        req.file.originalname,
        req.file.mimetype,
        "repairs"
      );

      return res.status(200).json({
        success: true,
        imageUrl: imageUrl,
      });
    } catch (error) {
      console.error("UploadController uploadRepairImage Error:", error);
      return res.status(500).json({ success: false, message: "Cloudflare R2 upload failed, please try again." });
    }
  }
}
