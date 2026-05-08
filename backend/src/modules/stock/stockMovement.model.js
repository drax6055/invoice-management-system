import mongoose from "mongoose";
import { STOCK_MOVEMENT_TYPES } from "../../config/constants.js";

const stockMovementSchema = new mongoose.Schema(
  {
    shopId: { type: mongoose.Schema.Types.ObjectId, ref: "Shop", required: true, index: true },
    productId: { type: mongoose.Schema.Types.ObjectId, ref: "Product", required: true, index: true },
    productName: { type: String, required: true },
    type: { type: String, enum: STOCK_MOVEMENT_TYPES, required: true },
    qtyChange: { type: Number, required: true },
    qtyBefore: { type: Number, required: true },
    qtyAfter: { type: Number, required: true },
    reason: { type: String, default: "" },
    orderId: { type: mongoose.Schema.Types.ObjectId, ref: "Order" }
  },
  { timestamps: true }
);

stockMovementSchema.index({ shopId: 1, createdAt: -1 });

const StockMovement = mongoose.model("StockMovement", stockMovementSchema);

export default StockMovement;
