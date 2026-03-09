"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.authMiddleware = void 0;
/**
 * Basic Auth Middleware for Facility Management System
 * Based on SRS V2.1: Only logged-in residents can access this endpoint.
 * In a real-world scenario, you'd use a JWT or Session-based authentication here.
 * For now, this is a mock to show where auth belongs.
 */
const authMiddleware = (req, res, next) => {
    const token = req.headers.authorization;
    if (!token) {
        return res.status(401).json({
            success: false,
            message: "UNAUTHORIZED: Only residents can access this feature.",
        });
    }
    // Verify JWT, check roles, etc.
    // Mock success:
    next();
};
exports.authMiddleware = authMiddleware;
