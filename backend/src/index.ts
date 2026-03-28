import express from "express";
import cors from "cors";
import morgan from "morgan";
import dotenv from "dotenv";

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(morgan("dev"));
app.use(express.json());

// Routes Registration
import authRouter from "./routes/auth.routes";
import devRouter from "./routes/dev.routes";
import repairRouter from "./routes/repair.routes";
import chatRouter from "./routes/chat.routes"; // Added Chat Router
import uploadRouter from "./routes/upload.routes"; // Added Upload Router

app.use("/api/auth", authRouter);
app.use("/api/dev", devRouter);
app.use("/api/repair", repairRouter);
app.use("/api/chat", chatRouter);
app.use("/api/upload", uploadRouter);


// Simple health check
app.get("/health", (req, res) => res.status(200).json({ status: "OK", time: new Date() }));

app.listen(PORT, () => {
    console.log(`FCM [Backend Server] is running on http://localhost:${PORT}`);
});

// Trigger backend restart
