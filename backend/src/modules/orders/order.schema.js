import { z } from "zod";
import { PAYMENT_MODES } from "../../config/constants.js";

export const checkoutSchema = z.object({
  body: z.object({
    cartItems: z.array(
      z.object({
        productId: z.string().min(1),
        qty: z.coerce.number().int().positive(),
        discount: z.coerce.number().min(0).default(0)
      })
    ).min(1),
    discountTotal: z.coerce.number().min(0).default(0),
    taxRate: z.coerce.number().min(0).optional(),
    paymentMode: z.enum(PAYMENT_MODES),
    customerId: z.string().optional(),
    customer: z
      .object({
        name: z.string().min(1),
        phone: z.string().min(3),
        email: z.string().email().optional().or(z.literal(""))
      })
      .optional()
  })
});

export const voidOrderSchema = z.object({
  body: z.object({
    reason: z.string().min(1)
  })
});
