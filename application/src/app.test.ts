import request from "supertest";
import { describe, expect, it } from "vitest";

import { app } from "./app.js";

describe("CareFlow API", () => {
  it("returns platform information", async () => {
    const response = await request(app).get("/");

    expect(response.status).toBe(200);
    expect(response.body).toMatchObject({
      platform: "CareFlow",
      service: "healthcare-appointment-api",
      classification: "synthetic-data-only"
    });

    expect(response.headers["x-correlation-id"]).toBeDefined();
  });

  it("passes the liveness check", async () => {
    const response = await request(app).get("/health/live");

    expect(response.status).toBe(200);
    expect(response.body).toMatchObject({
      status: "healthy",
      check: "liveness",
      service: "careflow-api"
    });
  });

  it("returns application version information", async () => {
    const response = await request(app).get("/version");

    expect(response.status).toBe(200);
    expect(response.body.service).toBe("careflow-api");
  });

  it("returns a structured 404 response", async () => {
    const response = await request(app).get("/does-not-exist");

    expect(response.status).toBe(404);
    expect(response.body.error).toBe("not_found");
  });
});
