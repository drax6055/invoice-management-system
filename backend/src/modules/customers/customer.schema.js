import { z } from "zod";

const customerBody = z.object({
  name: z.string().min(1),
  phone: z.string().min(3),
  email: z.string().email().optional().or(z.literal(""))
});

export const createCustomerSchema = z.object({ body: customerBody });
export const updateCustomerSchema = z.object({ body: customerBody.partial() });
export const creditPaymentSchema = z.object({
  body: z.object({
    amount: z.coerce.number().positive()
  })
});
