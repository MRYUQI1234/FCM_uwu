import { GoogleGenerativeAI } from "@google/generative-ai";
import dotenv from "dotenv";
import { db } from "../database";

dotenv.config();

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || "");

export interface DBObject {
  id: string;
  object_name: string;
  category: string;
}

export interface TaskRecord {
  object_id: string | null;
  object_type: string;
  description: string;
  urgency: "normal" | "emergency";
  status: string;
  prefer_date: string;
  prefer_time?: string;
}

export interface RequestRecord {
  status: string;
  tasks: TaskRecord[];
}

export interface IntentResult {
  request?: RequestRecord;
  confidence_score?: number;
  follow_up_message?: string | null;
  fallback_required?: boolean;
  error_type?: string;
  message?: string;
  raw_prompt?: string;
  raw_response?: string;
  usage_metadata?: any;
}

const HOUSE_OBJECTS: DBObject[] = [
  // --- Bathroom ---
  { id: "bathroom_door", object_name: "Bathroom Door", category: "Structure" },
  { id: "bathroom_floor", object_name: "Bathroom Floor", category: "Structure" },
  { id: "bathroom_light", object_name: "Bathroom Light", category: "Electrical" },
  { id: "bathroom_light_switch", object_name: "Bathroom Light Switch", category: "Electrical" },
  { id: "bathroom_sink", object_name: "Bathroom Sink", category: "Plumbing" },
  { id: "bathroom_tub", object_name: "Bathroom Tub", category: "Plumbing" },
  { id: "bathroom_wall", object_name: "Bathroom Wall", category: "Structure" },
  { id: "bathroom_window", object_name: "Bathroom Window", category: "Structure" },
  { id: "bathroom_toilet", object_name: "Bathroom Toilet", category: "Plumbing" },

  // --- Kitchen ---
  { id: "kitchen_floor", object_name: "Kitchen Floor", category: "Structure" },
  { id: "kitchen_fridge", object_name: "Refrigerator", category: "Appliance" },
  { id: "kitchen_hanged_cabinet", object_name: "Hanging Cabinet", category: "Furniture" },
  { id: "kitchen_light", object_name: "Kitchen Light", category: "Electrical" },
  { id: "kitchen_light_switch", object_name: "Kitchen Light Switch", category: "Electrical" },
  { id: "kitchen_sink", object_name: "Kitchen Sink", category: "Plumbing" },
  { id: "kitchen_small_floor_cabinet", object_name: "Floor Cabinet", category: "Furniture" },
  { id: "kitchen_stove", object_name: "Kitchen Stove", category: "Appliance" },
  { id: "kitchen_wall", object_name: "Kitchen Wall", category: "Structure" },
  { id: "kitchen_window", object_name: "Kitchen Window", category: "Structure" },

  // --- Living Room ---
  { id: "livingroom_carpet", object_name: "Living Room Carpet", category: "Furniture" },
  { id: "livingroom_coffe_table", object_name: "Coffee Table", category: "Furniture" },
  { id: "livingroom_floor", object_name: "Living Room Floor", category: "Structure" },
  { id: "livingroom_light", object_name: "Living Room Light", category: "Electrical" },
  { id: "livingroom_light_switch", object_name: "Living Room Light Switch", category: "Electrical" },
  { id: "livingroom_lock", object_name: "Smart Door Lock", category: "Electrical" },
  { id: "livingroom_smartdoor", object_name: "Smart Front Door", category: "Structure" },
  { id: "livingroom_smartdoor_tablet", object_name: "Smart Door Tablet", category: "Appliance" },
  { id: "livingroom_sofa", object_name: "Living Room Sofa", category: "Furniture" },
  { id: "livingroom_tapis", object_name: "Living Room Rug", category: "Furniture" },
  { id: "livingroom_tv", object_name: "TV", category: "Appliance" },
  { id: "livingroom_tv_closet", object_name: "TV Cabinet", category: "Furniture" },
  { id: "livingroom_wall", object_name: "Living Room Wall", category: "Structure" },
  { id: "livingroom_window", object_name: "Living Room Window", category: "Structure" },

  // --- Main Bedroom ---
  { id: "main_bedroom_aircon", object_name: "Air Conditioner (Main)", category: "Appliance" },
  { id: "main_bedroom_aircon_remote", object_name: "AC Remote (Main)", category: "Appliance" },
  { id: "main_bedroom_bathroom_door", object_name: "Master Bathroom Door", category: "Structure" },
  { id: "main_bedroom_bathroom_floor", object_name: "Master Bathroom Floor", category: "Structure" },
  { id: "main_bedroom_bathroom_light", object_name: "Master Bathroom Light", category: "Electrical" },
  { id: "main_bedroom_bathroom_light_switch", object_name: "Master Bathroom Light Switch", category: "Electrical" },
  { id: "main_bedroom_bathroom_sink", object_name: "Master Bathroom Sink", category: "Plumbing" },
  { id: "main_bedroom_bathroom_toilet", object_name: "Master Bathroom Toilet", category: "Plumbing" },
  { id: "main_bedroom_bathroom_tub", object_name: "Master Bathroom Tub", category: "Plumbing" },
  { id: "main_bedroom_bathroom_wall", object_name: "Master Bathroom Wall", category: "Structure" },
  { id: "main_bedroom_bathroom_window", object_name: "Master Bathroom Window", category: "Structure" },
  { id: "main_bedroom_bed", object_name: "Master Bed", category: "Furniture" },
  { id: "main_bedroom_door", object_name: "Main Bedroom Door", category: "Structure" },
  { id: "main_bedroom_drawer", object_name: "Bedroom Drawer", category: "Furniture" },
  { id: "main_bedroom_floor", object_name: "Main Bedroom Floor", category: "Structure" },
  { id: "main_bedroom_light", object_name: "Main Bedroom Light", category: "Electrical" },
  { id: "main_bedroom_light_switch", object_name: "Main Bedroom Light Switch", category: "Electrical" },
  { id: "main_bedroom_tapis", object_name: "Master Bedroom Rug", category: "Furniture" },
  { id: "main_bedroom_wall", object_name: "Main Bedroom Wall", category: "Structure" },
  { id: "main_bedroom_window", object_name: "Main Bedroom Window", category: "Structure" },

  // --- Secondary Bedroom ---
  { id: "secondary_bedroom_aircon", object_name: "Air Conditioner (Small)", category: "Appliance" },
  { id: "secondary_bedroom_aircon_remote", object_name: "AC Remote (Small)", category: "Appliance" },
  { id: "secondary_bedroom_closet", object_name: "Bedroom Closet", category: "Furniture" },
  { id: "secondary_bedroom_door", object_name: "Secondary Bedroom Door", category: "Structure" },
  { id: "secondary_bedroom_floor", object_name: "Secondary Bedroom Floor", category: "Structure" },
  { id: "secondary_bedroom_light", object_name: "Secondary Bedroom Light", category: "Electrical" },
  { id: "secondary_bedroom_light_switch", object_name: "Secondary Bedroom Light Switch", category: "Electrical" },
  { id: "secondary_bedroom_red", object_name: "Secondary Bed", category: "Furniture" },
  { id: "secondary_bedroom_wall", object_name: "Secondary Bedroom Wall", category: "Structure" },
  { id: "secondary_bedroom_window", object_name: "Secondary Bedroom Window", category: "Structure" },

  // --- Washroom ---
  { id: "WashingMachine", object_name: "Washing Machine", category: "Appliance" },
  { id: "washroom_door", object_name: "Washroom Door", category: "Structure" },
  { id: "washroom_dryer", object_name: "Dryer", category: "Appliance" },
  { id: "washroom_floor", object_name: "Washroom Floor", category: "Structure" },
  { id: "washroom_light", object_name: "Washroom Light", category: "Electrical" },
  { id: "washroom_switch", object_name: "Washroom Light Switch", category: "Electrical" },
  { id: "washroom_wall", object_name: "Washroom Wall", category: "Structure" },
  { id: "washroom_window", object_name: "Washroom Window", category: "Structure" },

  // --- Exterior & Infrastructure ---
  { id: "exterior_back_raintrack", object_name: "Rain Track", category: "Infrastructure" },
  { id: "exterior_back_wall", object_name: "Back Wall", category: "Structure" },
  { id: "exterior_front_entrance_decoration", object_name: "Entrance Decoration", category: "Structure" },
  { id: "exterior_front_rampart", object_name: "Front Rampart", category: "Structure" },
  { id: "exterior_front_roof", object_name: "Front Roof", category: "Structure" },
  { id: "exterior_front_stone_decoration", object_name: "Stone Decoration", category: "Structure" },
  { id: "exterior_front_wall", object_name: "Front Wall", category: "Structure" },
  { id: "exterior_front_wood_decoration", object_name: "Wood Decoration", category: "Structure" },
  { id: "exterior_left_wall", object_name: "Left Side Wall", category: "Structure" },
  { id: "exterior_left_wood_decoration", object_name: "Side Wood Decoration", category: "Structure" },
  { id: "exterior_left_condenser", object_name: "AC Condenser (Left)", category: "Appliance" },
  { id: "exterior_right_condenser", object_name: "AC Condenser (Right)", category: "Appliance" },
  { id: "exterior_right_wall", object_name: "Right Side Wall", category: "Structure" },
  { id: "exterior_roof", object_name: "Main Roof", category: "Structure" }
];

export class AIService {
  private static model = genAI.getGenerativeModel({
    model: "gemini-3.1-flash-lite-preview",
    systemInstruction: `You are the Senior Resident Assistant "Vivorn" for Vivorn Villa (Ultra-Luxury Estate). 
Your primary goal is to map resident maintenance requests to the internal equipment list precisely. 
You handle everything from Appliances and Infrastructure to Interior Furniture and Building Structure (Walls, Floors, Roof).
Always maintain a premium, professional, and helpful tone. Strictly output JSON.`,
    generationConfig: {
      responseMimeType: "application/json",
      temperature: 0.1,
    }
  });

  static async analyzeRepairIntent(
    description: string,
    residentInfo?: { name: string; house_number: string },
    chatHistory?: string,
    preferredLanguage: string = "th"
  ): Promise<IntentResult> {
    const startTime = Date.now();
    const objectsContext = HOUSE_OBJECTS
      .map(obj => `- ID: ${obj.id}, Name: ${obj.object_name}, Category: ${obj.category}`)
      .join("\n");

    const prompt = `
      SYSTEM INSTRUCTION:
      You are a Senior Resident Assistant for Vivorn Villa (Ultra-Luxury Estate).
      Your primary goal is to assist residents with maintenance requests and provide estate information.
      
      PERSONALIZATION:
      - CRITICAL: You MUST use the resident's full name frequently. It is essential for an ultra-luxury feel.
      - ADDRESSING: Always address them as "Khun [Name]" in Thai or "Mr./Ms. [Name]" in English.
      
      CORE CAPABILITIES:
      1. CRITICAL: Detect "Maintenance/Repair Intent". If detected, MUST return an array of "tasks" in the JSON.
      2. MULTI-LANGUAGE: You MUST respond in ${preferredLanguage === 'th' ? 'Thai (ภาษาไทย)' : preferredLanguage === 'en' ? 'English' : 'Chinese (中文)'}.
      3. CONVERSATIONAL: Be extremely polite, professional, and helpful. 
      
      MAINTENANCE LOGIC:
      - CRITICAL REQUIREMENT: Do NOT populate the "tasks" array until you have BOTH:
        1. A clear description of the issue (e.g., "Air con doesn't cool", not just "Air con fix").
        2. A preferred Date and Time. Time MUST be either exactly "09:30:00" (Morning) or "13:00:00" (Afternoon).
      - ACTION: If any of these are missing, leave "tasks" as an empty array [] and politely ask the resident for the missing information using their full name.
      - URGENCIES: Default 'normal'. Use 'emergency' only for life-safety threats.
      - DETAIL: If input is vague, ask for specific symptoms before finalizing.
      
      CONTEXT:
      - Current Date: ${new Date().toISOString().split('T')[0]} (${new Date().toLocaleDateString('en-US', { weekday: 'long' })})
      - Resident: ${residentInfo?.name || "Member"} (House: ${residentInfo?.house_number || "Unknown"})
      - Equipment List (Grouped by Category): 
${objectsContext}

      - Recent Messages: 
${chatHistory || "No previous history."}

      INSTRUCTIONS FOR MATCHING:
      - For structural issues (leaks, cracks), match with categories "Structure" or "Infrastructure".
      - For furniture issues (broken leg, jammed drawer), match with category "Furniture".
      - For appliance issues, match with category "Appliance".
      - BE SPECIFIC: If they say "bedroom AC", use "main_bedroom_aircon" or "secondary_bedroom_aircon" based on context.
      - If multiple items are mentioned, create a task for each.

      RESIDENT INPUT: "${description}"

      OUTPUT FORMAT (Strict JSON only):
      {
        "request": { 
          "status": "Created", 
          "tasks": [ 
            {
              "object_id": "Exact ID from list", 
              "object_name": "Name from list", 
              "object_type": "Category from list", 
              "description": "Specific issue details", 
              "urgency": "normal/emergency",
              "prefer_date": "YYYY-MM-DD",
              "prefer_time": "09:30:00" // MUST be exactly "09:30:00" or "13:00:00"
            } 
          ] 
        },
        "follow_up_message": "Your polite response using the resident's name.",
        "confidence_score": 0.8-1.0
      }
      *Note: If no maintenance is detected, leave 'tasks' as an empty array [].
    `;

    console.log(`[AIService] Calling Gemini API (${this.model.model})...`);

    try {
      const result = await this.model.generateContent(prompt);
      const response = await result.response;
      let text = response.text();
      const apiTime = (Date.now() - startTime) / 1000;

      console.log(`[AIService] Raw Response Received (${apiTime}s):`);
      console.log(text);
      console.log("-----------------------------------------");

      // Extract JSON block from response
      const jsonStart = text.indexOf("{");
      const jsonEnd = text.lastIndexOf("}");

      if (jsonStart !== -1 && jsonEnd !== -1 && jsonEnd > jsonStart) {
        const jsonStr = text.substring(jsonStart, jsonEnd + 1);
        try {
          const parsed = JSON.parse(jsonStr);
          return {
            ...parsed,
            raw_prompt: prompt,
            raw_response: text,
            usage_metadata: response.usageMetadata
          };
        } catch (err: any) {
          console.error("[AIService] JSON Parse Error:", err.message);
        }
      }

      return {
        follow_up_message: text,
        confidence_score: 1.0,
        raw_prompt: prompt,
        raw_response: text,
        usage_metadata: response.usageMetadata
      };
    } catch (error: any) {
      const processingTime = (Date.now() - startTime) / 1000;
      const errorMessage = error.message || "Unknown Gemini Error";
      console.error(`[AIService] Gemini ERROR after ${processingTime}s:`, errorMessage);

      try {
        db.prepare(`
          INSERT INTO ai_log (raw_prompt, raw_response, success_flag, error_message, processing_time_sec)
          VALUES (?, ?, 0, ?, ?)
        `).run(prompt, "N/A", errorMessage, processingTime);
      } catch (logErr) {
        console.error("Failed to log AI error to DB:", logErr);
      }

      if (errorMessage.includes("503") || errorMessage.includes("429") || errorMessage.includes("overloaded")) {
        return {
          request: { status: "Created", tasks: [] },
          follow_up_message: null,
          confidence_score: 0,
          fallback_required: true,
          error_type: "API_OVERLOAD",
          message: "ขออภัยค่ะตอนนี้ระบบมีการใช้งานมากเกินไป โปรดรอสักครู่แล้วลองใหม่ค่ะ",
          raw_prompt: prompt,
          raw_response: errorMessage
        };
      }

      throw error;
    }
  }
}

