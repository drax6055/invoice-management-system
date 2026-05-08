import { Router } from "express";
import * as controller from "./product.controller.js";
import { protect } from "../../middleware/auth.middleware.js";
import { validate } from "../../middleware/validate.middleware.js";
import { bulkImportSchema, createProductSchema, updateProductSchema } from "./product.schema.js";

const router = Router();

router.use(protect);
router.get("/", controller.list);
router.post("/", validate(createProductSchema), controller.create);
router.get("/barcode/:code", controller.getByBarcode);
router.post("/bulk-import", validate(bulkImportSchema), controller.bulkImport);
router.get("/:id", controller.getById);
router.patch("/:id", validate(updateProductSchema), controller.update);
router.delete("/:id", controller.archive);

export default router;
