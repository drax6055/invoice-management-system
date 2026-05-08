import mongoose from "mongoose";

const invoiceSchema = new mongoose.Schema(
  {
    shopId: { type: mongoose.Schema.Types.ObjectId, ref: "Shop", required: true, index: true },
    orderId: { type: mongoose.Schema.Types.ObjectId, ref: "Order", required: true },
    invoiceNumber: { type: String, required: true },
    shopSnapshot: {
      name: String,
      address: String,
      phone: String,
      taxLabel: String,
      logoUrl: String
    },
    customerSnapshot: {
      name: String,
      phone: String,
      email: String
    },
    items: { type: Array, default: [] },
    subtotal: { type: Number, required: true },
    discountTotal: { type: Number, default: 0 },
    taxRate: { type: Number, default: 0 },
    taxAmount: { type: Number, default: 0 },
    grandTotal: { type: Number, required: true },
    paymentMode: { type: String, required: true }
  },
  { timestamps: true }
);

invoiceSchema.index({ shopId: 1, createdAt: -1 });
invoiceSchema.index({ shopId: 1, invoiceNumber: 1 }, { unique: true });

const Invoice = mongoose.model("Invoice", invoiceSchema);

export default Invoice;
