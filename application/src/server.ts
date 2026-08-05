import { app } from "./app.js";
import { config } from "./config.js";
import { closeDatabase } from "./database.js";

const server = app.listen(config.PORT, "0.0.0.0", () => {
  console.log(
    JSON.stringify({
      timestamp: new Date().toISOString(),
      level: "info",
      event: "application_started",
      service: "careflow-api",
      version: config.APP_VERSION,
      environment: config.NODE_ENV,
      port: config.PORT
    })
  );
});

let shuttingDown = false;

function shutdown(signal: string): void {
  if (shuttingDown) {
    return;
  }

  shuttingDown = true;

  console.log(
    JSON.stringify({
      timestamp: new Date().toISOString(),
      level: "info",
      event: "application_shutdown_started",
      signal
    })
  );

  server.close(() => {
    closeDatabase()
      .catch((error: unknown) => {
        console.error(
          JSON.stringify({
            timestamp: new Date().toISOString(),
            level: "error",
            event: "database_shutdown_failed",
            message:
              error instanceof Error ? error.message : "Unknown error"
          })
        );
      })
      .finally(() => {
        process.exit(0);
      });
  });
}

process.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("SIGINT", () => shutdown("SIGINT"));
