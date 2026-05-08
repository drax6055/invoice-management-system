import { Router } from "express";
import { z } from "zod";
import * as controller from "./category.controller.js";
import { protect } from "../../middleware/auth.middleware.js";
import { validate } from "../../middleware/validate.middleware.js";

const router = Router();
const bodySchema = z.object({ body: z.object({ name: z.string().min(1) }) });

router.use(protect);
router.get("/", controller.list);
router.post("/", validate(bodySchema), controller.create);
router.patch("/:id", validate(bodySchema), controller.update);
router.delete("/:id", controller.remove);

export default router;
