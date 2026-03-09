import Database from "better-sqlite3";
import path from "path";
import fs from "fs";

const dbPath = path.join(process.cwd(), "database/vivorn_villa.db");
const schemaPath = path.join(process.cwd(), "database/schema.sql");

// Ensure directory exists
if (!fs.existsSync(path.dirname(dbPath))) {
  fs.mkdirSync(path.dirname(dbPath), { recursive: true });
}

export const db = new Database(dbPath);

// Initialize database if it's empty
const tables = db.prepare("SELECT name FROM sqlite_master WHERE type='table'").all();
if (tables.length === 0) {
  console.log("Initializing database schema...");
  const schema = fs.readFileSync(schemaPath, "utf8");
  db.exec(schema);
}

export default db;
