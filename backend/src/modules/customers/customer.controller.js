import * as service from "./customer.service.js";
import { ApiResponse } from "../../utils/ApiResponse.js";
import { asyncHandler } from "../../utils/asyncHandler.js";

export const list = asyncHandler(async (req, res) => {
  res.json(new ApiResponse(200, await service.list(req.shopId, req.query), "Customers fetched"));
});

export const create = asyncHandler(async (req, res) => {
  res.status(201).json(new ApiResponse(201, await service.create(req.shopId, req.body), "Customer created"));
});

export const detail = asyncHandler(async (req, res) => {
  res.json(new ApiResponse(200, await service.detail(req.shopId, req.params.id), "Customer fetched"));
});

export const update = asyncHandler(async (req, res) => {
  res.json(new ApiResponse(200, await service.update(req.shopId, req.params.id, req.body), "Customer updated"));
});

export const recordCreditPayment = asyncHandler(async (req, res) => {
  res.json(
    new ApiResponse(
      200,
      await service.recordCreditPayment(req.shopId, req.params.id, req.body.amount),
      "Credit payment recorded"
    )
  );
});
