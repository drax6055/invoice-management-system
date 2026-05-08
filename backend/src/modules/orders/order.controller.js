import * as service from "./order.service.js";
import { ApiResponse } from "../../utils/ApiResponse.js";
import { asyncHandler } from "../../utils/asyncHandler.js";

export const checkout = asyncHandler(async (req, res) => {
  res.status(201).json(new ApiResponse(201, await service.checkout(req.shopId, req.body), "Checkout complete"));
});

export const list = asyncHandler(async (req, res) => {
  res.json(new ApiResponse(200, await service.list(req.shopId, req.query), "Orders fetched"));
});

export const detail = asyncHandler(async (req, res) => {
  res.json(new ApiResponse(200, await service.detail(req.shopId, req.params.id), "Order fetched"));
});

export const voidOrder = asyncHandler(async (req, res) => {
  res.json(new ApiResponse(200, await service.voidOrder(req.shopId, req.params.id, req.body.reason), "Order voided"));
});
