import Category from "./category.model.js";
import Product from "../products/product.model.js";
import { ApiError } from "../../utils/ApiError.js";

export const list = (shopId) => Category.find({ shopId }).sort({ name: 1 });

export const create = (shopId, payload) => Category.create({ ...payload, shopId });

export const update = async (shopId, id, payload) => {
  const category = await Category.findOneAndUpdate({ _id: id, shopId }, payload, { new: true, runValidators: true });
  if (!category) throw new ApiError(404, "Category not found");
  return category;
};

export const remove = async (shopId, id) => {
  const inUse = await Product.exists({ shopId, categoryId: id, isArchived: false });
  if (inUse) throw new ApiError(400, "Category is used by active products");

  const category = await Category.findOneAndDelete({ _id: id, shopId });
  if (!category) throw new ApiError(404, "Category not found");
};
