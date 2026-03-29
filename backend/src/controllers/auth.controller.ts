import { Request, Response } from "express";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import { z } from "zod";
import { v4 as uuidv4 } from "uuid";
import { db } from "../database";
import { EmailService } from "../services/email.service";

const JWT_SECRET = process.env.JWT_SECRET || "vivorn-villa-secret-key-2026";

// Validation Schemas
const RegisterSchema = z.object({
  national_id: z.string().regex(/^[0-9]{13}$/, "National ID must be 13 digits"),
  email: z.string().email("Invalid email format"),
  phone: z.string().regex(/^[0-9]{10}$/, "Phone number must be exactly 10 digits"),
  password: z.string()
    .min(8, "Password must be at least 8 characters")
    .regex(/[A-Z]/, "Password must contain at least one uppercase letter")
    .regex(/[a-z]/, "Password must contain at least one lowercase letter"),
  name: z.string().optional()
});

const LoginSchema = z.object({
  email: z.string().email("Invalid email format"),
  password: z.string(),
});

const SetupPinSchema = z.object({
  pin: z.string().regex(/^[0-9]{6}$/, "PIN must be exactly 6 digits"),
});

const UpdateProfileSchema = z.object({
  fullname: z.string().optional(),
  name: z.string().optional(),
  email: z.string().email("Invalid email format").optional(),
  phone: z.string().regex(/^[0-9]{10}$/, "Phone number must be exactly 10 digits").optional(),
  password: z.string()
    .min(8, "Password must be at least 8 characters")
    .regex(/[A-Z]/, "Password must contain at least one uppercase letter")
    .regex(/[a-z]/, "Password must contain at least one lowercase letter").optional(),
  pin: z.string().regex(/^[0-9]{6}$/, "PIN must be exactly 6 digits").optional(),
  picture_uri: z.string().optional(),
});

export class AuthController {
  static async register(req: Request, res: Response) {
    try {
      const validatedData = RegisterSchema.parse(req.body);
      const { national_id, email, password, name, phone } = validatedData;
      const estateRecord = db.prepare("SELECT * FROM real_estate WHERE national_id = ?").get(national_id) as any;
      if (!estateRecord) {
        return res.status(409).json({ status_code: 409, message: "หมายเลขบัตรประชาชนนี้ไม่มีในระบบ หรือ อีเมลนี้ถูกใช้แล้ว" });
      }
      const existingUser = db.prepare("SELECT user_id FROM user WHERE email = ?").get(email);
      if (existingUser) {
        return res.status(409).json({ status_code: 409, message: "หมายเลขบัตรประชาชนนี้ไม่มีในระบบ หรือ อีเมลนี้ถูกใช้แล้ว" });
      }
      const password_hash = await bcrypt.hash(password, 10);
      const userId = uuidv4();
      db.prepare(`INSERT INTO user (user_id, email, phone, password_hash, role, national_id) VALUES (?, ?, ?, ?, ?, ?)`).run(userId, email, phone, password_hash, 'RESIDENT', national_id);
      return res.status(201).json({ status_code: 201, userId: userId });
    } catch (error: any) {
      if (error instanceof z.ZodError) return res.status(400).json({ status_code: 400, message: "ข้อมูลไม่ถูกต้องตามรูปแบบ", errors: error.format() });
      return res.status(500).json({ status_code: 500, message: error.message });
    }
  }

  static async login(req: Request, res: Response) {
    try {
      const { email, password } = req.body;
      const u = db.prepare("SELECT * FROM user WHERE email = ?").get(email) as any;
      if (!u || !(await bcrypt.compare(password, u.password_hash))) {
        return res.status(401).json({ status_code: "INVALID_CREDENTIALS", message: "อีเมลหรือรหัสผ่านไม่ถูกต้อง" });
      }
      const token = jwt.sign({ id: u.user_id, role: u.role, email: u.email }, JWT_SECRET, { expiresIn: "12h" });
      return res.status(200).json({ status_code: u.pin_hash ? "AUTH_SUCCESS" : "REQUIRE_PIN_SETUP", token: token, user: { id: u.user_id, role: u.role } });
    } catch (error: any) {
      return res.status(500).json({ status_code: 500, message: "Internal Server Error" });
    }
  }

  static async setupPin(req: Request, res: Response) {
    try {
      const userId = (req as any).user?.id;
      if (!userId) return res.status(401).json({ success: false, message: "Unauthorized" });
      const { pin } = SetupPinSchema.parse(req.body);
      const pin_hash = await bcrypt.hash(pin, 10);
      db.prepare(`UPDATE user SET pin_hash = ? WHERE user_id = ?`).run(pin_hash, userId);
      return res.status(200).json({ success: true, message: "ตั้งค่ารหัส PIN เรียบร้อยแล้ว" });
    } catch (error: any) {
      return res.status(500).json({ success: false, message: "SERVER_ERROR" });
    }
  }

  static async verifyPin(req: Request, res: Response) {
    try {
      const userId = (req as any).user?.id;
      if (!userId) return res.status(401).json({ success: false, message: "Unauthorized" });
      const { pin } = SetupPinSchema.parse(req.body);
      const u = db.prepare(`SELECT pin_hash FROM user WHERE user_id = ?`).get(userId) as any;
      if (!u || !u.pin_hash) return res.status(401).json({ success: false, message: "PIN not set up" });
      if (!(await bcrypt.compare(pin, u.pin_hash))) return res.status(200).json({ success: false, message: "รหัส PIN ไม่ถูกต้องกรุณาลองใหม่อีกครั้ง" });
      return res.status(200).json({ success: true });
    } catch (error: any) {
      return res.status(500).json({ success: false, message: "SERVER_ERROR" });
    }
  }

  static async getProfile(req: Request, res: Response) {
    try {
      const userId = (req as any).user.id;
      const u = db.prepare(`
        SELECT u.user_id, u.email, u.phone, u.role, u.picture_uri,
               COALESCE(re.fullname, rs.fullname) as fullname,
               h.house_address, h.soi
        FROM user u
        LEFT JOIN real_estate re ON u.national_id = re.national_id AND u.role = 'RESIDENT'
        LEFT JOIN real_staff rs ON u.national_id = rs.national_id AND u.role != 'RESIDENT'
        LEFT JOIN house h ON re.national_id = h.national_id AND u.role = 'RESIDENT'
        WHERE u.user_id = ?
      `).get(userId) as any;
      if (!u) return res.status(404).json({ success: false, message: "User not found" });
      return res.status(200).json({ success: true, data: { user_id: u.user_id, email: u.email, phone: u.phone, name: u.fullname || "User", fullname: u.fullname || "User", role: u.role, picture_uri: u.picture_uri || "", house_address: u.house_address || "N/A", soi: u.soi || "N/A" } });
    } catch (error) {
      return res.status(500).json({ success: false, message: "Connection Error" });
    }
  }

  static async getPersonnel(req: Request, res: Response) {
    try {
      const personnel = db.prepare(`
        SELECT u.national_id as id, u.national_id as idCard, u.email, u.phone, 
               u.role as type, u.role as role,
               rs.fullname as name, 
               CASE 
                 WHEN u.picture_uri IS NULL OR u.picture_uri = '' THEN 'assets/resident_profile.png'
                 ELSE u.picture_uri 
               END as image,
               ex.LineID as lineId,
               ex.LineID as LineID,
               1 as isActive
        FROM user u
        JOIN real_staff rs ON u.national_id = rs.national_id
        LEFT JOIN extended_user ex ON u.user_id = ex.user_id
        WHERE u.role IN ('TECHNICIAN', 'JURISTIC')
        ORDER BY rs.fullname ASC
      `).all().map((p: any) => ({
        ...p,
        isActive: !!p.isActive
      }));

      return res.status(200).json({
        success: true,
        data: personnel
      });
    } catch (error) {
      console.error("[FCM Backend] getPersonnel Error:", error);
      return res.status(500).json({ success: false, status_code: "SERVER_ERROR" });
    }
  }

  static async updateProfile(req: Request, res: Response) {
    try {
      const userId = (req as any).user.id;
      const { name, email, phone, password, pin, picture_uri } = req.body;
      if (email) db.prepare("UPDATE user SET email = ? WHERE user_id = ?").run(email, userId);
      if (phone) db.prepare("UPDATE user SET phone = ? WHERE user_id = ?").run(phone, userId);
      if (password) { const hash = await bcrypt.hash(password, 10); db.prepare("UPDATE user SET password_hash = ? WHERE user_id = ?").run(hash, userId); }
      if (pin) { const hash = await bcrypt.hash(pin, 10); db.prepare("UPDATE user SET pin_hash = ? WHERE user_id = ?").run(hash, userId); }
      if (picture_uri) db.prepare("UPDATE user SET picture_uri = ? WHERE user_id = ?").run(picture_uri, userId);
      return res.status(200).json({ success: true });
    } catch (error) {
      return res.status(500).json({ success: false, message: "Connection Error" });
    }
  }

  static async forgotPassword(req: Request, res: Response) {
    try {
      const { email } = req.body;
      const u = db.prepare("SELECT user_id FROM user WHERE email = ?").get(email) as any;
      if (!u) return res.status(404).json({ success: false, message: "อีเมลนี้ไม่ได้รับอนุญาตในระบบ" });
      const token = uuidv4();
      const expiresAt = new Date(Date.now() + 3600000).toISOString();
      db.prepare("INSERT INTO password_resets (token, user_id, expires_at) VALUES (?, ?, ?)").run(token, u.user_id, expiresAt);
      const backendUrl = "https://abundantly-unsaturated-hayes.ngrok-free.dev";
      const resetLink = `${backendUrl}/api/auth/reset-password?token=${token}`;
      await EmailService.sendResetPasswordEmail(email, resetLink);
      return res.status(200).json({ success: true, message: "Link for password reset has been sent to your email." });
    } catch (error) {
      return res.status(500).json({ success: false, message: "Connection Error" });
    }
  }

  static async redirectReset(req: Request, res: Response) {
    const { token } = req.query;
    const frontendUrl = "https://vivorn-fcm.web.app";
    return res.redirect(`${frontendUrl}/#/reset-password?token=${token}`);
  }

  static async resetPassword(req: Request, res: Response) {
    try {
      const { token, newPassword } = req.body;
      const resetData = db.prepare("SELECT user_id, expires_at FROM password_resets WHERE token = ?").get(token) as any;
      if (!resetData || resetData.expires_at < new Date().toISOString()) return res.status(400).json({ success: false, message: "Invalid or expired token" });
      const hash = await bcrypt.hash(newPassword, 10);
      db.prepare("UPDATE user SET password_hash = ? WHERE user_id = ?").run(hash, resetData.user_id);
      db.prepare("DELETE FROM password_resets WHERE token = ?").run(token);
      return res.status(200).json({ success: true, message: "Your password has been reset successfully." });
    } catch (error) {
      return res.status(500).json({ success: false, message: "Connection Error" });
    }
  }

  static async registerStaff(req: Request, res: Response) {
    try {
      const { type, name, idCard, phone, email } = req.body;
      const userId = uuidv4();
      const passwordHash = await bcrypt.hash(`Vi${idCard}`, 10);
      db.prepare("INSERT INTO real_staff (national_id, staff_id, fullname) VALUES (?, ?, ?)").run(idCard, `STF-${Date.now()}`, name);
      db.prepare("INSERT INTO user (user_id, national_id, email, phone, password_hash, role) VALUES (?, ?, ?, ?, ?, ?)").run(userId, idCard, email, phone, passwordHash, type.toUpperCase());
      return res.status(201).json({ success: true, message: "Staff registered" });
    } catch (error) {
      return res.status(500).json({ success: false, message: "Registration failed" });
    }
  }

  static async updatePersonnel(req: Request, res: Response) {
    try {
      const { nationalId } = req.params;
      const { name, phone, email } = req.body;
      if (name) db.prepare("UPDATE real_staff SET fullname = ? WHERE national_id = ?").run(name, nationalId);
      if (phone) db.prepare("UPDATE user SET phone = ? WHERE national_id = ?").run(phone, nationalId);
      if (email) db.prepare("UPDATE user SET email = ? WHERE national_id = ?").run(email, nationalId);
      return res.status(200).json({ success: true, message: "Updated" });
    } catch (error) {
      return res.status(500).json({ success: false, message: "Update failed" });
    }
  }

  static async deletePersonnel(req: Request, res: Response) {
    try {
      const { nationalId } = req.params;
      db.prepare("DELETE FROM user WHERE national_id = ?").run(nationalId);
      db.prepare("DELETE FROM real_staff WHERE national_id = ?").run(nationalId);
      return res.status(200).json({ success: true, message: "Deleted" });
    } catch (error) {
      return res.status(500).json({ success: false, message: "Deletion failed" });
    }
  }
}
