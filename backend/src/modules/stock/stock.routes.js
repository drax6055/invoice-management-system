import { Router } from "express";
import * as controller from "./stock.controller.js";
import { protect } from "../../middleware/auth.middleware.js";
import { validate } from "../../middleware/validate.middleware.js";
import { adjustStockSchema } from "./stock.schema.js";

const router = Router();

router.use(protect);
router.post("/adjust", validate(adjustStockSchema), controller.adjust);
router.get("/movements", controller.movements);
router.get("/low", controller.lowStock);

export default router;
