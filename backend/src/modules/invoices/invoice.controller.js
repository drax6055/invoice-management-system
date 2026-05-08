import * as service from "./invoice.service.js";
import { ApiResponse } from "../../utils/ApiResponse.js";
import { asyncHandler } from "../../utils/asyncHandler.js";

export const list = asyncHandler(async (req, res) => {
  res.json(new ApiResponse(200, await service.list(req.shopId, req.query), "Invoices fetched"));
});

export const detail = asyncHandler(async (req, res) => {
  res.json(new ApiResponse(200, await service.detail(req.shopId, req.params.id), "Invoice fetched"));
});
