import { Router } from "express";
import * as controller from "./customer.controller.js";
import { protect } from "../../middleware/auth.middleware.js";
import { validate } from "../../middleware/validate.middleware.js";
import { createCustomerSchema, creditPaymentSchema, updateCustomerSchema } from "./customer.schema.js";

const router = Router();

router.use(protect);
router.get("/", controller.list);
router.post("/", validate(createCustomerSchema), controller.create);
router.get("/:id", controller.detail);
router.patch("/:id", validate(updateCustomerSchema), controller.update);
router.patch("/:id/credit", validate(creditPaymentSchema), controller.recordCreditPayment);

export default router;
