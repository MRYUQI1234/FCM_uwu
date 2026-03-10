import Database from "better-sqlite3";
import path from "path";

const dbPath = path.join(process.cwd(), "database/vivorn_villa.db");
const db = new Database(dbPath);

try {
    db.prepare("ALTER TABLE users ADD COLUMN position TEXT").run();
    console.log("Successfully added 'position' column to 'users' table.");
} catch (error: any) {
    if (error.message.includes("duplicate column name")) {
        console.log("Column 'position' already exists.");
    } else {
        console.error("Migration failed:", error);
        process.exit(1);
    }
}
