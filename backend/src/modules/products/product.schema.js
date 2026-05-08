import { z } from "zod";

const productBody = z.object({
  name: z.string().min(1),
  sku: z.string().optional(),
  barcode: z.string().optional(),
  categoryId: z.string().optional(),
  price: z.coerce.number().min(0),
  costPrice: z.coerce.number().min(0).default(0),
  qty: z.coerce.number().min(0).default(0),
  unit: z.string().default("pcs"),
  lowStockThreshold: z.coerce.number().min(0).default(0),
  imageUrl: z.string().url().optional().or(z.literal(""))
});

export const createProductSchema = z.object({ body: productBody });
export const updateProductSchema = z.object({ body: productBody.partial() });

export const bulkImportSchema = z.object({
  body: z.object({
    products: z.array(productBody).min(1)
  })
});
