import axios from "axios";

const BASE_URL = "http://localhost:3000/api";

async function testPersonnelFlow() {
  console.log("--- Testing Personnel Management Flow (SysT-4) ---");

  try {
    // 1. Login as Existing Jurisdictic Admin (Jane)
    console.log("Step 1: Logging in as Admin (Jurisdictic)...");
    const adminLogin = await axios.post(`${BASE_URL}/auth/login`, {
      email: "admin@vivorn.com",
      password: "AdminP@ss123"
    });
    const adminToken = adminLogin.data.token;
    console.log("Admin Token acquired.");

    // 2. Add New Personnel (Pongsak)
    console.log("Step 2: Adding New Personnel 'Pongsak'...");
    const pongsakData = {
      national_id: "1111111111111",
      full_name: "Pongsak Sansook",
      phone: "0810001234",
      email: "pongsak@vivorn.com",
      role: "Jurisdictic",
      face_image_url: "https://example.com/pongsak_face.jpg"
    };

    const addPersonnelRes = await axios.post(`${BASE_URL}/personnel`, pongsakData, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });

    console.log("Add Personnel Success! Status Code:", addPersonnelRes.data.status_code);

    // 3. Try Login as Pongsak using National ID as Password
    console.log("Step 3: Logging in as Pongsak (Initial Login)...");
    const pongsakLogin = await axios.post(`${BASE_URL}/auth/login`, {
      email: pongsakData.email,
      password: pongsakData.national_id
    });

    console.log("Pongsak Login Success!");
    console.log("Resulting Status Code:", pongsakLogin.data.status_code);
    console.log("Expected: REQUIRE_PIN_SETUP");

    if (pongsakLogin.data.status_code === "REQUIRE_PIN_SETUP") {
      console.log(">>> SYST-4 VERIFIED: Personnel flows correctly to PIN setup on first login.");
    } else {
      console.log(">>> SYST-4 FAILED: Unexpected status code.");
    }

  } catch (err: any) {
    console.error("SysT-4 Test Failed:", err.response?.data || err.message);
  }
}

testPersonnelFlow();
