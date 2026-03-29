/**
 * FCM Model Upload Script
 * Uploads Vivorn7.8.glb to Cloudflare R2 with correct CORS/cache headers
 * Run: node upload-model.js
 */
import { S3Client, PutObjectCommand, HeadObjectCommand } from '@aws-sdk/client-s3';
import { createReadStream, statSync } from 'fs';
import { resolve } from 'path';
import dotenv from 'dotenv';

dotenv.config();

const MODEL_LOCAL_PATH = resolve('../assets/models/Vivorn7.8.glb');
const MODEL_KEY = 'Vivorn7.8.glb';

const r2 = new S3Client({
    region: 'auto',
    endpoint: `https://${process.env.CLOUDFLARE_ACCOUNT_ID}.r2.cloudflarestorage.com`,
    credentials: {
        accessKeyId: process.env.R2_ACCESS_KEY_ID,
        secretAccessKey: process.env.R2_SECRET_ACCESS_KEY,
    },
});

async function upload() {
    const stat = statSync(MODEL_LOCAL_PATH);
    const sizeMB = (stat.size / 1024 / 1024).toFixed(2);
    console.log(`[FCM] Uploading ${MODEL_KEY} (${sizeMB} MB) to R2...`);

    // Check if already exists
    try {
        await r2.send(new HeadObjectCommand({ Bucket: process.env.R2_BUCKET_NAME, Key: MODEL_KEY }));
        console.log(`[FCM] ✓ ${MODEL_KEY} already exists in R2. Skipping upload.`);
        console.log(`[FCM] Public URL: ${process.env.R2_PUBLIC_DOMAIN}/${MODEL_KEY}`);
        return;
    } catch (_) {
        // Not found, proceed with upload
    }

    const stream = createReadStream(MODEL_LOCAL_PATH);
    let uploaded = 0;
    stream.on('data', (chunk) => {
        uploaded += chunk.length;
        const percent = ((uploaded / stat.size) * 100).toFixed(1);
        process.stdout.write(`\r[FCM] Progress: ${percent}%   `);
    });

    await r2.send(new PutObjectCommand({
        Bucket: process.env.R2_BUCKET_NAME,
        Key: MODEL_KEY,
        Body: createReadStream(MODEL_LOCAL_PATH),
        ContentType: 'model/gltf-binary',
        ContentLength: stat.size,
        CacheControl: 'public, max-age=31536000, immutable', // Cache 1 year
        Metadata: {
            'uploaded-by': 'fcm-upload-script',
            'version': '7.8',
        },
    }));

    console.log(`\n[FCM] ✅ Upload complete!`);
    console.log(`[FCM] Public URL: ${process.env.R2_PUBLIC_DOMAIN}/${MODEL_KEY}`);
}

upload().catch(err => {
    console.error('[FCM] Upload failed:', err.message);
    process.exit(1);
});
