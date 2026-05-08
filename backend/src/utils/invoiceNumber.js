import Shop from "../modules/auth/auth.model.js";
import { ApiError } from "./ApiError.js";

export const generateInvoiceNumber = async (shopId, session) => {
  const shop = await Shop.findByIdAndUpdate(
    shopId,
    { $inc: { invoiceCounter: 1 } },
    { new: true, select: "invoiceCounter invoicePrefix", ...(session ? { session } : {}) }
  );

  if (!shop) {
    throw new ApiError(404, "Shop not found");
  }

  return `${shop.invoicePrefix}-${String(shop.invoiceCounter).padStart(4, "0")}`;
};
