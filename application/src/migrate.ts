import fs from "node:fs/promises";
import path from "node:path";

import { closeDatabase, databasePool } from "./database.js";

async function runMigrations(): Promise<void> {
  const migrationsDirectory = path.resolve(process.cwd(), "migrations");

  const migrationFiles = (await fs.readdir(migrationsDirectory))
    .filter((fileName) => fileName.endsWith(".sql"))
    .sort();

  const client = await databasePool.connect();

  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        migration_name TEXT PRIMARY KEY,
        applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    `);

    for (const migrationFile of migrationFiles) {
      const existingMigration = await client.query(
        `
          SELECT migration_name
          FROM schema_migrations
          WHERE migration_name = $1
        `,
        [migrationFile]
      );

      if (existingMigration.rowCount !== 0) {
        console.log(`Migration already applied: ${migrationFile}`);
        continue;
      }

      const migrationSql = await fs.readFile(
        path.join(migrationsDirectory, migrationFile),
        "utf8"
      );

      console.log(`Applying migration: ${migrationFile}`);

      await client.query("BEGIN");

      try {
        await client.query(migrationSql);

        await client.query(
          `
            INSERT INTO schema_migrations (migration_name)
            VALUES ($1)
          `,
          [migrationFile]
        );

        await client.query("COMMIT");
        console.log(`Migration completed: ${migrationFile}`);
      } catch (error) {
        await client.query("ROLLBACK");
        throw error;
      }
    }
  } finally {
    client.release();
  }
}

runMigrations()
  .then(async () => {
    console.log("All database migrations completed.");
    await closeDatabase();
  })
  .catch(async (error: unknown) => {
    console.error(
      error instanceof Error ? error.message : "Migration failed"
    );

    await closeDatabase();
    process.exitCode = 1;
  });
