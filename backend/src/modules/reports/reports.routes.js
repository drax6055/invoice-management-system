import { Router } from "express";
import * as controller from "./reports.controller.js";
import { protect } from "../../middleware/auth.middleware.js";

const router = Router();

router.use(protect);
router.get("/sales/daily", controller.dailySales);
router.get("/sales/range", controller.rangeSales);
router.get("/sales/hourly", controller.hourlySales);
router.get("/products", controller.productSales);
router.get("/categories", controller.categorySales);
router.get("/inventory", controller.inventory);
router.get("/low-stock", controller.lowStock);
router.get("/profit", controller.profit);
router.get("/tax", controller.tax);
router.get("/payment-modes", controller.paymentModes);
router.get("/customers/top", controller.topCustomers);
router.get("/customers/credit", controller.creditCustomers);
router.get("/discounts", controller.discounts);
router.get("/void-orders", controller.voidOrders);

export default router;
