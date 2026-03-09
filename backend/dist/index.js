"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const morgan_1 = __importDefault(require("morgan"));
const dotenv_1 = __importDefault(require("dotenv"));
const repair_controller_1 = require("./controllers/repair.controller");
const auth_middleware_1 = require("./middlewares/auth.middleware");
dotenv_1.default.config();
const app = (0, express_1.default)();
const PORT = process.env.PORT || 3000;
// Middleware
app.use((0, cors_1.default)());
app.use((0, morgan_1.default)("dev"));
app.use(express_1.default.json());
// Routes (FCM - Facility Management System Endpoint)
app.post("/api/repair/intent", auth_middleware_1.authMiddleware, repair_controller_1.RepairController.processIntent);
// Simple health check
app.get("/health", (req, res) => res.status(200).json({ status: "OK", time: new Date() }));
app.listen(PORT, () => {
    console.log(`FCM [Backend Server] is running on http://localhost:${PORT}`);
});
