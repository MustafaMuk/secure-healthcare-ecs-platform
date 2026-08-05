import { randomUUID } from "node:crypto";

import {
  Router,
  type NextFunction,
  type Request,
  type Response
} from "express";
import { z } from "zod";

import { databasePool } from "./database.js";

export const appointmentRouter = Router();

const appointmentStatuses = [
  "scheduled",
  "confirmed",
  "checked_in",
  "completed",
  "cancelled",
  "did_not_attend"
] as const;

type AppointmentStatus =
  (typeof appointmentStatuses)[number];

const appointmentStatusSchema = z.enum(
  appointmentStatuses
);

const createAppointmentSchema = z.object({
  patient_reference: z
    .string()
    .regex(
      /^SYN-PAT-[0-9]{4}$/,
      "Use a synthetic reference such as SYN-PAT-0001"
    ),

  clinic: z
    .string()
    .trim()
    .min(3)
    .max(100),

  scheduled_at: z
    .string()
    .refine(
      (value) => !Number.isNaN(Date.parse(value)),
      "scheduled_at must be a valid date and time"
    ),

  actor: z
    .string()
    .regex(
      /^demo-[a-z0-9-]{3,50}$/,
      "Use a synthetic actor such as demo-reception-user"
    )
});

const listAppointmentsSchema = z.object({
  status: appointmentStatusSchema.optional(),
  clinic: z.string().trim().min(1).max(100).optional()
});

const updateStatusSchema = z.object({
  status: appointmentStatusSchema,

  actor: z
    .string()
    .regex(
      /^demo-[a-z0-9-]{3,50}$/,
      "Use a synthetic actor such as demo-reception-user"
    )
});

const appointmentIdSchema = z.object({
  appointmentId: z.string().uuid()
});

interface AppointmentRow {
  appointment_id: string;
  appointment_reference: string;
  patient_reference: string;
  clinic: string;
  scheduled_at: Date;
  status: AppointmentStatus;
  data_classification: string;
  created_by: string;
  created_at: Date;
  updated_at: Date;
}

interface AuditRow {
  audit_event_id: string;
  appointment_id: string;
  event_type: string;
  actor: string;
  previous_values: Record<string, unknown> | null;
  new_values: Record<string, unknown>;
  correlation_id: string;
  created_at: Date;
}

const allowedStatusTransitions: Record<
  AppointmentStatus,
  AppointmentStatus[]
> = {
  scheduled: ["confirmed", "cancelled"],
  confirmed: [
    "checked_in",
    "cancelled",
    "did_not_attend"
  ],
  checked_in: ["completed"],
  completed: [],
  cancelled: [],
  did_not_attend: []
};

function formatAppointment(row: AppointmentRow) {
  return {
    ...row,
    scheduled_at: row.scheduled_at.toISOString(),
    created_at: row.created_at.toISOString(),
    updated_at: row.updated_at.toISOString()
  };
}

function formatAuditEvent(row: AuditRow) {
  return {
    ...row,
    created_at: row.created_at.toISOString()
  };
}

appointmentRouter.get(
  "/",
  async (
    request: Request,
    response: Response,
    next: NextFunction
  ) => {
    const parsedQuery =
      listAppointmentsSchema.safeParse(request.query);

    if (!parsedQuery.success) {
      response.status(400).json({
        error: "validation_failed",
        issues: parsedQuery.error.flatten().fieldErrors
      });
      return;
    }

    const conditions: string[] = [];
    const values: unknown[] = [];

    if (parsedQuery.data.status) {
      values.push(parsedQuery.data.status);
      conditions.push(`status = $${values.length}`);
    }

    if (parsedQuery.data.clinic) {
      values.push(parsedQuery.data.clinic);
      conditions.push(`clinic = $${values.length}`);
    }

    const whereClause =
      conditions.length > 0
        ? `WHERE ${conditions.join(" AND ")}`
        : "";

    try {
      const result =
        await databasePool.query<AppointmentRow>(
          `
            SELECT
              appointment_id,
              appointment_reference,
              patient_reference,
              clinic,
              scheduled_at,
              status,
              data_classification,
              created_by,
              created_at,
              updated_at
            FROM appointments
            ${whereClause}
            ORDER BY scheduled_at ASC
            LIMIT 100
          `,
          values
        );

      response.status(200).json({
        count: result.rowCount,
        appointments: result.rows.map(formatAppointment)
      });
    } catch (error) {
      next(error);
    }
  }
);

appointmentRouter.post(
  "/",
  async (
    request: Request,
    response: Response,
    next: NextFunction
  ) => {
    const parsedBody =
      createAppointmentSchema.safeParse(request.body);

    if (!parsedBody.success) {
      response.status(400).json({
        error: "validation_failed",
        issues: parsedBody.error.flatten().fieldErrors
      });
      return;
    }

    const appointmentId = randomUUID();

    const appointmentReference = [
      "APT",
      new Date().getUTCFullYear(),
      randomUUID()
        .replaceAll("-", "")
        .slice(0, 8)
        .toUpperCase()
    ].join("-");

    const correlationId = String(
      response.locals.correlationId
    );

    const client = await databasePool.connect();

    try {
      await client.query("BEGIN");

      const appointmentResult =
        await client.query<AppointmentRow>(
          `
            INSERT INTO appointments (
              appointment_id,
              appointment_reference,
              patient_reference,
              clinic,
              scheduled_at,
              status,
              created_by
            )
            VALUES ($1, $2, $3, $4, $5, 'scheduled', $6)
            RETURNING *
          `,
          [
            appointmentId,
            appointmentReference,
            parsedBody.data.patient_reference,
            parsedBody.data.clinic,
            new Date(parsedBody.data.scheduled_at),
            parsedBody.data.actor
          ]
        );

      const appointment = appointmentResult.rows[0];

      if (!appointment) {
        throw new Error(
          "Appointment insert returned no record"
        );
      }

      await client.query(
        `
          INSERT INTO appointment_audit (
            audit_event_id,
            appointment_id,
            event_type,
            actor,
            previous_values,
            new_values,
            correlation_id
          )
          VALUES ($1, $2, $3, $4, $5, $6, $7)
        `,
        [
          randomUUID(),
          appointmentId,
          "appointment_created",
          parsedBody.data.actor,
          null,
          {
            appointment_reference: appointmentReference,
            patient_reference:
              parsedBody.data.patient_reference,
            clinic: parsedBody.data.clinic,
            scheduled_at:
              parsedBody.data.scheduled_at,
            status: "scheduled"
          },
          correlationId
        ]
      );

      await client.query("COMMIT");

      response.status(201).json({
        appointment: formatAppointment(appointment)
      });
    } catch (error) {
      await client.query("ROLLBACK");
      next(error);
    } finally {
      client.release();
    }
  }
);

appointmentRouter.patch(
  "/:appointmentId/status",
  async (
    request: Request,
    response: Response,
    next: NextFunction
  ) => {
    const parsedParameters =
      appointmentIdSchema.safeParse(request.params);

    const parsedBody =
      updateStatusSchema.safeParse(request.body);

    if (
      !parsedParameters.success ||
      !parsedBody.success
    ) {
      response.status(400).json({
        error: "validation_failed",
        parameter_issues: parsedParameters.success
          ? {}
          : parsedParameters.error.flatten().fieldErrors,
        body_issues: parsedBody.success
          ? {}
          : parsedBody.error.flatten().fieldErrors
      });
      return;
    }

    const correlationId = String(
      response.locals.correlationId
    );

    const client = await databasePool.connect();

    try {
      await client.query("BEGIN");

      const existingResult =
        await client.query<AppointmentRow>(
          `
            SELECT *
            FROM appointments
            WHERE appointment_id = $1
            FOR UPDATE
          `,
          [parsedParameters.data.appointmentId]
        );

      const existingAppointment =
        existingResult.rows[0];

      if (!existingAppointment) {
        await client.query("ROLLBACK");

        response.status(404).json({
          error: "appointment_not_found"
        });
        return;
      }

      const requestedStatus = parsedBody.data.status;

      const allowedTransitions =
        allowedStatusTransitions[
          existingAppointment.status
        ];

      if (!allowedTransitions.includes(requestedStatus)) {
        await client.query("ROLLBACK");

        response.status(409).json({
          error: "invalid_status_transition",
          current_status: existingAppointment.status,
          requested_status: requestedStatus,
          allowed_transitions: allowedTransitions
        });
        return;
      }

      const updatedResult =
        await client.query<AppointmentRow>(
          `
            UPDATE appointments
            SET
              status = $1,
              updated_at = NOW()
            WHERE appointment_id = $2
            RETURNING *
          `,
          [
            requestedStatus,
            parsedParameters.data.appointmentId
          ]
        );

      const updatedAppointment =
        updatedResult.rows[0];

      if (!updatedAppointment) {
        throw new Error(
          "Appointment update returned no record"
        );
      }

      await client.query(
        `
          INSERT INTO appointment_audit (
            audit_event_id,
            appointment_id,
            event_type,
            actor,
            previous_values,
            new_values,
            correlation_id
          )
          VALUES ($1, $2, $3, $4, $5, $6, $7)
        `,
        [
          randomUUID(),
          parsedParameters.data.appointmentId,
          "appointment_status_changed",
          parsedBody.data.actor,
          {
            status: existingAppointment.status
          },
          {
            status: requestedStatus
          },
          correlationId
        ]
      );

      await client.query("COMMIT");

      response.status(200).json({
        appointment:
          formatAppointment(updatedAppointment)
      });
    } catch (error) {
      await client.query("ROLLBACK");
      next(error);
    } finally {
      client.release();
    }
  }
);

appointmentRouter.get(
  "/:appointmentId/audit",
  async (
    request: Request,
    response: Response,
    next: NextFunction
  ) => {
    const parsedParameters =
      appointmentIdSchema.safeParse(request.params);

    if (!parsedParameters.success) {
      response.status(400).json({
        error: "validation_failed",
        issues:
          parsedParameters.error.flatten().fieldErrors
      });
      return;
    }

    try {
      const result =
        await databasePool.query<AuditRow>(
          `
            SELECT
              audit_event_id,
              appointment_id,
              event_type,
              actor,
              previous_values,
              new_values,
              correlation_id,
              created_at
            FROM appointment_audit
            WHERE appointment_id = $1
            ORDER BY created_at ASC
          `,
          [parsedParameters.data.appointmentId]
        );

      response.status(200).json({
        count: result.rowCount,
        audit_events: result.rows.map(formatAuditEvent)
      });
    } catch (error) {
      next(error);
    }
  }
);
