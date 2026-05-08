import Invoice from "./invoice.model.js";
import { ApiError } from "../../utils/ApiError.js";
import { getPagination, paginatedResult } from "../../utils/pagination.js";

export const list = async (shopId, query) => {
  const { page, limit, skip } = getPagination(query);
  const filter = { shopId };
  if (query.search) filter.invoiceNumber = new RegExp(query.search, "i");
  if (query.from || query.to) {
    filter.createdAt = {};
    if (query.from) filter.createdAt.$gte = new Date(query.from);
    if (query.to) filter.createdAt.$lte = new Date(query.to);
  }

  return paginatedResult(
    Invoice.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
    Invoice.countDocuments(filter),
    { page, limit }
  );
};

export const detail = async (shopId, id) => {
  const invoice = await Invoice.findOne({ _id: id, shopId }).populate("orderId");
  if (!invoice) throw new ApiError(404, "Invoice not found");
  return invoice;
};
