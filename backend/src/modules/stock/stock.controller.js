import * as service from "./stock.service.js";
import { ApiResponse } from "../../utils/ApiResponse.js";
import { asyncHandler } from "../../utils/asyncHandler.js";

export const adjust = asyncHandler(async (req, res) => {
  res.status(201).json(new ApiResponse(201, await service.adjust(req.shopId, req.body), "Stock adjusted"));
});

export const movements = asyncHandler(async (req, res) => {
  res.json(new ApiResponse(200, await service.movements(req.shopId, req.query), "Stock movements fetched"));
});

export const lowStock = asyncHandler(async (req, res) => {
  res.json(new ApiResponse(200, await service.lowStock(req.shopId), "Low stock products fetched"));
});
