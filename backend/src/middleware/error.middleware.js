import { ZodError } from "zod";

export const notFoundHandler = (req, res, next) => {
  res.status(404).json({
    success: false,
    statusCode: 404,
    message: `Route not found: ${req.method} ${req.originalUrl}`
  });
};

export const errorHandler = (err, req, res, next) => {
  if (err instanceof ZodError) {
    return res.status(400).json({
      success: false,
      statusCode: 400,
      message: "Validation failed",
      errors: err.flatten().fieldErrors
    });
  }

  if (err.name === "CastError") {
    return res.status(400).json({ success: false, statusCode: 400, message: "Invalid resource id" });
  }

  if (err.code === 11000) {
    return res.status(409).json({
      success: false,
      statusCode: 409,
      message: "Duplicate value",
      details: err.keyValue
    });
  }

  const statusCode = err.statusCode || 500;
  res.status(statusCode).json({
    success: false,
    statusCode,
    message: err.message || "Internal server error",
    ...(err.details ? { details: err.details } : {})
  });
};
