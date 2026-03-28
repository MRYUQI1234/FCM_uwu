-- Vivorn Villa FCM Database Schema v4.0
-- Technician Reporting & Resident Feedback System

PRAGMA foreign_keys = ON;

-- 1. ข้อมูลพนักงานจริง
CREATE TABLE IF NOT EXISTS real_staff (
    national_id TEXT PRIMARY KEY, 
    staff_id    TEXT NOT NULL,
    fullname    TEXT NOT NULL
);

-- 2. ข้อมูลผู้อยู่อาศัยจริง
CREATE TABLE IF NOT EXISTS real_estate (
    national_id TEXT PRIMARY KEY,
    fullname    TEXT NOT NULL
);

-- 3. ตารางบัญชีผู้ใช้
CREATE TABLE IF NOT EXISTS user (
    user_id TEXT NOT NULL PRIMARY KEY,
    national_id TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    pin_hash TEXT DEFAULT NULL,
    picture_uri TEXT DEFAULT NULL,

    -- บทบาท
    role TEXT CHECK (role IN ('RESIDENT','JURISTIC','TECHNICIAN'))

    -- Note: national_id is polymorphic. 
    -- If role='RESIDENT', it references real_estate(national_id).
    -- If role='JURISTIC' or 'TECHNICIAN', it references real_staff(national_id).
    -- SQLite does not support a single column having optional foreign keys to different tables easily,
    -- so we handle the integrity via triggers or application logic.
);

-- 4. ข้อมูลลูกบ้านเพิ่มเติม (มีหรือไม่มีก็ได้)
CREATE TABLE IF NOT EXISTS extended_user(
    user_id TEXT PRIMARY KEY,
    LineID  TEXT NOT NULL,

    -- มั่นใจว่า จะถูกลบเมื่อบัญชีถูกลบ
    FOREIGN KEY (user_id) REFERENCES user (user_id) ON DELETE CASCADE
);

-- 5. ตารางบ้าน
CREATE TABLE IF NOT EXISTS house (
    house_address TEXT PRIMARY KEY,
    national_id TEXT,
    soi TEXT NOT NULL,
    -- sqlite ไม่มี enum type and DATETIME โดยตรง
    status TEXT CHECK(status IN ('ACTIVE','INACTIVE')) DEFAULT 'ACTIVE',
    -- เช็ครูปแบบของวันเวลา YYYY-MM-DD
    activate_date TEXT CHECK (activate_date = strftime('%Y-%m-%d', activate_date)),

    -- มั่นใจว่า เมื่อเจ้าของเปลี่ยนหรือถูกลบจะลบด้วย เพื่อให้บ้านสามารถสร้างใหม่ได้โดยใช้ PK เดิม
    FOREIGN KEY (national_id) REFERENCES real_estate (national_id) ON DELETE CASCADE
);

-- 6. ตารางสิ่งของภายในบ้าน
CREATE TABLE IF NOT EXISTS object (
    object_id TEXT PRIMARY KEY,
    cat_id    TEXT NOT NULL,
    house_address TEXT NOT NULL,

    -- ชื่อ object ในไฟล์ glb
    glb_name TEXT NOT NULL,
    name     TEXT NOT NULL,

    -- มั่นใจว่าสิ่งของจะถูกลบหากบ้านถูกลบ (เกิดขึ้นเมื่อเปลี่ยนเจ้าของหรือถูกลบ) เพื่อสร้างใหม่เมื่อมีคนย้ายเข้า
    FOREIGN KEY (house_address) REFERENCES house (house_address) ON DELETE CASCADE
);

-- 7. ข้อมูลประเภทสิ่งของ
CREATE TABLE IF NOT EXISTS category (
    cat_id TEXT PRIMARY KEY,
    name   TEXT NOT NULL

    -- ไม่มีอะไรยังไม่มีกำหนดการจะลบเร็วๆนี้
);

-- 8. คำขอแจ้งซ่อม
CREATE TABLE IF NOT EXISTS request (
    request_id TEXT PRIMARY KEY,
    user_id    TEXT NOT NULL,
    title      TEXT NOT NULL,

    -- sqlite ไม่มี enum ใช้ Text แทน
    type       TEXT CHECK (type IN ('NORMAL', 'URGENT', 'CENTRAL')) DEFAULT 'NORMAL',
    -- ลืมใส่ Cancelled ใน SDD
    status     TEXT CHECK (status IN ('CREATED', 'ASSIGNED', 'BEGAN', 'COMPLETED','EVALUATED','DECLINED', 'CANCELED')) DEFAULT 'CREATED',
    
    -- ISO 8601 YYYY-MM-DD HH:MM:SS
    created_at TEXT CHECK (created_at = strftime('%Y-%m-%d %H:%M:%S', created_at)),
    completed_at TEXT DEFAULT NULL CHECK (
        completed_at IS NULL
        OR
        completed_at = strftime('%Y-%m-%d %H:%M:%S', completed_at)),
    
    -- เพิ่มฟิลด์สำหรับเหตุผลการปฏิเสธ (FE-03)
    rejection_reason TEXT,
    rejection_template TEXT,

    -- ตอนนี้ยังไม่มีระบบรองรับการเก็บข้อมูลผู้ใช้ที่ถูกลบตาม SDD จึงลบข้อมูลทุกอย่างทิ้ง
    FOREIGN KEY (user_id) REFERENCES user (user_id) ON DELETE CASCADE
);

-- 9. ข้อมูลงานในแต่ละคำขอ
CREATE TABLE IF NOT EXISTS task(
    task_id   TEXT PRIMARY KEY,
    -- เพิ่มฟิลด์ request_id ที่ลืมใน SDD ลืมการเชื่อมกับคำขอแจ้งซ่อม
    request_id TEXT NOT NULL,
    object_id TEXT NOT NULL,
    detail    TEXT NOT NULL,

    -- ISO 8601 YYYY-MM-DD 
    prefer_date TEXT CHECK (
        -- เช็คความถูกต้อง
        prefer_date = strftime('%Y-%m-%d %H:%M:%S', prefer_date)
        AND
        -- เช็คช่วงเวลา เช้า หรือ บ่าย
        strftime('%H:%M:%S', prefer_date) IN ('09:30:00', '13:00:00')
    ),
    -- เพิ่มฟิลด์สำหรับรายงานของช่าง (S-03)
    status      TEXT DEFAULT 'Pending',
    task_report TEXT,
    after_repair_image_url TEXT,

    -- เมื่อคำขอถูกลบจะถูกลบไปด้วย
    FOREIGN KEY (request_id) REFERENCES request (request_id) ON DELETE CASCADE

);

-- 10. ข้อมูลการมอบหมานงาน (ใช้สำหรับการมอบหมายช่างหลายๆคน)
CREATE TABLE IF NOT EXISTS assignment(
    assignment_id TEXT PRIMARY KEY,
    request_id TEXT NOT NULL,
    -- ข้อมูลนี้ใช้ staff_id จากตาราง real_staff 
    juristic_id   TEXT NOT NULL,
    technician_id TEXT NOT NULL,
    -- ISO 8601 YYYY-MM-DD HH:MM:SS
    created_at TEXT CHECK (created_at = strftime('%Y-%m-%d %H:%M:%S', created_at)),

    -- เมื่อคำขอถูกลบจะถูกลบไปด้วย
    FOREIGN KEY (request_id) REFERENCES request (request_id) ON DELETE CASCADE
);

-- 11. การประเมินหลังการซ่อม
CREATE TABLE IF NOT EXISTS evaluation(
    evaluation_id TEXT PRIMARY KEY,
    request_id    TEXT NOT NULL,
    comment       TEXT NOT NULL,
    -- คะแนนความพึงพอใจ : ดาว
    score         INTEGER CHECK (score BETWEEN 1 AND 5),

    -- ISO 8601 YYYY-MM-DD HH:MM:SS
    created_at TEXT CHECK (created_at = strftime('%Y-%m-%d %H:%M:%S', created_at)),

    -- เมื่อคำขอถูกลบจะถูกลบไปด้วย
    FOREIGN KEY (request_id) REFERENCES request (request_id) ON DELETE CASCADE
);

-- 12. บทสนทนา (Thread) พูดคุยกับ AI
CREATE TABLE IF NOT EXISTS ai_conversation(
    conversation_id TEXT PRIMARY KEY,
    user_id         TEXT NOT NULL,
    title           TEXT,

    -- id ของ message ล่าสุดในบทสนทนา
    last_message_id TEXT NOT NULL,
    -- เก็บสถานะของบทสนทนา ซึ่งเมื่อแจ้งซ่อมในบทสนทนานี้สำเร็จ ผู้ใช้จะคุยต่อไม่ได้
    -- เป็นการถูก archive บทสนทนาไว้
    complete         INTEGER CHECK (complete BETWEEN 0 AND 1) DEFAULT 0,
   
    -- ISO 8601 YYYY-MM-DD HH:MM:SS
    created_at TEXT DEFAULT (strftime('%Y-%m-%d %H:%M:%S', 'now')),

    -- ถ้าบัญชีถูกลบข้อมูลจะถูกลบไปด้วยเพราะหา id ไม่เจอ
    FOREIGN KEY (user_id) REFERENCES user (user_id) ON DELETE CASCADE
);

-- 13. ข้อความในบทสนทนากับ AI
CREATE TABLE IF NOT EXISTS ai_messages(
    message_id      TEXT PRIMARY KEY,
    conversation_id TEXT NOT NULL,
    owner           TEXT CHECK (owner IN ('USER', 'AI')),
    message         TEXT NOT NULL,
    action_data     TEXT,
    action_state    TEXT DEFAULT 'none',
    log_id          TEXT NOT NULL,
    created_at      TEXT DEFAULT (strftime('%Y-%m-%d %H:%M:%S', 'now')),

    -- ถ้าการสนทนาถูกลบจะถูกลบไปด้วย
    FOREIGN KEY (conversation_id) REFERENCES ai_conversation (conversation_id) ON DELETE CASCADE
);

-- 14. บันทึกการตอบเรียกใช้ API ของ AI เพื่อวิเคราะห์และตรวจสอบ performance
CREATE TABLE IF NOT EXISTS ai_log(
    log_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    raw_prompt      TEXT NOT NULL,
    raw_response    TEXT NOT NULL,
    success_flag    INTEGER CHECK (success_flag BETWEEN 0 AND 1),
    error_message   TEXT,
    processing_time_sec REAL,
    created_at      TEXT DEFAULT (strftime('%Y-%m-%d %H:%M:%S', 'now'))
);

-- real president
INSERT INTO real_estate (national_id, fullname) VALUES ('1234567890123','Test User');
INSERT INTO house (house_address, national_id, soi) VALUES ('9999/10000', '1234567890123','99');

-- admin
INSERT INTO real_staff (national_id, staff_id, fullname) VALUES ('1509966298430', 'a12096e7-a529-4534-8b5e-18ef499bc1ff','Vivorn Admin');
INSERT INTO user (user_id, national_id, email, phone, password_hash, role) VALUES ('521f0bc5-bfa3-4477-b310-857a9a36ee5f','1509966298430', 'estelianalaa@gmail.com', '0928566488', '$2a$12$FoOJIptvwN4I/89Xeb.4SuqhIkHy78PUM4NDtn4dYfj.niw0mcZSO', 'JURISTIC');

-- 15. ตารางสำหรับรีเซ็ตรหัสผ่าน
CREATE TABLE IF NOT EXISTS password_resets (
    token TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    expires_at DATETIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES user (user_id) ON DELETE CASCADE
);