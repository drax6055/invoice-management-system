import * as service from "./category.service.js";
import { ApiResponse } from "../../utils/ApiResponse.js";
import { asyncHandler } from "../../utils/asyncHandler.js";

export const list = asyncHandler(async (req, res) => {
  res.json(new ApiResponse(200, await service.list(req.shopId), "Categories fetched"));
});

export const create = asyncHandler(async (req, res) => {
  res.status(201).json(new ApiResponse(201, await service.create(req.shopId, req.body), "Category created"));
});

export const update = asyncHandler(async (req, res) => {
  res.json(new ApiResponse(200, await service.update(req.shopId, req.params.id, req.body), "Category updated"));
});

export const remove = asyncHandler(async (req, res) => {
  await service.remove(req.shopId, req.params.id);
  res.json(new ApiResponse(200, null, "Category deleted"));
});
