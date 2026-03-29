import { Request, Response } from "express";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import { z } from "zod";
import { v4 as uuidv4 } from "uuid";
import { db } from "../database";
import { EmailService } from "../services/email.service";

const JWT_SECRET = process.env.JWT_SECRET || "vivorn-villa-secret-key-2026";

// Validation Schemas (UT-3, UT-11)
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
  /**
   * POST /auth/register
   * Logic (Strict Validation):
   * 1. Check if national_id exists in real_estate (Only residents can register via this endpoint)
   * 2. Check if email is unique
   * 3. Insert into user table with role = 'RESIDENT'
   * 4. Generate random user_id (UUID)
   */
  static async register(req: Request, res: Response) {
    console.log("-----------------------------------------");
    console.log("[FCM Backend] Registration Attempt");
    console.log("[FCM Backend] Incoming Body:", req.body);

    try {
      // Validate Input using Zod
      const validatedData = RegisterSchema.parse(req.body);
      const { national_id, email, password, name, phone } = validatedData;

      // Step 1: Check national_id in real_estate
      const estateRecord = db.prepare("SELECT * FROM real_estate WHERE national_id = ?").get(national_id) as any;
      if (!estateRecord) {
        console.warn(`[FCM Backend] Registration Failed: National ID not found (${national_id})`);
        return res.status(409).json({
          status_code: 409,
          message: "หมายเลขบัตรประชาชนนี้ไม่มีในระบบ หรือ อีเมลนี้ถูกใช้แล้ว"
        });
      }

      // Step 2: Check if email is unique
      const existingUser = db.prepare("SELECT user_id FROM user WHERE email = ?").get(email);
      if (existingUser) {
        console.warn(`[FCM Backend] Registration Failed: Email already used (${email})`);
        return res.status(409).json({
          status_code: 409,
          message: "หมายเลขบัตรประชาชนนี้ไม่มีในระบบ หรือ อีเมลนี้ถูกใช้แล้ว"
        });
      }

      // Step 3 & 4: Hash password and Insert user
      const password_hash = await bcrypt.hash(password, 10);
      const userId = uuidv4();

      db.prepare(`
        INSERT INTO user (user_id, email, phone, password_hash, role, national_id)
        VALUES (?, ?, ?, ?, ?, ?)
      `).run(userId, email, phone, password_hash, 'RESIDENT', national_id);

      console.log(`[FCM Backend] Registration SUCCESS! User ID: ${userId}, Role: RESIDENT`);

      return res.status(201).json({
        status_code: 201,
        userId: userId
      });

    } catch (error: any) {
      if (error instanceof z.ZodError) {
        return res.status(400).json({ status_code: 400, message: "ข้อมูลไม่ถูกต้องตามรูปแบบ", errors: error.format() });
      }
      console.error("[FCM Backend] Registration Failed: SERVER_ERROR", error);
      return res.status(500).json({ status_code: 500, message: error.message });
    }
  }

  /**
   * POST /auth/login
   * Logic:
   * 1. Check email in user table
   * 2. Verify password_hash
   * 3. Return Mock Token and User Data
   */
  static async login(req: Request, res: Response) {
    try {
      const { email, password } = req.body;
      const u = db.prepare("SELECT * FROM user WHERE email = ?").get(email) as any;

      if (!u || !(await bcrypt.compare(password, u.password_hash))) {
        console.log("[FCM] Login Failed: Invalid Credentials for ", email);
        return res.status(401).json({
          status_code: "INVALID_CREDENTIALS",
          message: "อีเมลหรือรหัสผ่านไม่ถูกต้อง"
        });
      }

      const token = jwt.sign({ id: u.user_id, role: u.role, email: u.email }, JWT_SECRET, { expiresIn: "12h" });

      console.log(`[FCM Backend] Login Success: User ID: ${u.user_id}, Role: ${u.role}`);

      return res.status(200).json({
        status_code: u.pin_hash ? "AUTH_SUCCESS" : "REQUIRE_PIN_SETUP",
        token: token,
        user: {
          id: u.user_id,
          role: u.role
        }
      });

    } catch (error: any) {
      console.error("[FCM Backend] Login Failed: SERVER_ERROR", error);
      return res.status(500).json({ status_code: 500, message: "Internal Server Error" });
    }
  }

  /**
   * POST /auth/setup-pin
   * Authentication: Requires Bearer Token for user identification
   * Logic: Hashes a 6-digit PIN and updates user's pin_hash
   */
  static async setupPin(req: Request, res: Response) {
    try {
      const userId = (req as any).user?.id;
      if (!userId) {
        return res.status(401).json({
          success: false,
          message: "ไม่สามารถตั้งค่า PIN ได้ กรุณาตรวจสอบการเข้าสู่ระบบ"
        });
      }

      const { pin } = SetupPinSchema.parse(req.body);

      const pin_hash = await bcrypt.hash(pin, 10);
      db.prepare(`UPDATE user SET pin_hash = ? WHERE user_id = ?`).run(pin_hash, userId);

      console.log(`[FCM Backend] PIN setup successful for user ${userId}`);

      return res.status(200).json({
        success: true,
        message: "ตั้งค่ารหัส PIN เรียบร้อยแล้ว"
      });

    } catch (error: any) {
      if (error instanceof z.ZodError) {
        return res.status(400).json({
          success: false,
          message: "ไม่สามารถตั้งค่า PIN ได้ กรุณาตรวจสอบการเข้าสู่ระบบ"
        });
      }
      return res.status(500).json({ success: false, message: "SERVER_ERROR" });
    }
  }

  /**
   * POST /auth/verify-pin
   * Authentication: Requires Bearer Token
   * Logic: Compares provided pin with stored pin_hash
   */
  static async verifyPin(req: Request, res: Response) {
    try {
      const userId = (req as any).user?.id;
      if (!userId) {
        return res.status(401).json({ success: false, message: "Unauthorized" });
      }

      const { pin } = SetupPinSchema.parse(req.body);
      const u = db.prepare(`SELECT pin_hash FROM user WHERE user_id = ?`).get(userId) as any;

      if (!u || !u.pin_hash) {
        return res.status(401).json({ success: false, message: "PIN not set up" });
      }

      if (!(await bcrypt.compare(pin, u.pin_hash))) {
        // According to SRS condition: Return 200 with success: false for wrong PIN
        return res.status(200).json({
          success: false,
          message: "รหัส PIN ไม่ถูกต้องกรุณาลองใหม่อีกครั้ง"
        });
      }

      return res.status(200).json({ success: true });

    } catch (error: any) {
      if (error instanceof z.ZodError) {
        return res.status(400).json({ success: false, message: "Validation Error" });
      }
      return res.status(500).json({ success: false, message: "SERVER_ERROR" });
    }
  }

  /**
   * GET /auth/profile
   * Returns current user info based on JWT
   */
  static async getProfile(req: Request, res: Response) {
    try {
      const userId = (req as any).user.id;

      // SQL Join with real_estate, real_staff, AND house to get fullname and address
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

      if (!u) {
        return res.status(404).json({ success: false, message: "User not found" });
      }

      return res.status(200).json({
        success: true,
        data: {
          user_id: u.user_id,
          email: u.email,
          phone: u.phone,
          name: u.fullname || "User",
          fullname: u.fullname || "User",
          role: u.role,
          picture_uri: u.picture_uri || "",
          house_address: u.house_address || "N/A",
          soi: u.soi || "N/A"
        }
      });
    } catch (error) {
      console.error("[FCM Backend] getProfile Error:", error);
      return res.status(500).json({ success: false, message: "Connection Error" });
    }
  }

  /**
   * GET /api/auth/personnel
   * Returns list of all personnel (Technicians & Admins)
   */
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

  /**
   * PATCH /auth/profile
   * Logic: Updates user table (name, email, phone, password)
   */
  static async updateProfile(req: Request, res: Response) {
    try {
      const userId = (req as any).user.id;
      // Use Zod validation parser
      const parsedBody = UpdateProfileSchema.safeParse(req.body);
      if (!parsedBody.success) {
        return res.status(400).json({ success: false, message: "ข้อมูลไม่ถูกต้องตามรูปแบบ", errors: parsedBody.error.format() });
      }

      const { fullname, name, email, phone, password, picture_uri, pin } = parsedBody.data;

      const profileName = name || fullname;

      // 1. Update Fullname in respective tables
      if (profileName && typeof profileName === "string") {
        const uInfo = db.prepare("SELECT national_id, role FROM user WHERE user_id = ?").get(userId) as any;
        if (uInfo) {
          if (uInfo.role === 'RESIDENT') {
            db.prepare("UPDATE real_estate SET fullname = ? WHERE national_id = ?").run(profileName, uInfo.national_id);
          } else {
            db.prepare("UPDATE real_staff SET fullname = ? WHERE national_id = ?").run(profileName, uInfo.national_id);
          }
        }
      }

      // 2. Build dynamic update for 'user' table
      const updates: string[] = [];
      const values: any[] = [];

      if (email && typeof email === "string") {
        updates.push("email = ?");
        values.push(email);
      }

      if (phone) {
        updates.push("phone = ?");
        values.push(phone);
      }

      if (password) {
        const hash = await bcrypt.hash(password, 10);
        updates.push("password_hash = ?");
        values.push(hash);
      }

      if (pin) {
        const pinHash = await bcrypt.hash(pin, 10);
        updates.push("pin_hash = ?");
        values.push(pinHash);
      }

      if (picture_uri !== undefined) {
        updates.push("picture_uri = ?");
        values.push(picture_uri);
      }

      if (updates.length > 0) {
        values.push(userId);
        db.prepare(`UPDATE user SET ${updates.join(", ")} WHERE user_id = ?`).run(...values);
      }

      return res.status(200).json({ success: true });

    } catch (error) {
      console.error("[FCM Backend] updateProfile Error:", error);
      return res.status(500).json({ success: false, message: "Connection Error" });
    }
  }

  /**
   * POST /auth/forgot-password
   * Logic: Generates reset token and sends mock email
   */
  static async forgotPassword(req: Request, res: Response) {
    try {
      const { email } = req.body;
      const u = db.prepare("SELECT user_id FROM user WHERE email = ?").get(email) as any;

      if (!u) {
        // Return success anyway for security if email doesn't exist, or be explicit per requirement
        return res.status(404).json({ success: false, message: "อีเมลนี้ไม่ได้รับอนุญาตในระบบ" });
      }

      const token = uuidv4();
      const expiresAt = new Date(Date.now() + 3600000).toISOString(); // 1 hour expiry

      db.prepare(`
        INSERT INTO password_resets (token, user_id, expires_at)
        VALUES (?, ?, ?)
      `).run(token, u.user_id, expiresAt);

      // Simulation of Email Service (Mock)
      const resetLink = `http://localhost:3000/auth/reset-password?token=${token}`;
      console.log(`[FCM Backend] Mock Email Sent to ${email}: Reset your password at ${resetLink}`);

      // In a real scenario, use await EmailService.send(...)
      await EmailService.sendResetPasswordEmail(email, resetLink);

      return res.status(200).json({
        success: true,
        message: "Link for password reset has been sent to your email."
      });

    } catch (error) {
      console.error("[FCM Backend] forgotPassword Error:", error);
      return res.status(500).json({ success: false, message: "Connection Error" });
    }
  }

  /**
   * POST /auth/reset-password
   * Input: token, newPassword
   */
  static async resetPassword(req: Request, res: Response) {
    try {
      const { token, newPassword } = req.body;

      if (!token || !newPassword || newPassword.length < 8) {
        return res.status(400).json({ success: false, message: "Invalid parameters or weak password" });
      }

      const resetData = db.prepare(`
        SELECT user_id, expires_at 
        FROM password_resets 
        WHERE token = ?
      `).get(token) as any;

      if (!resetData) {
        return res.status(400).json({ success: false, message: "Invalid or expired token" });
      }

      const now = new Date().toISOString();
      if (resetData.expires_at < now) {
        db.prepare("DELETE FROM password_resets WHERE token = ?").run(token);
        return res.status(400).json({ success: false, message: "Invalid or expired token" });
      }

      // Hash and Update
      const hash = await bcrypt.hash(newPassword, 10);
      db.prepare("UPDATE user SET password_hash = ? WHERE user_id = ?").run(hash, resetData.user_id);

      // Delete token
      db.prepare("DELETE FROM password_resets WHERE token = ?").run(token);

      return res.status(200).json({
        success: true,
        message: "Your password has been reset successfully."
      });

    } catch (error) {
      console.error("[FCM Backend] resetPassword Error:", error);
      return res.status(500).json({ success: false, message: "Connection Error" });
    }
  }

  /**
   * POST /auth/register-staff
   * Logic: 1. real_staff 2. user
   * Default password: national_id
   */
  static async registerStaff(req: Request, res: Response) {
    try {
      const { type, name, idCard, phone, lineId, LineID, email, profileUrl, picture_uri, imageUrl, image } = req.body;
      const finalProfileUrl = profileUrl || picture_uri || imageUrl || image;
      const finalLineId = lineId || LineID;

      // Transform and normalize role (Map type to role)
      let role = (type || "").toString().trim().toLowerCase();
      if (role === "ช่างซ่อม" || role === "technician") {
        role = "TECHNICIAN";
      } else if (role === "นิติกรหมู่บ้าน" || role === "juristic") {
        role = "JURISTIC";
      } else {
        role = role.toUpperCase();
      }

      // Final Role Validation (matches SQL CHECK constraint)
      const allowedRoles = ["RESIDENT", "JURISTIC", "TECHNICIAN"];
      if (!allowedRoles.includes(role)) {
        return res.status(400).json({
          success: false,
          message: `Role/Type '${type}' ไม่ถูกต้อง ต้องเป็นหนึ่งใน: ${allowedRoles.join(", ")}`
        });
      }

      // Validation
      if (!name || !idCard || !phone || !email) {
        return res.status(400).json({ success: false, message: "Missing required fields" });
      }

      const userId = uuidv4();
      const staffId = `STF-${Date.now().toString().slice(-6)}`;
      const passwordHash = await bcrypt.hash(`Vi${idCard}`, 10); // Default to Vi + national_id

      // Transactional registration
      const registerTx = db.transaction(() => {
        // 1. Check if national_id exists in real_staff
        const existingStaff = db.prepare("SELECT national_id FROM real_staff WHERE national_id = ?").get(idCard);
        if (!existingStaff) {
          db.prepare("INSERT INTO real_staff (national_id, staff_id, fullname) VALUES (?, ?, ?)")
            .run(idCard, staffId, name);
        }

        // 2. Insert into user table
        db.prepare(`
          INSERT INTO user (user_id, national_id, email, phone, password_hash, role, picture_uri)
          VALUES (?, ?, ?, ?, ?, ?, ?)
        `).run(userId, idCard, email, phone, passwordHash, role, finalProfileUrl || null);

        // 3. LineID in extended_user (if it exists)
        if (finalLineId) {
          db.prepare(`
            INSERT OR REPLACE INTO extended_user (user_id, LineID)
            VALUES (?, ?)
          `).run(userId, finalLineId);
        }
      });

      registerTx();

      const newStaff = {
        id: idCard,
        idCard: idCard,
        name: name,
        email: email,
        phone: phone,
        type: role,
        lineId: finalLineId,
        LineID: finalLineId,
        image: finalProfileUrl || 'assets/resident_profile.png'
      };

      return res.status(201).json({ 
        success: true, 
        message: "Staff registered successfully",
        data: newStaff
      });

    } catch (error: any) {
      console.error("[FCM Backend] registerStaff Error:", error);
      if (error.message.includes("UNIQUE constraint failed")) {
        return res.status(400).json({ success: false, message: "Email or ID Card already registered" });
      }
      return res.status(500).json({ success: false, message: "Registration failed" });
    }
  }

  /**
   * PUT /auth/personnel/:nationalId
   */
  static async updatePersonnel(req: Request, res: Response) {
    try {
      const { nationalId } = req.params;
      const { name, phone, email, type, profileUrl, picture_uri, imageUrl, image } = req.body;
      const finalProfileUrl = profileUrl || picture_uri || imageUrl || image;

      // Update Real Staff
      if (name) {
        db.prepare("UPDATE real_staff SET fullname = ? WHERE national_id = ?").run(name, nationalId);
      }

      // Update User
      const updates: string[] = [];
      const values: any[] = [];

      if (phone) { updates.push("phone = ?"); values.push(phone); }
      if (email) { updates.push("email = ?"); values.push(email); }
      if (type) {
        let updatedRole = (type || "").toString().trim().toLowerCase();
        if (updatedRole === "ช่างซ่อม" || updatedRole === "technician") {
          updatedRole = "TECHNICIAN";
        } else if (updatedRole === "นิติกรหมู่บ้าน" || updatedRole === "juristic") {
          updatedRole = "JURISTIC";
        } else {
          updatedRole = updatedRole.toUpperCase();
        }
        updates.push("role = ?");
        values.push(updatedRole);
      }
      if (finalProfileUrl) { 
        updates.push("picture_uri = ?"); 
        values.push(finalProfileUrl); 
      }

      if (updates.length > 0) {
        values.push(nationalId);
        db.prepare(`UPDATE user SET ${updates.join(", ")} WHERE national_id = ?`).run(...values);
      }

      // Handle LineID Update
      const { lineId, LineID } = req.body;
      const finalLineId = lineId || LineID;
      
      if (finalLineId !== undefined) {
        const u = db.prepare("SELECT user_id FROM user WHERE national_id = ?").get(nationalId) as any;
        if (u) {
          db.prepare(`
            INSERT INTO extended_user (user_id, LineID) 
            VALUES (?, ?)
            ON CONFLICT(user_id) DO UPDATE SET LineID = excluded.LineID
          `).run(u.user_id, finalLineId);
        }
      }

      return res.status(200).json({ success: true, message: "Personnel updated" });
    } catch (error) {
      console.error("[FCM Backend] updatePersonnel Error:", error);
      return res.status(500).json({ success: false, message: "Update failed" });
    }
  }

  /**
   * DELETE /auth/personnel/:nationalId
   */
  static async deletePersonnel(req: Request, res: Response) {
    try {
      const { nationalId } = req.params;

      const deleteTx = db.transaction(() => {
        // Delete from user (will cascade to tasks if schema is set up, otherwise manual cleanup needed)
        // Schema v4.0 has ON DELETE CASCADE for tasks and items? Let's check.
        // Usually, deleting staff account should be handled carefully.
        db.prepare("DELETE FROM user WHERE national_id = ?").run(nationalId);
        db.prepare("DELETE FROM real_staff WHERE national_id = ?").run(nationalId);
      });

      deleteTx();

      return res.status(200).json({ success: true, message: "Personnel deleted" });
    } catch (error) {
      console.error("[FCM Backend] deletePersonnel Error:", error);
      return res.status(500).json({ success: false, message: "Deletion failed" });
    }
  }
}
