import fs from "node:fs";

import {
  Pool,
  type PoolConfig
} from "pg";

import { config } from "./config.js";

function createSslConfiguration(): PoolConfig["ssl"] {
  if (!config.DB_SSL) {
    return undefined;
  }

  if (!config.DB_SSL_CA_PATH) {
    throw new Error(
      "DB_SSL_CA_PATH is required for verified database TLS"
    );
  }

  const certificateAuthority = fs.readFileSync(
    config.DB_SSL_CA_PATH,
    "utf8"
  );

  return {
    ca: certificateAuthority,
    rejectUnauthorized: true
  };
}

const databaseConnection: PoolConfig =
  config.DATABASE_URL
    ? {
        connectionString: config.DATABASE_URL,
        ssl: createSslConfiguration()
      }
    : {
        host: config.DB_HOST!,
        port: config.DB_PORT,
        database: config.DB_NAME,
        user: config.DB_USER!,
        password: config.DB_PASSWORD!,
        ssl: createSslConfiguration()
      };

export const databasePool = new Pool({
  ...databaseConnection,
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
  const result = await databasePool.query<{
    checked_at: Date;
  }>(
    "SELECT NOW() AS checked_at"
  );

  return result.rows[0]?.checked_at ?? new Date();
}

export async function closeDatabase(): Promise<void> {
  await databasePool.end();
}
