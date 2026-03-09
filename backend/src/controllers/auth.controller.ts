import { Request, Response } from "express";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import { z } from "zod";
import { v4 as uuidv4 } from "uuid";
import { db } from "../database";

const JWT_SECRET = process.env.JWT_SECRET || "vivorn-villa-secret-key-2026";

// Validation Schemas (UT-3, UT-11)
const RegisterSchema = z.object({
  national_id: z.string().regex(/^[0-9]{13}$/, "National ID must be 13 digits"),
  email: z.string().email("Invalid email format"),
  phone: z.string().min(9).max(15),
  password: z.string()
    .min(8, "Password must be at least 8 characters")
    .regex(/[A-Z]/, "Password must contain at least one uppercase letter")
    .regex(/[0-9]/, "Password must contain at least one number"),
});

const LoginSchema = z.object({
  email: z.string().email("Invalid email format"),
  password: z.string(),
});

const SetupPinSchema = z.object({
  pin: z.string().regex(/^[0-9]{6}$/, "PIN must be exactly 6 digits"),
});

export class AuthController {
  /**
   * POST /api/auth/register
   * Result Codes: REGISTRATION_SUCCESS, ID_NOT_FOUND, ALREADY_REGISTERED
   */
  static async register(req: Request, res: Response) {
    console.log("-----------------------------------------");
    console.log("[FCM Backend] Registration Attempt");
    console.log("[FCM Backend] Incoming Body:", req.body);

    try {
      const { national_id, email, phone, password } = RegisterSchema.parse(req.body);
      console.log(`[FCM Backend] Zod Validation Passed for: ${national_id}`);

      const estateRecord = db.prepare("SELECT * FROM real_estate_records WHERE national_id = ?").get(national_id) as any;
      if (!estateRecord) {
        console.warn(`[FCM Backend] Registration Failed: ID_NOT_FOUND (${national_id})`);
        return res.status(403).json({
          success: false,
          status_code: "ID_NOT_FOUND"
        });
      }

      console.log(`[FCM Backend] Real Estate Record Found: ${estateRecord.full_name}`);

      // Only email must be unique — same person can have multiple accounts for different houses
      const existingUser = db.prepare("SELECT id FROM users WHERE email = ?").get(email);
      if (existingUser) {
        console.warn(`[FCM Backend] Registration Failed: ALREADY_REGISTERED (${email})`);
        return res.status(409).json({
          success: false,
          status_code: "ALREADY_REGISTERED"
        });
      }

      const password_hash = await bcrypt.hash(password, 10);
      const userId = uuidv4();

      db.prepare(`
        INSERT INTO users (id, email, phone, password_hash, role, national_id, is_first_login, full_name)
        VALUES (?, ?, ?, ?, ?, ?, 1, ?)
      `).run(userId, email, phone, password_hash, 'Resident', national_id, estateRecord.full_name);

      console.log(`[FCM Backend] Registration SUCCESS! User ID: ${userId}`);

      return res.status(201).json({
        success: true,
        status_code: "REGISTRATION_SUCCESS",
        userId: userId
      });

    } catch (error: any) {
      if (error instanceof z.ZodError) {
        console.error("[FCM Backend] Registration Failed: VALIDATION_ERROR");
        console.error(JSON.stringify(error.issues, null, 2));
        return res.status(400).json({ success: false, status_code: "VALIDATION_ERROR", errors: error.issues });
      }

      console.error("[FCM Backend] Registration Failed: SERVER_ERROR", error);
      return res.status(500).json({ success: false, status_code: "SERVER_ERROR", message: error.message });
    }
  }

  /**
   * POST /api/auth/login
   * Result Codes: AUTH_SUCCESS, REQUIRE_PIN_SETUP, INVALID_CREDENTIALS
   */
  static async login(req: Request, res: Response) {
    try {
      const { email, password } = LoginSchema.parse(req.body);
      const user = db.prepare("SELECT * FROM users WHERE email = ?").get(email) as any;

      if (!user || !(await bcrypt.compare(password, user.password_hash))) {
        return res.status(401).json({
          success: false,
          status_code: "INVALID_CREDENTIALS"
        });
      }

      const token = jwt.sign({ id: user.id, role: user.role, email: user.email }, JWT_SECRET, { expiresIn: "12h" });

      return res.status(200).json({
        success: true,
        status_code: user.is_first_login ? "REQUIRE_PIN_SETUP" : "AUTH_SUCCESS",
        token,
        user: {
          id: user.id,
          role: user.role
        }
      });

    } catch (error: any) {
      if (error instanceof z.ZodError) {
        return res.status(400).json({ success: false, status_code: "VALIDATION_ERROR", errors: error.issues });
      }
      return res.status(500).json({ success: false, status_code: "SERVER_ERROR" });
    }
  }

  /**
   * POST /api/auth/setup-pin
   * Result Codes: PIN_SETUP_SUCCESS, AUTH_REQUIRED
   */
  static async setupPin(req: Request, res: Response) {
    try {
      const userId = (req as any).user.id;
      const { pin } = SetupPinSchema.parse(req.body);

      const pin_hash = await bcrypt.hash(pin, 10);
      db.prepare(`UPDATE users SET pin_hash = ?, is_first_login = 0 WHERE id = ?`).run(pin_hash, userId);

      return res.status(200).json({
        success: true,
        status_code: "PIN_SETUP_SUCCESS"
      });

    } catch (error: any) {
      if (error instanceof z.ZodError) {
        return res.status(400).json({ success: false, status_code: "VALIDATION_ERROR", errors: error.issues });
      }
      return res.status(500).json({ success: false, status_code: "SERVER_ERROR" });
    }
  }

  /**
   * GET /api/auth/profile
   * Returns current user info based on JWT
   */
  static async getProfile(req: Request, res: Response) {
    try {
      const userId = (req as any).user.id;

      // Get basic user info
      const user = db.prepare(`
        SELECT u.id, u.email, u.phone, u.role, u.full_name as name, u.is_first_login, r.house_number as houseId
        FROM users u
        LEFT JOIN real_estate_records r ON u.national_id = r.national_id
        WHERE u.id = ?
      `).get(userId) as any;

      if (!user) {
        return res.status(404).json({ success: false, status_code: "USER_NOT_FOUND" });
      }

      return res.status(200).json({
        success: true,
        data: user
      });
    } catch (error) {
      return res.status(500).json({ success: false, status_code: "SERVER_ERROR" });
    }
  }

  /**
   * PATCH /api/auth/profile
   * Update current user's profile fields (name, email, phone, password)
   */
  static async updateProfile(req: Request, res: Response) {
    try {
      const userId = (req as any).user.id;
      const { name, email, phone, password } = req.body;

      // Build dynamic update
      const updates: string[] = [];
      const values: any[] = [];

      if (name && typeof name === "string" && name.trim()) {
        updates.push("full_name = ?");
        values.push(name.trim());
      }

      if (email && typeof email === "string") {
        const emailSchema = z.string().email();
        const parsed = emailSchema.safeParse(email);
        if (!parsed.success) {
          return res.status(400).json({ success: false, status_code: "VALIDATION_ERROR", message: "Invalid email format" });
        }
        // Check uniqueness
        const existing = db.prepare("SELECT id FROM users WHERE email = ? AND id != ?").get(email, userId);
        if (existing) {
          return res.status(409).json({ success: false, status_code: "EMAIL_TAKEN", message: "Email already in use" });
        }
        updates.push("email = ?");
        values.push(email.trim());
      }

      if (phone && typeof phone === "string" && phone.trim()) {
        updates.push("phone = ?");
        values.push(phone.trim());
      }

      if (password && typeof password === "string") {
        if (password.length < 8) {
          return res.status(400).json({ success: false, status_code: "VALIDATION_ERROR", message: "Password must be at least 8 characters" });
        }
        const password_hash = await bcrypt.hash(password, 10);
        updates.push("password_hash = ?");
        values.push(password_hash);
      }

      if (updates.length === 0) {
        return res.status(400).json({ success: false, status_code: "NO_CHANGES", message: "No valid fields to update" });
      }

      values.push(userId);
      db.prepare(`UPDATE users SET ${updates.join(", ")} WHERE id = ?`).run(...values);

      console.log(`[FCM Backend] Profile updated for user ${userId}: ${updates.map(u => u.split(" =")[0]).join(", ")}`);

      return res.status(200).json({ success: true, status_code: "PROFILE_UPDATED" });
    } catch (error: any) {
      console.error("[FCM Backend] Profile Update Error:", error);
      return res.status(500).json({ success: false, status_code: "SERVER_ERROR" });
    }
  }
}
