import axios from "axios";

const BASE_URL = "http://localhost:3000/api";

async function testAuthFlow() {
  console.log("--- Testing Auth Flow (Resident PIN Setup) ---");

  try {
    // 1. Login with pre-seeded resident
    console.log("Step 1: Logging in as alice_res...");
    const loginRes = await axios.post(`${BASE_URL}/auth/login`, {
      email: "alice@vivorn.com",
      password: "StronG@123"
    });

    const token = loginRes.data.token;
    console.log("Login Success! Token acquired.");

    // 2. Setup PIN
    console.log("Step 2: Setting up 6-digit PIN...");
    const pinRes = await axios.post(`${BASE_URL}/auth/setup-pin`, 
      { pin: "123456" },
      { headers: { Authorization: `Bearer ${token}` } }
    );

    console.log("PIN Success!", pinRes.data.message);

    // 3. Verify is_first_login is now false
    console.log("Step 3: Re-logging in to verify status...");
    const verifyRes = await axios.post(`${BASE_URL}/auth/login`, {
      email: "alice@vivorn.com",
      password: "StronG@123"
    });

    if (verifyRes.data.user.is_first_login === false) {
      console.log("Verification Success: is_first_login is now FALSE.");
    } else {
      console.log("Verification Failed: is_first_login is still TRUE.");
    }

  } catch (err: any) {
    console.error("Test Failed:", err.response?.data || err.message);
  }
}

testAuthFlow();
