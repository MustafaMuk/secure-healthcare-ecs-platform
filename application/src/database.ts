import { Pool } from "pg";
import { config } from "./config.js";

export const databasePool = new Pool({
  connectionString: config.DATABASE_URL,
  max: 10,
  connectionTimeoutMillis: 5000,
  idleTimeoutMillis: 30000
});

databasePool.on("error", (error: Error) => {
  console.error(
    JSON.stringify({
      timestamp: new Date().toISOString(),
      level: "error",
      event: "database_pool_error",
      message: error.message
    })
  );
});

export async function checkDatabase(): Promise<Date> {
  const result = await databasePool.query<{ checked_at: Date }>(
    "SELECT NOW() AS checked_at"
  );

  return result.rows[0]?.checked_at ?? new Date();
}

export async function closeDatabase(): Promise<void> {
  await databasePool.end();
}
