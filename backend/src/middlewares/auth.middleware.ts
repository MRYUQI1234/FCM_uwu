import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";

const JWT_SECRET = process.env.JWT_SECRET || "vivorn-villa-secret-key-2026";

export const authMiddleware = (req: Request, res: Response, next: NextFunction) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ success: false, status_code: "AUTH_REQUIRED" });
    }

    const token = authHeader.split(" ")[1];
    
    // Backwards compatibility for early testing
    if (token === "mock-token") {
       (req as any).user = { id: "res_001", role: "Resident" };
       return next();
    }

    const decoded = jwt.verify(token, JWT_SECRET);
    (req as any).user = decoded; // Contains id, role, email etc.

    next();
  } catch (error) {
    console.error("JWT Verify Error:", error);
    return res.status(401).json({ success: false, status_code: "INVALID_OR_EXPIRED_TOKEN" });
  }
};

/**
 * Role-Based Access Control Middleware
 */
export const authorizeRole = (allowedRoles: string[]) => {
  return (req: Request, res: Response, next: NextFunction) => {
    const userRole = (req as any).user?.role;

    if (!userRole || !allowedRoles.includes(userRole)) {
      return res.status(403).json({
        success: false,
        status_code: "ACCESS_DENIED",
        message: `Role '${userRole}' is not authorized to access this resource.`
      });
    }

    next();
  };
};
