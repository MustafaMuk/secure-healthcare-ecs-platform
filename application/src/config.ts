import "dotenv/config";
import { z } from "zod";

const environmentSchema = z
  .object({
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

    // Used by local development and CI.
    DATABASE_URL: z
      .string()
      .min(1)
      .optional(),

    // Used by ECS with values supplied from Terraform
    // and the RDS-managed Secrets Manager secret.
    DB_HOST: z
      .string()
      .min(1)
      .optional(),

    DB_PORT: z.coerce
      .number()
      .int()
      .min(1)
      .max(65535)
      .default(5432),

    DB_NAME: z
      .string()
      .min(1)
      .default("careflow"),

    DB_USER: z
      .string()
      .min(1)
      .optional(),

    DB_PASSWORD: z
      .string()
      .min(1)
      .optional(),

    DB_SSL: z
      .enum(["true", "false"])
      .default("false")
      .transform((value) => value === "true"),

    DB_SSL_CA_PATH: z
      .string()
      .min(1)
      .optional()
  })
  .superRefine((environment, context) => {
    if (!environment.DATABASE_URL) {
      const requiredVariables = [
        ["DB_HOST", environment.DB_HOST],
        ["DB_USER", environment.DB_USER],
        ["DB_PASSWORD", environment.DB_PASSWORD]
      ] as const;

      for (const [variableName, variableValue] of requiredVariables) {
        if (!variableValue) {
          context.addIssue({
            code: "custom",
            path: [variableName],
            message: `${variableName} is required when DATABASE_URL is absent`
          });
        }
      }
    }

    if (
      environment.DB_SSL &&
      !environment.DB_SSL_CA_PATH
    ) {
      context.addIssue({
        code: "custom",
        path: ["DB_SSL_CA_PATH"],
        message:
          "DB_SSL_CA_PATH is required when DB_SSL is enabled"
      });
    }
  });

const parsedEnvironment = environmentSchema.safeParse(
  process.env
);

if (!parsedEnvironment.success) {
  console.error(
    JSON.stringify(
      {
        level: "error",
        event: "invalid_configuration",
        issues:
          parsedEnvironment.error.flatten().fieldErrors
      },
      null,
      2
    )
  );

  process.exit(1);
}

export const config = parsedEnvironment.data;
