import Product from "./product.model.js";
import { ApiError } from "../../utils/ApiError.js";
import { getPagination, paginatedResult } from "../../utils/pagination.js";

const baseFilter = (shopId) => ({ shopId, isArchived: false });

export const list = async (shopId, query) => {
  const { page, limit, skip } = getPagination(query);
  const filter = baseFilter(shopId);

  if (query.categoryId) filter.categoryId = query.categoryId;
  if (query.search) {
    filter.$or = [
      { name: new RegExp(query.search, "i") },
      { sku: new RegExp(query.search, "i") },
      { barcode: new RegExp(query.search, "i") }
    ];
  }

  return paginatedResult(
    Product.find(filter).populate("categoryId", "name").sort({ createdAt: -1 }).skip(skip).limit(limit),
    Product.countDocuments(filter),
    { page, limit }
  );
};

export const create = (shopId, payload) => Product.create({ ...payload, shopId });

export const getById = async (shopId, id) => {
  const product = await Product.findOne({ _id: id, ...baseFilter(shopId) }).populate("categoryId", "name");
  if (!product) throw new ApiError(404, "Product not found");
  return product;
};

export const update = async (shopId, id, payload) => {
  const product = await Product.findOneAndUpdate({ _id: id, shopId }, payload, { new: true, runValidators: true });
  if (!product || product.isArchived) throw new ApiError(404, "Product not found");
  return product;
};

export const archive = async (shopId, id) => {
  const product = await Product.findOneAndUpdate({ _id: id, shopId }, { isArchived: true }, { new: true });
  if (!product) throw new ApiError(404, "Product not found");
  return product;
};

export const getByBarcode = async (shopId, barcode) => {
  const product = await Product.findOne({ ...baseFilter(shopId), barcode });
  if (!product) throw new ApiError(404, "Product not found for barcode");
  return product;
};

export const bulkImport = async (shopId, products) => {
  const docs = products.map((product) => ({ ...product, shopId }));
  return Product.insertMany(docs, { ordered: false });
};
