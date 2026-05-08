import * as service from "./product.service.js";
import { ApiResponse } from "../../utils/ApiResponse.js";
import { asyncHandler } from "../../utils/asyncHandler.js";

export const list = asyncHandler(async (req, res) => {
  res.json(new ApiResponse(200, await service.list(req.shopId, req.query), "Products fetched"));
});

export const create = asyncHandler(async (req, res) => {
  res.status(201).json(new ApiResponse(201, await service.create(req.shopId, req.body), "Product created"));
});

export const getById = asyncHandler(async (req, res) => {
  res.json(new ApiResponse(200, await service.getById(req.shopId, req.params.id), "Product fetched"));
});

export const update = asyncHandler(async (req, res) => {
  res.json(new ApiResponse(200, await service.update(req.shopId, req.params.id, req.body), "Product updated"));
});

export const archive = asyncHandler(async (req, res) => {
  res.json(new ApiResponse(200, await service.archive(req.shopId, req.params.id), "Product archived"));
});

export const getByBarcode = asyncHandler(async (req, res) => {
  res.json(new ApiResponse(200, await service.getByBarcode(req.shopId, req.params.code), "Product fetched"));
});

export const bulkImport = asyncHandler(async (req, res) => {
  const products = await service.bulkImport(req.shopId, req.body.products);
  res.status(201).json(new ApiResponse(201, products, "Products imported"));
});
