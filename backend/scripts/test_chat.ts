import axios from 'axios';

const BASE_URL = 'http://localhost:3000/api';

async function runTest() {
    console.log('--- Starting Automated AI Chat Test ---');

    try {
        console.log('[1/4] Logging in as Resident (test@resident.com)...');
        let token;
        try {
            const loginRes = await axios.post(`${BASE_URL}/auth/login`, {
                email: 'test@resident.com',
                password: 'Password1'
            });
            token = loginRes.data.token;
        } catch (e: any) {
            if (e.response?.status === 401 || e.response?.status === 404) {
                console.log('User not found. Registering...');

                // Ensure whitelist exists
                const Database = require('better-sqlite3');
                const db = new Database('./database/vivorn_villa.db');
                db.prepare('INSERT OR IGNORE INTO real_estate_records (national_id, house_number, full_name, citizen_type) VALUES (?, ?, ?, ?)').run('1100110011000', '99/999', 'Test Resident', 'Thai');
                db.close();

                await axios.post(`${BASE_URL}/auth/register`, {
                    national_id: '1100110011000',
                    email: 'test@resident.com',
                    phone: '0812345678',
                    password: 'Password1'
                });

                // Login after register
                const loginRes2 = await axios.post(`${BASE_URL}/auth/login`, {
                    email: 'test@resident.com',
                    password: 'Password1'
                });
                token = loginRes2.data.token;
            } else {
                throw e;
            }
        }

        if (!token) throw new Error('Failed to get token: ' + JSON.stringify(token));
        console.log('✅ Login successful');

        console.log('[2/4] Sending message to AI to test SQL query...');
        const msgRes = await axios.post(
            `${BASE_URL}/chat/message`,
            { content: 'Hello, I have a broken pipe.' },
            { headers: { Authorization: `Bearer ${token}` } }
        );

        if (!msgRes.data.success) throw new Error('Send message failed');
        const convoId = msgRes.data.data.conversation_id;
        console.log(`✅ Message sent successfully, no SQL errors. Conversation ID: ${convoId}`);

        console.log('[3/4] Fetching conversations...');
        const getRes = await axios.get(
            `${BASE_URL}/chat/conversations`,
            { headers: { Authorization: `Bearer ${token}` } }
        );

        const convos = getRes.data.data;
        const found = convos.find((c: any) => c.id === convoId);
        if (!found) throw new Error('New conversation not found in list');
        console.log('✅ Conversation found in list');

        console.log(`[4/4] Deleting conversation ${convoId}...`);
        const delRes = await axios.delete(
            `${BASE_URL}/chat/conversations/${convoId}`,
            { headers: { Authorization: `Bearer ${token}` } }
        );

        if (!delRes.data.success) throw new Error('Failed to delete conversation');
        console.log('✅ Conversation deleted successfully');

        console.log('🎉 All tests passed successfully!');
        process.exit(0);

    } catch (error: any) {
        console.error('❌ Test failed:');
        if (error.response) {
            console.error(error.response.data);
        } else {
            console.error(error.message);
        }
        process.exit(1);
    }
}

runTest();
