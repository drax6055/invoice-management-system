import { Router } from "express";
import * as controller from "./auth.controller.js";
import { protect } from "../../middleware/auth.middleware.js";
import { validate } from "../../middleware/validate.middleware.js";
import { loginSchema, logoutSchema, refreshSchema, registerSchema, updateShopSchema } from "./auth.schema.js";

const router = Router();

router.post("/register", validate(registerSchema), controller.register);
router.post("/login", validate(loginSchema), controller.login);
router.post("/refresh", validate(refreshSchema), controller.refresh);
router.post("/logout", protect, validate(logoutSchema), controller.logout);
router.get("/me", protect, controller.me);
router.patch("/shop", protect, validate(updateShopSchema), controller.updateShop);

export default router;
