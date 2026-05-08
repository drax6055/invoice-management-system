import * as authService from "./auth.service.js";
import { ApiResponse } from "../../utils/ApiResponse.js";
import { asyncHandler } from "../../utils/asyncHandler.js";

export const register = asyncHandler(async (req, res) => {
  const result = await authService.register(req.body);
  res.status(201).json(new ApiResponse(201, result, "Shop registered"));
});

export const login = asyncHandler(async (req, res) => {
  const result = await authService.login(req.body);
  res.json(new ApiResponse(200, result, "Login successful"));
});

export const refresh = asyncHandler(async (req, res) => {
  const result = await authService.refresh(req.body.refreshToken);
  res.json(new ApiResponse(200, result, "Token refreshed"));
});

export const logout = asyncHandler(async (req, res) => {
  await authService.logout(req.shopId, req.body.refreshToken);
  res.json(new ApiResponse(200, null, "Logged out"));
});

export const me = asyncHandler(async (req, res) => {
  const shop = await authService.getProfile(req.shopId);
  res.json(new ApiResponse(200, shop, "Shop profile fetched"));
});

export const updateShop = asyncHandler(async (req, res) => {
  const shop = await authService.updateShop(req.shopId, req.body);
  res.json(new ApiResponse(200, shop, "Shop updated"));
});
