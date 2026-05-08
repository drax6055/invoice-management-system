import mongoose from "mongoose";
import Order from "./order.model.js";
import Product from "../products/product.model.js";
import Invoice from "../invoices/invoice.model.js";
import Shop from "../auth/auth.model.js";
import Customer from "../customers/customer.model.js";
import StockMovement from "../stock/stockMovement.model.js";
import { ApiError } from "../../utils/ApiError.js";
import { generateInvoiceNumber } from "../../utils/invoiceNumber.js";
import { getPagination, paginatedResult } from "../../utils/pagination.js";

const withSession = (query, session) => (session ? query.session(session) : query);
const createOptions = (session) => (session ? { session } : {});
const isTransactionUnsupported = (error) =>
  error?.code === 20 ||
  /Transaction numbers are only allowed|replica set member|not supported.*transaction/i.test(error?.message || "");

const buildCustomer = async (shopId, payload, session) => {
  if (payload.customerId) {
    const customer = await withSession(Customer.findOne({ _id: payload.customerId, shopId }), session);
    if (!customer) throw new ApiError(404, "Customer not found");
    return customer;
  }

  if (!payload.customer) return null;

  return Customer.findOneAndUpdate(
    { shopId, phone: payload.customer.phone },
    { $setOnInsert: { ...payload.customer, shopId } },
    { new: true, upsert: true, ...createOptions(session) }
  );
};

const calculateItems = (cartItems, products) =>
  cartItems.map((cartItem) => {
    const product = products.find((item) => item._id.equals(cartItem.productId));
    if (!product) throw new ApiError(400, "Product in cart was not found");
    if (product.qty < cartItem.qty) throw new ApiError(400, `Insufficient stock: ${product.name}`);

    const itemDiscount = Math.min(cartItem.discount || 0, product.price);
    const total = (product.price - itemDiscount) * cartItem.qty;
    return {
      productId: product._id,
      productName: product.name,
      barcode: product.barcode,
      qty: cartItem.qty,
      unitPrice: product.price,
      costPrice: product.costPrice,
      discount: itemDiscount,
      total
    };
  });

const checkoutWithOptionalSession = async (shopId, payload, session = null) => {
  const shop = await withSession(Shop.findById(shopId), session);
  if (!shop) throw new ApiError(404, "Shop not found");

  const productIds = payload.cartItems.map((item) => item.productId);
  const products = await withSession(Product.find({ _id: { $in: productIds }, shopId, isArchived: false }), session);
  const items = calculateItems(payload.cartItems, products);

  for (const item of items) {
    const product = products.find((entry) => entry._id.equals(item.productId));
    const qtyBefore = product.qty;
    const qtyAfter = qtyBefore - item.qty;

    const update = await Product.updateOne(
      { _id: item.productId, shopId, qty: { $gte: item.qty }, isArchived: false },
      { $inc: { qty: -item.qty } },
      createOptions(session)
    );
    if (update.modifiedCount !== 1) {
      throw new ApiError(400, `Insufficient stock: ${item.productName}`);
    }

    await StockMovement.create(
      [
        {
          shopId,
          productId: item.productId,
          productName: item.productName,
          type: "sale",
          qtyChange: -item.qty,
          qtyBefore,
          qtyAfter,
          reason: "Checkout sale"
        }
      ],
      createOptions(session)
    );
  }

  const customer = await buildCustomer(shopId, payload, session);
  const subtotal = items.reduce((sum, item) => sum + item.total, 0);
  const discountTotal = Math.min(payload.discountTotal || 0, subtotal);
  const taxRate = payload.taxRate ?? shop.taxRate;
  const taxable = subtotal - discountTotal;
  const taxAmount = Number(((taxable * taxRate) / 100).toFixed(2));
  const grandTotal = Number((taxable + taxAmount).toFixed(2));
  const invoiceNumber = await generateInvoiceNumber(shopId, session);

  const [order] = await Order.create(
    [
      {
        shopId,
        invoiceNumber,
        customerId: customer?._id,
        customerName: customer?.name || "",
        customerPhone: customer?.phone || "",
        items,
        subtotal,
        discountTotal,
        taxRate,
        taxAmount,
        grandTotal,
        paymentMode: payload.paymentMode
      }
    ],
    createOptions(session)
  );

  const [invoice] = await Invoice.create(
    [
      {
        shopId,
        orderId: order._id,
        invoiceNumber,
        shopSnapshot: {
          name: shop.shopName,
          address: shop.shopAddress,
          phone: shop.phone,
          taxLabel: shop.taxLabel,
          logoUrl: shop.logoUrl
        },
        customerSnapshot: customer
          ? { name: customer.name, phone: customer.phone, email: customer.email }
          : undefined,
        items,
        subtotal,
        discountTotal,
        taxRate,
        taxAmount,
        grandTotal,
        paymentMode: payload.paymentMode
      }
    ],
    createOptions(session)
  );

  order.invoiceId = invoice._id;
  await order.save(createOptions(session));

  if (payload.paymentMode === "credit" && customer) {
    await Customer.updateOne(
      { _id: customer._id, shopId },
      { $inc: { outstandingCredit: grandTotal } },
      createOptions(session)
    );
  }

  return { order, invoice };
};

export const checkout = async (shopId, payload) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const result = await checkoutWithOptionalSession(shopId, payload, session);
    await session.commitTransaction();
    return result;
  } catch (error) {
    await session.abortTransaction().catch(() => {});
    if (isTransactionUnsupported(error)) {
      return checkoutWithOptionalSession(shopId, payload);
    }
    throw error;
  } finally {
    session.endSession();
  }
};

export const list = async (shopId, query) => {
  const { page, limit, skip } = getPagination(query);
  const filter = { shopId };
  if (query.status) filter.status = query.status;
  if (query.paymentMode) filter.paymentMode = query.paymentMode;
  if (query.from || query.to) {
    filter.createdAt = {};
    if (query.from) filter.createdAt.$gte = new Date(query.from);
    if (query.to) filter.createdAt.$lte = new Date(query.to);
  }

  return paginatedResult(
    Order.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
    Order.countDocuments(filter),
    { page, limit }
  );
};

export const detail = async (shopId, id) => {
  const order = await Order.findOne({ _id: id, shopId }).populate("invoiceId");
  if (!order) throw new ApiError(404, "Order not found");
  return order;
};

export const voidOrder = async (shopId, id, reason) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const order = await Order.findOne({ _id: id, shopId }).session(session);
    if (!order) throw new ApiError(404, "Order not found");
    if (order.status === "void") throw new ApiError(400, "Order is already void");

    for (const item of order.items) {
      const product = await Product.findOneAndUpdate(
        { _id: item.productId, shopId },
        { $inc: { qty: item.qty } },
        { new: false, session }
      );
      if (product) {
        await StockMovement.create(
          [
            {
              shopId,
              productId: item.productId,
              productName: item.productName,
              type: "void_return",
              qtyChange: item.qty,
              qtyBefore: product.qty,
              qtyAfter: product.qty + item.qty,
              reason,
              orderId: order._id
            }
          ],
          { session }
        );
      }
    }

    order.status = "void";
    order.voidReason = reason;
    await order.save({ session });

    if (order.paymentMode === "credit" && order.customerId) {
      await Customer.updateOne(
        { _id: order.customerId, shopId },
        { $inc: { outstandingCredit: -order.grandTotal } },
        { session }
      );
    }

    await session.commitTransaction();
    return order;
  } catch (error) {
    await session.abortTransaction();
    throw error;
  } finally {
    session.endSession();
  }
};
