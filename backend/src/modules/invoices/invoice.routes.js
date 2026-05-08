import { Router } from "express";
import * as controller from "./invoice.controller.js";
import { protect } from "../../middleware/auth.middleware.js";

const router = Router();

router.use(protect);
router.get("/", controller.list);
router.get("/:id", controller.detail);

export default router;
