import * as service from "./reports.service.js";
import { ApiResponse } from "../../utils/ApiResponse.js";
import { asyncHandler } from "../../utils/asyncHandler.js";

const send = (handler, message) =>
  asyncHandler(async (req, res) => {
    res.json(new ApiResponse(200, await handler(req.shopId, req.query), message));
  });

export const dailySales = asyncHandler(async (req, res) => {
  res.json(new ApiResponse(200, await service.dailySales(req.shopId, req.query.date), "Daily sales report fetched"));
});

export const rangeSales = send(service.rangeSales, "Range sales report fetched");
export const hourlySales = asyncHandler(async (req, res) => {
  res.json(new ApiResponse(200, await service.hourlySales(req.shopId, req.query.date), "Hourly sales report fetched"));
});
export const productSales = send(service.productSales, "Product sales report fetched");
export const categorySales = send(service.categorySales, "Category sales report fetched");
export const inventory = asyncHandler(async (req, res) => {
  res.json(new ApiResponse(200, await service.inventory(req.shopId), "Inventory report fetched"));
});
export const lowStock = asyncHandler(async (req, res) => {
  res.json(new ApiResponse(200, await service.lowStock(req.shopId), "Low stock report fetched"));
});
export const profit = send(service.profit, "Profit report fetched");
export const tax = send(service.tax, "Tax report fetched");
export const paymentModes = send(service.paymentModes, "Payment mode report fetched");
export const topCustomers = send(service.topCustomers, "Top customers report fetched");
export const creditCustomers = asyncHandler(async (req, res) => {
  res.json(new ApiResponse(200, await service.creditCustomers(req.shopId), "Credit customers report fetched"));
});
export const discounts = send(service.discounts, "Discount report fetched");
export const voidOrders = send(service.voidOrders, "Void orders report fetched");
