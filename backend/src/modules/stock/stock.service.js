import Product from "../products/product.model.js";
import StockMovement from "./stockMovement.model.js";
import { ApiError } from "../../utils/ApiError.js";
import { getPagination, paginatedResult } from "../../utils/pagination.js";

export const adjust = async (shopId, { productId, qtyChange, reason }) => {
  const product = await Product.findOne({ _id: productId, shopId, isArchived: false });
  if (!product) throw new ApiError(404, "Product not found");

  const qtyBefore = product.qty;
  const qtyAfter = qtyBefore + qtyChange;
  if (qtyAfter < 0) throw new ApiError(400, "Stock adjustment would make quantity negative");

  product.qty = qtyAfter;
  await product.save();

  const movement = await StockMovement.create({
    shopId,
    productId,
    productName: product.name,
    type: qtyChange > 0 ? "stock_in" : "stock_out",
    qtyChange,
    qtyBefore,
    qtyAfter,
    reason
  });

  return { product, movement };
};

export const movements = async (shopId, query) => {
  const { page, limit, skip } = getPagination(query);
  const filter = { shopId };
  if (query.productId) filter.productId = query.productId;

  return paginatedResult(
    StockMovement.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
    StockMovement.countDocuments(filter),
    { page, limit }
  );
};

export const lowStock = (shopId) =>
  Product.find({
    shopId,
    isArchived: false,
    $expr: { $lte: ["$qty", "$lowStockThreshold"] }
  }).sort({ qty: 1 });
