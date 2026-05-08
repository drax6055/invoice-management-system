import mongoose from "mongoose";

const productSchema = new mongoose.Schema(
  {
    shopId: { type: mongoose.Schema.Types.ObjectId, ref: "Shop", required: true, index: true },
    name: { type: String, required: true, trim: true },
    sku: { type: String, trim: true },
    barcode: { type: String, trim: true },
    categoryId: { type: mongoose.Schema.Types.ObjectId, ref: "Category" },
    price: { type: Number, required: true, min: 0 },
    costPrice: { type: Number, default: 0, min: 0 },
    qty: { type: Number, default: 0, min: 0 },
    unit: { type: String, default: "pcs" },
    lowStockThreshold: { type: Number, default: 0, min: 0 },
    imageUrl: { type: String, default: "" },
    isArchived: { type: Boolean, default: false, index: true }
  },
  { timestamps: true }
);

productSchema.index({ shopId: 1, barcode: 1 }, { unique: true, sparse: true });
productSchema.index({ shopId: 1, sku: 1 }, { unique: true, sparse: true });
productSchema.index({ shopId: 1, name: "text" });

const Product = mongoose.model("Product", productSchema);

export default Product;
