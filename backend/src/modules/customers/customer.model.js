import mongoose from "mongoose";

const customerSchema = new mongoose.Schema(
  {
    shopId: { type: mongoose.Schema.Types.ObjectId, ref: "Shop", required: true, index: true },
    name: { type: String, required: true, trim: true },
    phone: { type: String, required: true, trim: true },
    email: { type: String, lowercase: true, trim: true },
    outstandingCredit: { type: Number, default: 0, min: 0 }
  },
  { timestamps: true }
);

customerSchema.index({ shopId: 1, phone: 1 }, { unique: true });

const Customer = mongoose.model("Customer", customerSchema);

export default Customer;
