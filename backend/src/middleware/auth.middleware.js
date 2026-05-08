import jwt from "jsonwebtoken";
import { env } from "../config/env.js";
import { ApiError } from "../utils/ApiError.js";
import { asyncHandler } from "../utils/asyncHandler.js";

export const protect = asyncHandler(async (req, res, next) => {
  const token = req.headers.authorization?.startsWith("Bearer ")
    ? req.headers.authorization.split(" ")[1]
    : undefined;

  if (!token) {
    throw new ApiError(401, "No token provided");
  }

  const decoded = jwt.verify(token, env.JWT_SECRET);
  req.userId = decoded.userId;
  req.shopId = decoded.shopId;
  next();
});
