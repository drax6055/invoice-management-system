import { Router } from "express";
import * as controller from "./order.controller.js";
import { protect } from "../../middleware/auth.middleware.js";
import { validate } from "../../middleware/validate.middleware.js";
import { checkoutSchema, voidOrderSchema } from "./order.schema.js";

const router = Router();

router.use(protect);
router.post("/checkout", validate(checkoutSchema), controller.checkout);
router.get("/", controller.list);
router.get("/:id", controller.detail);
router.patch("/:id/void", validate(voidOrderSchema), controller.voidOrder);

export default router;
