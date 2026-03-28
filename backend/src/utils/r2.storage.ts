import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import dotenv from "dotenv";

dotenv.config();

/**
 * Configure R2 Client using AWS SDK v3
 */
const r2Client = new S3Client({
  region: "auto",
  endpoint: `https://${process.env.CLOUDFLARE_ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: process.env.R2_ACCESS_KEY_ID!,
    secretAccessKey: process.env.R2_SECRET_ACCESS_KEY!,
  },
});

export const uploadToR2 = async (
  fileBuffer: Buffer,
  fileName: string,
  contentType: string,
  folder: string = "profiles"
): Promise<string> => {
  const bucketName = process.env.R2_BUCKET_NAME!;
  
  // Sanitize fileName: Extract extension and use timestamp to avoid character encoding issues in URLs
  const extension = fileName.split('.').pop() || 'jpg';
  const sanitizedKey = `${folder}/${Date.now()}.${extension}`;
  
  const uploadParams = {
    Bucket: bucketName,
    Key: sanitizedKey,
    Body: fileBuffer,
    ContentType: contentType,
  };

  try {
    await r2Client.send(new PutObjectCommand(uploadParams));
    
    // Construct the public URL using the R2_PUBLIC_DOMAIN from .env
    const publicDomain = process.env.R2_PUBLIC_DOMAIN || "https://r2.vivorn.com";
    return `${publicDomain}/${uploadParams.Key}`;
  } catch (error) {
    console.error("R2 Upload Error:", error);
    throw new Error("Failed to upload image to R2");
  }
};
