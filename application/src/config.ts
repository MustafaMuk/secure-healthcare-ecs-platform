import "dotenv/config";
import { z } from "zod";

const environmentSchema = z.object({
  NODE_ENV: z
    .enum(["development", "test", "production"])
    .default("development"),

  PORT: z.coerce
    .number()
    .int()
    .min(1)
    .max(65535)
    .default(3000),

  APP_VERSION: z
    .string()
    .min(1)
    .default("0.1.0"),

  DATABASE_URL: z
    .string()
    .min(1)
    .default(
      "postgresql://careflow:careflow_dev@localhost:5432/careflow"
    )
});

const parsedEnvironment = environmentSchema.safeParse(process.env);

if (!parsedEnvironment.success) {
  console.error(
    JSON.stringify(
      {
        level: "error",
        event: "invalid_configuration",
        issues: parsedEnvironment.error.flatten().fieldErrors
      },
      null,
      2
    )
  );

  process.exit(1);
}

export const config = parsedEnvironment.data;
