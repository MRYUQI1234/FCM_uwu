import { Request, Response } from "express";
import { db } from "../database";

export class DevController {
  /**
   * POST /api/dev/query
   * Dev-only direct DB access bridge.
   */
  static async query(req: Request, res: Response) {
    try {
      const { sql, params } = req.body;
      
      if (!sql) return res.status(400).json({ error: "No SQL provided" });

      if (sql.trim().toUpperCase().startsWith("SELECT") || sql.trim().toUpperCase().startsWith("PRAGMA")) {
        const rows = db.prepare(sql).all(...(params || []));
        return res.json({ success: true, data: rows });
      } else {
        const result = db.prepare(sql).run(...(params || []));
        return res.json({ success: true, result });
      }
    } catch (error: any) {
      console.error("Dev DB Bridge Error:", error);
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  /**
   * GET /api/dev/tables
   * Get all tables from sqlite_master
   */
  static async getTables(req: Request, res: Response) {
    try {
      const tables = db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';").all();
      return res.json({ success: true, data: tables.map((t: any) => t.name) });
    } catch (error: any) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }
}
