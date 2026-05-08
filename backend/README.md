# Invoice Management Backend

Multi-tenant Node.js + Express + MongoDB API for shop onboarding, product inventory, POS checkout, invoice generation, customers, stock movements, and reporting.

## Quick Start

```bash
cd backend
cp .env.example .env
npm install
npm run dev
```

Set `MONGODB_URI`, `JWT_SECRET`, and `REFRESH_TOKEN_SECRET` in `.env` before starting.

For your local network setup, `.env.example` is already configured for:

```env
PORT=3000
CORS_ORIGIN=http://192.168.29.39:8080
```

The backend API will be available at `http://192.168.29.39:3000/api` when your machine is reachable on that IP.

## API Surface

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/refresh`
- `POST /api/auth/logout`
- `GET /api/auth/me`
- `PATCH /api/auth/shop`
- `GET|POST /api/products`
- `GET|PATCH|DELETE /api/products/:id`
- `GET /api/products/barcode/:code`
- `POST /api/products/bulk-import`
- `GET|POST /api/categories`
- `PATCH|DELETE /api/categories/:id`
- `POST /api/stock/adjust`
- `GET /api/stock/movements`
- `GET /api/stock/low`
- `POST /api/orders/checkout`
- `GET /api/orders`
- `GET /api/orders/:id`
- `PATCH /api/orders/:id/void`
- `GET /api/invoices`
- `GET /api/invoices/:id`
- `GET|POST /api/customers`
- `GET|PATCH /api/customers/:id`
- `PATCH /api/customers/:id/credit`
- `GET /api/reports/*`

All non-auth routes use JWT auth. The backend injects `req.shopId` from the token and every service scopes database queries by that tenant id.

## Checkout Notes

`POST /api/orders/checkout` runs in a MongoDB transaction:

1. Fetches and validates tenant-owned products.
2. Checks and deducts stock atomically.
3. Logs stock movements.
4. Generates the next tenant-specific invoice number.
5. Creates an order and invoice.
6. Updates customer credit when payment mode is `credit`.
