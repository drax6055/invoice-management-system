import mongoose from "mongoose";

const shopSchema = new mongoose.Schema(
  {
    ownerName: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    passwordHash: { type: String, required: true },
    shopName: { type: String, required: true, trim: true },
    shopAddress: { type: String, default: "" },
    phone: { type: String, default: "" },
    logoUrl: { type: String, default: "" },
    currency: { type: String, default: "INR" },
    taxLabel: { type: String, default: "GST" },
    taxRate: { type: Number, default: 0, min: 0 },
    invoicePrefix: { type: String, default: "INV" },
    invoiceCounter: { type: Number, default: 0 },
    refreshTokens: { type: [String], default: [] }
  },
  { timestamps: true }
);

shopSchema.methods.toSafeJSON = function toSafeJSON() {
  const obj = this.toObject();
  delete obj.passwordHash;
  delete obj.refreshTokens;
  return obj;
};

const Shop = mongoose.model("Shop", shopSchema);

export default Shop;
