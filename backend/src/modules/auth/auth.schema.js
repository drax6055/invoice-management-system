import { z } from "zod";

const password = z.string().min(8, "Password must be at least 8 characters");

export const registerSchema = z.object({
  body: z.object({
    ownerName: z.string().min(1),
    email: z.string().email(),
    password,
    shopName: z.string().min(1),
    shopAddress: z.string().optional(),
    phone: z.string().optional(),
    currency: z.string().default("INR"),
    taxLabel: z.string().default("GST"),
    taxRate: z.coerce.number().min(0).default(0),
    invoicePrefix: z.string().min(1).max(10).default("INV")
  })
});

export const loginSchema = z.object({
  body: z.object({
    email: z.string().email(),
    password: z.string().min(1)
  })
});

export const refreshSchema = z.object({
  body: z.object({
    refreshToken: z.string().min(1)
  })
});

export const logoutSchema = refreshSchema;

export const updateShopSchema = z.object({
  body: z.object({
    ownerName: z.string().min(1).optional(),
    shopName: z.string().min(1).optional(),
    shopAddress: z.string().optional(),
    phone: z.string().optional(),
    logoUrl: z.string().url().optional().or(z.literal("")),
    currency: z.string().optional(),
    taxLabel: z.string().optional(),
    taxRate: z.coerce.number().min(0).optional(),
    invoicePrefix: z.string().min(1).max(10).optional()
  })
});
