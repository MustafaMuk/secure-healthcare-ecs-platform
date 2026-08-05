CREATE TABLE appointments (
    appointment_id UUID PRIMARY KEY,
    appointment_reference VARCHAR(32) UNIQUE NOT NULL,

    patient_reference VARCHAR(32) NOT NULL
        CHECK (patient_reference ~ '^SYN-PAT-[0-9]{4}$'),

    clinic VARCHAR(100) NOT NULL,
    scheduled_at TIMESTAMPTZ NOT NULL,

    status VARCHAR(32) NOT NULL DEFAULT 'scheduled'
        CHECK (
            status IN (
                'scheduled',
                'confirmed',
                'checked_in',
                'completed',
                'cancelled',
                'did_not_attend'
            )
        ),

    data_classification VARCHAR(32) NOT NULL
        DEFAULT 'synthetic-data-only'
        CHECK (data_classification = 'synthetic-data-only'),

    created_by VARCHAR(64) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE appointment_audit (
    audit_event_id UUID PRIMARY KEY,

    appointment_id UUID NOT NULL
        REFERENCES appointments(appointment_id)
        ON DELETE RESTRICT,

    event_type VARCHAR(64) NOT NULL,
    actor VARCHAR(64) NOT NULL,

    previous_values JSONB,
    new_values JSONB NOT NULL,

    correlation_id VARCHAR(128) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX appointments_scheduled_at_index
    ON appointments(scheduled_at);

CREATE INDEX appointments_status_index
    ON appointments(status);

CREATE INDEX appointment_audit_appointment_index
    ON appointment_audit(appointment_id, created_at);
