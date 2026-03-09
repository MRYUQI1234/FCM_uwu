import Database from "better-sqlite3";
import bcrypt from "bcrypt";
import { v4 as uuidv4 } from "uuid";

const db = new Database("database/vivorn_villa.db");

try {
    const adminPass = bcrypt.hashSync("AdminP@ss123", 10);
    const resPass = bcrypt.hashSync("1234567890123", 10); // Use 1234567890123 as National ID / Password

    db.prepare(`
    INSERT OR IGNORE INTO real_estate_records (national_id, house_number, full_name, citizen_type) 
    VALUES ('1234567890123', '200', 'Test Resident', 'Thai')
  `).run();

    const existingRes = db.prepare("SELECT id FROM users WHERE email = ?").get("res_200@vivorn.com");
    if (existingRes) {
        db.prepare("UPDATE users SET password_hash = ?, national_id = '1234567890123' WHERE email = ?").run(resPass, "res_200@vivorn.com");
    } else {
        db.prepare(`
      INSERT INTO users (id, username, email, password_hash, role, national_id, is_first_login, full_name) 
      VALUES (?, 'user_200_test', 'res_200@vivorn.com', ?, 'Resident', '1234567890123', 1, 'Test Resident')
    `).run(uuidv4(), resPass);
    }

    const existingAdmin = db.prepare("SELECT id FROM users WHERE email = ?").get("admin@vivorn.com");
    if (existingAdmin) {
        db.prepare("UPDATE users SET password_hash = ?, role = 'Jurisdictic' WHERE email = ?").run(adminPass, "admin@vivorn.com");
    } else {
        db.prepare(`
      INSERT INTO users (id, username, email, password_hash, role, national_id, is_first_login, full_name) 
      VALUES (?, 'admin_test', 'admin@vivorn.com', ?, 'Jurisdictic', '9999999999999', 0, 'Admin Test')
    `).run(uuidv4(), adminPass);
    }

    console.log("Test users guaranteed to exist!");
    console.log("Resident: res_200@vivorn.com / 1234567890123");
    console.log("Admin: admin@vivorn.com / AdminP@ss123");

} catch (err) {
    console.error(err);
} finally {
    db.close();
}
