import { Router } from "express";
import { AuthController } from "../controllers/auth.controller";
import { authMiddleware } from "../middlewares/auth.middleware";

const authRouter = Router();

authRouter.post("/register", AuthController.register);
authRouter.post("/login", AuthController.login);

// Setup PIN requires user to be logged in and possessing a valid JWT token
authRouter.post("/setup-pin", authMiddleware, AuthController.setupPin);
authRouter.get("/profile", authMiddleware, AuthController.getProfile);
authRouter.patch("/profile", authMiddleware, AuthController.updateProfile);

export default authRouter;
