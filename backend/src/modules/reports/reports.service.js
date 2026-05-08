import mongoose from "mongoose";
import Order from "../orders/order.model.js";
import Product from "../products/product.model.js";
import Customer from "../customers/customer.model.js";
import { dayRange, queryDateRange } from "../../utils/dateHelpers.js";

const oid = (value) => new mongoose.Types.ObjectId(value);
const completedMatch = (shopId, start, end) => ({
  shopId: oid(shopId),
  status: "completed",
  createdAt: { $gte: start, $lte: end }
});

const emptySales = {
  totalRevenue: 0,
  totalOrders: 0,
  totalTax: 0,
  totalDiscount: 0,
  avgOrderValue: 0
};

export const dailySales = async (shopId, date) => {
  const { start, end } = dayRange(date);
  const result = await Order.aggregate([
    { $match: completedMatch(shopId, start, end) },
    {
      $group: {
        _id: null,
        totalRevenue: { $sum: "$grandTotal" },
        totalOrders: { $sum: 1 },
        totalTax: { $sum: "$taxAmount" },
        totalDiscount: { $sum: "$discountTotal" },
        avgOrderValue: { $avg: "$grandTotal" }
      }
    },
    { $project: { _id: 0 } }
  ]);

  return result[0] ?? emptySales;
};

export const rangeSales = async (shopId, query) => {
  const { start, end } = queryDateRange(query);
  const result = await Order.aggregate([
    { $match: completedMatch(shopId, start, end) },
    {
      $group: {
        _id: { $dateToString: { date: "$createdAt", format: "%Y-%m-%d" } },
        totalRevenue: { $sum: "$grandTotal" },
        totalOrders: { $sum: 1 },
        totalTax: { $sum: "$taxAmount" },
        totalDiscount: { $sum: "$discountTotal" }
      }
    },
    { $sort: { _id: 1 } }
  ]);
  return result;
};

export const hourlySales = async (shopId, date) => {
  const { start, end } = dayRange(date);
  return Order.aggregate([
    { $match: completedMatch(shopId, start, end) },
    {
      $group: {
        _id: { $hour: "$createdAt" },
        totalRevenue: { $sum: "$grandTotal" },
        totalOrders: { $sum: 1 }
      }
    },
    { $sort: { _id: 1 } }
  ]);
};

export const productSales = async (shopId, query) => {
  const { start, end } = queryDateRange(query);
  return Order.aggregate([
    { $match: completedMatch(shopId, start, end) },
    { $unwind: "$items" },
    {
      $group: {
        _id: "$items.productId",
        productName: { $first: "$items.productName" },
        unitsSold: { $sum: "$items.qty" },
        revenue: { $sum: "$items.total" },
        profit: { $sum: { $multiply: [{ $subtract: ["$items.unitPrice", "$items.costPrice"] }, "$items.qty"] } }
      }
    },
    { $sort: { revenue: -1 } }
  ]);
};

export const categorySales = async (shopId, query) => {
  const { start, end } = queryDateRange(query);
  return Order.aggregate([
    { $match: completedMatch(shopId, start, end) },
    { $unwind: "$items" },
    {
      $lookup: {
        from: "products",
        localField: "items.productId",
        foreignField: "_id",
        as: "product"
      }
    },
    { $unwind: "$product" },
    {
      $lookup: {
        from: "categories",
        localField: "product.categoryId",
        foreignField: "_id",
        as: "category"
      }
    },
    { $unwind: { path: "$category", preserveNullAndEmptyArrays: true } },
    {
      $group: {
        _id: "$product.categoryId",
        categoryName: { $first: { $ifNull: ["$category.name", "Uncategorized"] } },
        unitsSold: { $sum: "$items.qty" },
        revenue: { $sum: "$items.total" }
      }
    },
    { $sort: { revenue: -1 } }
  ]);
};

export const inventory = async (shopId) =>
  Product.aggregate([
    { $match: { shopId: oid(shopId), isArchived: false } },
    {
      $project: {
        name: 1,
        sku: 1,
        qty: 1,
        price: 1,
        costPrice: 1,
        lowStockThreshold: 1,
        stockValueAtCost: { $multiply: ["$qty", "$costPrice"] },
        stockValueAtSale: { $multiply: ["$qty", "$price"] }
      }
    },
    { $sort: { name: 1 } }
  ]);

export const lowStock = (shopId) =>
  Product.find({ shopId, isArchived: false, $expr: { $lte: ["$qty", "$lowStockThreshold"] } }).sort({ qty: 1 });

export const profit = async (shopId, query) => {
  const rows = await productSales(shopId, query);
  return {
    grossProfit: rows.reduce((sum, row) => sum + row.profit, 0),
    products: rows
  };
};

export const tax = async (shopId, query) => {
  const { start, end } = queryDateRange(query);
  const result = await Order.aggregate([
    { $match: completedMatch(shopId, start, end) },
    { $group: { _id: "$taxRate", taxableSales: { $sum: { $subtract: ["$subtotal", "$discountTotal"] } }, tax: { $sum: "$taxAmount" } } },
    { $sort: { _id: 1 } }
  ]);
  return result;
};

export const paymentModes = async (shopId, query) => {
  const { start, end } = queryDateRange(query);
  return Order.aggregate([
    { $match: completedMatch(shopId, start, end) },
    { $group: { _id: "$paymentMode", totalRevenue: { $sum: "$grandTotal" }, totalOrders: { $sum: 1 } } },
    { $sort: { totalRevenue: -1 } }
  ]);
};

export const topCustomers = async (shopId, query) => {
  const { start, end } = queryDateRange(query);
  const limit = Math.min(Number(query.limit) || 10, 50);
  return Order.aggregate([
    { $match: { ...completedMatch(shopId, start, end), customerId: { $ne: null } } },
    {
      $group: {
        _id: "$customerId",
        customerName: { $first: "$customerName" },
        customerPhone: { $first: "$customerPhone" },
        totalSpend: { $sum: "$grandTotal" },
        orderCount: { $sum: 1 }
      }
    },
    { $sort: { totalSpend: -1 } },
    { $limit: limit }
  ]);
};

export const creditCustomers = (shopId) => Customer.find({ shopId, outstandingCredit: { $gt: 0 } }).sort({ outstandingCredit: -1 });

export const discounts = async (shopId, query) => {
  const { start, end } = queryDateRange(query);
  const result = await Order.aggregate([
    { $match: completedMatch(shopId, start, end) },
    {
      $project: {
        discountTotal: 1,
        itemDiscountTotal: { $sum: "$items.discount" }
      }
    },
    {
      $group: {
        _id: null,
        orderDiscounts: { $sum: "$discountTotal" },
        itemDiscounts: { $sum: "$itemDiscountTotal" },
        ordersWithDiscount: { $sum: { $cond: [{ $gt: ["$discountTotal", 0] }, 1, 0] } }
      }
    },
    { $project: { _id: 0 } }
  ]);
  return result[0] ?? { orderDiscounts: 0, itemDiscounts: 0, ordersWithDiscount: 0 };
};

export const voidOrders = async (shopId, query) => {
  const { start, end } = queryDateRange(query);
  return Order.find({ shopId, status: "void", createdAt: { $gte: start, $lte: end } }).sort({ createdAt: -1 });
};
