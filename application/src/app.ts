import { randomUUID } from "node:crypto";
import express, {
  type ErrorRequestHandler,
  type RequestHandler
} from "express";
import helmet from "helmet";

import { config } from "./config.js";
import { checkDatabase } from "./database.js";

export const app = express();

app.disable("x-powered-by");
app.use(helmet());
app.use(express.json({ limit: "100kb" }));

const requestContext: RequestHandler = (request, response, next) => {
  const suppliedCorrelationId = request.header("x-correlation-id");

  const correlationId =
    suppliedCorrelationId && suppliedCorrelationId.length <= 128
      ? suppliedCorrelationId
      : randomUUID();

  const startedAt = performance.now();

  response.setHeader("x-correlation-id", correlationId);

  response.on("finish", () => {
    console.log(
      JSON.stringify({
        timestamp: new Date().toISOString(),
        level: "info",
        event: "http_request",
        correlation_id: correlationId,
        method: request.method,
        path: request.originalUrl,
        status_code: response.statusCode,
        duration_ms: Math.round(performance.now() - startedAt),
        application_version: config.APP_VERSION
      })
    );
  });

  next();
};

app.use(requestContext);

app.get("/", (_request, response) => {
  response.status(200).json({
    platform: "CareFlow",
    service: "healthcare-appointment-api",
    version: config.APP_VERSION,
    environment: config.NODE_ENV,
    classification: "synthetic-data-only",
    disclaimer: "DEMONSTRATION PLATFORM — SYNTHETIC DATA ONLY"
  });
});

app.get("/health/live", (_request, response) => {
  response.status(200).json({
    status: "healthy",
    check: "liveness",
    service: "careflow-api",
    version: config.APP_VERSION,
    timestamp: new Date().toISOString()
  });
});

app.get("/health/ready", async (_request, response) => {
  try {
    const checkedAt = await checkDatabase();

    response.status(200).json({
      status: "healthy",
      check: "readiness",
      database: "reachable",
      checked_at: checkedAt.toISOString()
    });
  } catch (error) {
    console.error(
      JSON.stringify({
        timestamp: new Date().toISOString(),
        level: "error",
        event: "database_readiness_failed",
        message: error instanceof Error ? error.message : "Unknown error"
      })
    );

    response.status(503).json({
      status: "unhealthy",
      check: "readiness",
      database: "unreachable"
    });
  }
});

app.get("/version", (_request, response) => {
  response.status(200).json({
    service: "careflow-api",
    version: config.APP_VERSION,
    environment: config.NODE_ENV
  });
});

app.use((_request, response) => {
  response.status(404).json({
    error: "not_found",
    message: "The requested resource does not exist."
  });
});

const errorHandler: ErrorRequestHandler = (
  error,
  _request,
  response,
  _next
) => {
  console.error(
    JSON.stringify({
      timestamp: new Date().toISOString(),
      level: "error",
      event: "unhandled_application_error",
      message: error instanceof Error ? error.message : "Unknown error"
    })
  );

  response.status(500).json({
    error: "internal_server_error",
    message: "An unexpected error occurred."
  });
};

app.use(errorHandler);
