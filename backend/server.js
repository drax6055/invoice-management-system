import app from "./src/app.js";
import { env } from "./src/config/env.js";
import { connectDB } from "./src/config/db.js";

const startServer = async () => {
  await connectDB();

  app.listen(env.PORT, () => {
    console.log(`API server running on port ${env.PORT}`);
  });
};

startServer().catch((error) => {
  console.error("Failed to start API server", error);
  process.exit(1);
});
