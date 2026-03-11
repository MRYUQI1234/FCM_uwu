import { Router } from "express";
import { DevController } from "../controllers/dev.controller";

const devRouter = Router();

// Dev DB Bridge: Only for Development Use
devRouter.post("/query", DevController.query);
devRouter.get("/tables", DevController.getTables);

export default devRouter;
