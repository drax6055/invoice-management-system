import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import Shop from "./auth.model.js";
import { env } from "../../config/env.js";
import { ApiError } from "../../utils/ApiError.js";

const signAccessToken = (shop) =>
  jwt.sign({ userId: shop._id.toString(), shopId: shop._id.toString() }, env.JWT_SECRET, {
    expiresIn: env.JWT_EXPIRES_IN
  });

const signRefreshToken = (shop) =>
  jwt.sign({ userId: shop._id.toString(), shopId: shop._id.toString() }, env.REFRESH_TOKEN_SECRET, {
    expiresIn: env.REFRESH_TOKEN_EXPIRES_IN
  });

const issueTokens = async (shop) => {
  const accessToken = signAccessToken(shop);
  const refreshToken = signRefreshToken(shop);
  await Shop.findByIdAndUpdate(shop._id, { $addToSet: { refreshTokens: refreshToken } });
  return { accessToken, refreshToken };
};

export const register = async (payload) => {
  const existing = await Shop.findOne({ email: payload.email.toLowerCase() });
  if (existing) {
    throw new ApiError(409, "Email is already registered");
  }

  const passwordHash = await bcrypt.hash(payload.password, 12);
  const shop = await Shop.create({
    ...payload,
    email: payload.email.toLowerCase(),
    passwordHash
  });

  const tokens = await issueTokens(shop);
  return { shop: shop.toSafeJSON(), ...tokens };
};

export const login = async ({ email, password }) => {
  const shop = await Shop.findOne({ email: email.toLowerCase() });
  if (!shop) {
    throw new ApiError(401, "Invalid email or password");
  }

  const valid = await bcrypt.compare(password, shop.passwordHash);
  if (!valid) {
    throw new ApiError(401, "Invalid email or password");
  }

  const tokens = await issueTokens(shop);
  return { shop: shop.toSafeJSON(), ...tokens };
};

export const refresh = async (refreshToken) => {
  let decoded;
  try {
    decoded = jwt.verify(refreshToken, env.REFRESH_TOKEN_SECRET);
  } catch {
    throw new ApiError(401, "Invalid refresh token");
  }

  const shop = await Shop.findOne({ _id: decoded.shopId, refreshTokens: refreshToken });
  if (!shop) {
    throw new ApiError(401, "Refresh token has been revoked");
  }

  const accessToken = signAccessToken(shop);
  const newRefreshToken = signRefreshToken(shop);
  await Shop.findByIdAndUpdate(shop._id, {
    $pull: { refreshTokens: refreshToken },
    $addToSet: { refreshTokens: newRefreshToken }
  });

  return { accessToken, refreshToken: newRefreshToken };
};

export const logout = async (shopId, refreshToken) => {
  await Shop.findByIdAndUpdate(shopId, { $pull: { refreshTokens: refreshToken } });
};

export const getProfile = async (shopId) => {
  const shop = await Shop.findById(shopId);
  if (!shop) {
    throw new ApiError(404, "Shop not found");
  }
  return shop.toSafeJSON();
};

export const updateShop = async (shopId, payload) => {
  const shop = await Shop.findByIdAndUpdate(shopId, payload, { new: true, runValidators: true });
  if (!shop) {
    throw new ApiError(404, "Shop not found");
  }
  return shop.toSafeJSON();
};
