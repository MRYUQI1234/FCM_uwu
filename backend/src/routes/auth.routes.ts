import { Router } from "express";
import { AuthController } from "../controllers/auth.controller";
import { authMiddleware, authorizeRole } from "../middlewares/auth.middleware";

const authRouter = Router();

authRouter.post("/register", AuthController.register);
authRouter.post("/login", AuthController.login);
authRouter.post("/forgot-password", AuthController.forgotPassword);
authRouter.get("/reset-password", AuthController.redirectReset); // URL REDIRECT FROM EMAIL
authRouter.post("/reset-password", AuthController.resetPassword);

// Setup PIN requires user to be logged in and possessing a valid JWT token
authRouter.post("/setup-pin", authMiddleware, AuthController.setupPin);
authRouter.post("/verify-pin", authMiddleware, AuthController.verifyPin);
authRouter.get("/profile", authMiddleware, AuthController.getProfile);
authRouter.patch("/profile", authMiddleware, AuthController.updateProfile);
authRouter.get("/personnel", authMiddleware, AuthController.getPersonnel);

// FE-05: Personnel Management (Juristic Only)
authRouter.post("/register-staff", authMiddleware, authorizeRole(["JURISTIC"]), AuthController.registerStaff);
authRouter.put("/personnel/:nationalId", authMiddleware, authorizeRole(["JURISTIC"]), AuthController.updatePersonnel);
authRouter.delete("/personnel/:nationalId", authMiddleware, authorizeRole(["JURISTIC"]), AuthController.deletePersonnel);

export default authRouter;
