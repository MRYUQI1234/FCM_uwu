-- Vivorn Villa FCM Database Schema v3.7
-- Technician Reporting & Resident Feedback System

PRAGMA foreign_keys = ON;

-- 0. real_estate_records: Whitelist for residents
CREATE TABLE IF NOT EXISTS real_estate_records (
    national_id TEXT PRIMARY KEY,
    house_number TEXT NOT NULL,
    full_name TEXT NOT NULL,
    citizen_type TEXT -- Thai, Chinese, English
);

-- 1. users: Core identity
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    password_hash TEXT NOT NULL,
    pin_hash TEXT,
    is_first_login BOOLEAN DEFAULT 1,
    role TEXT NOT NULL CHECK(role IN ('Resident', 'Technician', 'Jurisdictic')),
    national_id TEXT NOT NULL,
    employee_id TEXT UNIQUE,
    full_name TEXT,
    face_image_url TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 2. properties: The units
CREATE TABLE IF NOT EXISTS properties (
    id TEXT PRIMARY KEY,
    house_number TEXT UNIQUE NOT NULL,
    alley TEXT,
    status TEXT NOT NULL CHECK(status IN ('vacant', 'occupy')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 3. object: Physical items
CREATE TABLE IF NOT EXISTS object (
    id TEXT PRIMARY KEY,
    property_id TEXT NOT NULL,
    object_name TEXT NOT NULL,
    model_ref_3d TEXT NOT NULL,
    category TEXT,
    labor_fee REAL DEFAULT 0,
    part_fee REAL DEFAULT 0,
    FOREIGN KEY (property_id) REFERENCES properties(id)
);

-- 4. request: Master maintenance record
CREATE TABLE IF NOT EXISTS request (
    id TEXT PRIMARY KEY,
    resident_id TEXT NOT NULL,
    property_id TEXT NOT NULL,
    technician_id TEXT, -- Added: the technician assigned to the whole request
    status TEXT CHECK(status IN ('Created', 'Assigned', 'In-Progress', 'Completed', 'Reviewed', 'Cancelled')) DEFAULT 'Created',
    repair_report TEXT, -- Added: Summary report from technician
    after_repair_image_url TEXT, -- Added
    completed_at DATETIME, -- Added: To enforce 7-day feedback rule
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (resident_id) REFERENCES users(id),
    FOREIGN KEY (property_id) REFERENCES properties(id),
    FOREIGN KEY (technician_id) REFERENCES users(id)
);

-- 5. task: Individual repair items
CREATE TABLE IF NOT EXISTS task (
    id TEXT PRIMARY KEY,
    request_id TEXT NOT NULL,
    object_id TEXT, 
    object_type TEXT,
    description TEXT,
    urgency TEXT CHECK(urgency IN ('normal', 'emergency')) DEFAULT 'normal',
    status TEXT DEFAULT 'Pending' CHECK(status IN ('Pending', 'InProgress', 'Completed')),
    task_report TEXT, -- Added: Detailed report per item
    after_repair_image_url TEXT, -- Added
    prefer_date DATETIME,
    FOREIGN KEY (request_id) REFERENCES request(id) ON DELETE CASCADE,
    FOREIGN KEY (object_id) REFERENCES object(id)
);

-- 6. evaluation: Resident feedback (FE-03)
CREATE TABLE IF NOT EXISTS evaluation (
    id TEXT PRIMARY KEY,
    request_id TEXT UNIQUE NOT NULL,
    rating INTEGER NOT NULL CHECK(rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (request_id) REFERENCES request(id)
);

-- 7. ai_log: System performance
CREATE TABLE IF NOT EXISTS ai_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    request_id TEXT,
    raw_prompt TEXT,
    raw_response TEXT,
    tokens_used INTEGER,
    success_flag BOOLEAN,
    error_message TEXT,
    processing_time_sec REAL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (request_id) REFERENCES request(id)
);

CREATE INDEX IF NOT EXISTS idx_users_national_id ON users(national_id);
CREATE INDEX IF NOT EXISTS idx_task_request ON task(request_id);
CREATE INDEX IF NOT EXISTS idx_object_property ON object(property_id);
CREATE INDEX IF NOT EXISTS idx_evaluation_request ON evaluation(request_id);

-- 8. ai_conversations: Master record for an AI chat session
CREATE TABLE IF NOT EXISTS ai_conversations (
    id TEXT PRIMARY KEY,
    resident_id TEXT NOT NULL,
    title TEXT,                      -- e.g. "Request: Kitchen Leak"
    last_message TEXT,
    is_archived BOOLEAN DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (resident_id) REFERENCES users(id)
);

-- 9. ai_messages: Thread logs between Resident and Gemini AI
CREATE TABLE IF NOT EXISTS ai_messages (
    id TEXT PRIMARY KEY,
    conversation_id TEXT NOT NULL,
    sender_type TEXT CHECK(sender_type IN ('USER', 'AI')), 
    content TEXT NOT NULL,
    action_data TEXT,
    action_state TEXT DEFAULT 'none',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (conversation_id) REFERENCES ai_conversations(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_ai_messages_conversation ON ai_messages(conversation_id);