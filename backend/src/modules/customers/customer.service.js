import Customer from "./customer.model.js";
import Order from "../orders/order.model.js";
import { ApiError } from "../../utils/ApiError.js";
import { getPagination, paginatedResult } from "../../utils/pagination.js";

export const list = async (shopId, query) => {
  const { page, limit, skip } = getPagination(query);
  const filter = { shopId };
  if (query.search) filter.$or = [{ name: new RegExp(query.search, "i") }, { phone: new RegExp(query.search, "i") }];

  return paginatedResult(
    Customer.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
    Customer.countDocuments(filter),
    { page, limit }
  );
};

export const create = (shopId, payload) => Customer.create({ ...payload, shopId });

export const detail = async (shopId, id) => {
  const customer = await Customer.findOne({ _id: id, shopId });
  if (!customer) throw new ApiError(404, "Customer not found");
  const orders = await Order.find({ shopId, customerId: id }).sort({ createdAt: -1 }).limit(25);
  return { customer, orders };
};

export const update = async (shopId, id, payload) => {
  const customer = await Customer.findOneAndUpdate({ _id: id, shopId }, payload, { new: true, runValidators: true });
  if (!customer) throw new ApiError(404, "Customer not found");
  return customer;
};

export const recordCreditPayment = async (shopId, id, amount) => {
  const customer = await Customer.findOneAndUpdate(
    { _id: id, shopId },
    { $inc: { outstandingCredit: -amount } },
    { new: true, runValidators: true }
  );
  if (!customer) throw new ApiError(404, "Customer not found");
  if (customer.outstandingCredit < 0) {
    customer.outstandingCredit = 0;
    await customer.save();
  }
  return customer;
};
