import { z } from "zod";

export const adjustStockSchema = z.object({
  body: z.object({
    productId: z.string().min(1),
    qtyChange: z.coerce.number().refine((value) => value !== 0, "qtyChange cannot be zero"),
    reason: z.string().min(1)
  })
});
