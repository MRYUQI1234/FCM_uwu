import Database from "better-sqlite3";
import fs from "fs";
import path from "path";
import bcrypt from "bcrypt";
import { v4 as uuidv4 } from "uuid";

const DB_NAME = "vivorn_villa.db";
const dbPath = path.join(process.cwd(), "database", DB_NAME);
const schemaPath = path.join(process.cwd(), "database/schema.sql");

console.log(`--- FCM Deep Data Seeding [Version 3.6: Dynamic Pricing] ---`);

if (!fs.existsSync(path.dirname(dbPath))) {
  fs.mkdirSync(path.dirname(dbPath), { recursive: true });
}

const db = new Database(dbPath);

const objectTemplates = [
  // Bathroom
  { name: "Bath Tub (Free-standing)", ref: "bath_tub_01", cat: "Bathroom", labor: 2500, part: 85000 },
  { name: "Toilet", ref: "toilet_01", cat: "Bathroom", labor: 1500, part: 25000 },
  { name: "Wash Basin", ref: "wash_basin_01", cat: "Bathroom", labor: 1500, part: 15000 },
  // Kitchen
  { name: "Kitchen Counter", ref: "counter_01", cat: "Kitchen", labor: 4000, part: 45000 },
  { name: "Sink", ref: "sink_01", cat: "Kitchen", labor: 1500, part: 15000 },
  { name: "Dishwasher", ref: "dishwasher_01", cat: "Kitchen", labor: 2000, part: 40000 },
  // Security & Home
  { name: "Home Tablet", ref: "tablet_01", cat: "SmartHome", labor: 3000, part: 15000 },
  { name: "Smart Door", ref: "door_smart_01", cat: "Security", labor: 1000, part: 12000 },
  { name: "Light Bulb", ref: "light_01", cat: "Electrical", labor: 500, part: 800 },
  // Structure
  { name: "Window (Aluminum)", ref: "window_01", cat: "Structure", labor: 500, part: 5000 },
  { name: "Wall (Repair per sqm)", ref: "wall_01", cat: "Structure", labor: 200, part: 0 },
  { name: "Tile (per sqm)", ref: "tile_01", cat: "Structure", labor: 250, part: 500 },
  { name: "Roof (Tile Type)", ref: "roof_01", cat: "Structure", labor: 500, part: 50 },
];

try {
  const schema = fs.readFileSync(schemaPath, "utf8");
  db.exec("PRAGMA foreign_keys = OFF;");
  db.exec(`
    DROP TABLE IF EXISTS task;
    DROP TABLE IF EXISTS ai_log;
    DROP TABLE IF EXISTS request;
    DROP TABLE IF EXISTS object;
    DROP TABLE IF EXISTS properties;
    DROP TABLE IF EXISTS users;
    DROP TABLE IF EXISTS real_estate_records;
  `);
  db.exec(schema);
  db.exec("PRAGMA foreign_keys = ON;");
  console.log("Status: Schema updated with Labor/Part fee support.");

  const thaiNames = ["สมชาย เข็มกลัด", "วิไลวรรณ สนิทวงศ์", "มานะ อดทน", "ปิติ ยินดี", "ชูใจ รุ่งเรือง"];
  const chineseNames = ["张伟 (Zhang Wei)", "李秀英 (Li Xiuying)", "王建国 (Wang Jianguo)", "刘洋 (Liu Yang)", "陈芳 (Chen Fang)"];
  const englishNames = ["John Doe", "Alice Smith", "Michael Johnson", "Sarah Williams", "Robert Brown"];

  const getRandom = (list: any[]) => list[Math.floor(Math.random() * list.length)];

  const insertProp = db.prepare("INSERT INTO properties (id, house_number, alley, status) VALUES (?, ?, ?, ?)");
  const insertRecord = db.prepare("INSERT INTO real_estate_records (national_id, house_number, full_name, citizen_type) VALUES (?, ?, ?, ?)");
  const insertObj = db.prepare("INSERT INTO object (id, property_id, object_name, model_ref_3d, category, labor_fee, part_fee) VALUES (?, ?, ?, ?, ?, ?, ?)");
  const insertRequest = db.prepare("INSERT INTO request (id, resident_id, property_id, status) VALUES (?, ?, ?, ?)");
  const insertTask = db.prepare("INSERT INTO task (id, request_id, object_id, object_type, description, urgency, status) VALUES (?, ?, ?, ?, ?, ?, ?)");
  const insertUser = db.prepare("INSERT INTO users (id, username, email, password_hash, role, national_id, is_first_login, full_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");

  console.log("Seeding 50 houses with full object inventory...");

  for (let i = 0; i < 50; i++) {
    const houseNum = 200 + i;
    const alleyName = `ซอย ${Math.floor(i / 5) + 1}`;
    const status = Math.random() > 0.3 ? "occupy" : "vacant";
    const propId = `prop_${houseNum}`;

    insertProp.run(propId, houseNum.toString(), alleyName, status);

    const createdObjects: {id: string, name: string}[] = [];
    objectTemplates.forEach(t => {
      const objId = uuidv4();
      insertObj.run(objId, propId, t.name, t.ref, t.cat, t.labor, t.part);
      createdObjects.push({id: objId, name: t.name});
    });

    if (status === "occupy") {
      const nationalId = (Math.random() * 10000000000000).toFixed(0).padStart(13, '0');
      const typeRand = Math.random();
      let name = typeRand < 0.4 ? getRandom(thaiNames) : (typeRand < 0.7 ? getRandom(chineseNames) : getRandom(englishNames));
      
      insertRecord.run(nationalId, houseNum.toString(), name, typeRand < 0.4 ? "Thai" : (typeRand < 0.7 ? "Chinese" : "English"));

      if (Math.random() > 0.4) {
        const userId = uuidv4();
        insertUser.run(userId, `user_${houseNum}`, `res_${houseNum}@vivorn.com`, bcrypt.hashSync(nationalId, 8), "Resident", nationalId, 1, name);

        // Generate history
        const requestId = uuidv4();
        insertRequest.run(requestId, userId, propId, "Completed");
        const taskObj = getRandom(createdObjects);
        insertTask.run(uuidv4(), requestId, taskObj.id, "Repair", `Reported issue with ${taskObj.name}`, "normal", "Completed");
      }
    }
  }

  const adminPass = bcrypt.hashSync("AdminP@ss123", 10);
  insertUser.run(uuidv4(), "admin_jane", "admin@vivorn.com", adminPass, "Jurisdictic", "9999999999999", 0, "Jane Architect");

  console.log("Success: Seeding complete.");
  console.log("- Added labor_fee and part_fee to all 650 objects (13 items x 50 houses)");

} catch (err) {
  console.error("Critical Failure:", err);
} finally {
  db.close();
}
