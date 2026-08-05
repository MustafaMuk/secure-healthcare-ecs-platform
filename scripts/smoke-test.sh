#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.."
  pwd
)"

APPLICATION_DIR="${PROJECT_ROOT}/application"
PORT="${PORT:-3100}"
BASE_URL="http://127.0.0.1:${PORT}"
LOG_FILE="${TMPDIR:-/tmp}/careflow-smoke-test.log"

API_PID=""

cleanup() {
  if [ -n "${API_PID}" ] && kill -0 "${API_PID}" 2>/dev/null; then
    kill "${API_PID}"
    wait "${API_PID}" 2>/dev/null || true
  fi
}

show_logs() {
  echo
  echo "=== Application logs ==="
  cat "${LOG_FILE}" 2>/dev/null || true
}

trap cleanup EXIT
trap 'show_logs' ERR

cd "${APPLICATION_DIR}"

echo "Starting CareFlow API on port ${PORT}..."

PORT="${PORT}" \
APP_VERSION="${APP_VERSION:-ci-smoke-test}" \
node dist/server.js >"${LOG_FILE}" 2>&1 &

API_PID=$!

echo "Waiting for database readiness..."

for attempt in $(seq 1 30); do
  if curl -fsS "${BASE_URL}/health/ready" >/dev/null 2>&1; then
    echo "API became ready on attempt ${attempt}."
    break
  fi

  if [ "${attempt}" -eq 30 ]; then
    echo "API did not become ready."
    exit 1
  fi

  sleep 2
done

PATIENT_NUMBER=$(printf "%04d" $((RANDOM % 10000)))

echo
echo "=== Create appointment ==="

CREATE_RESPONSE=$(
  curl -fsS \
    -X POST \
    -H "Content-Type: application/json" \
    -H "x-correlation-id: ci-create-appointment" \
    -d "{
      \"patient_reference\": \"SYN-PAT-${PATIENT_NUMBER}\",
      \"clinic\": \"Cardiology Demonstration Clinic\",
      \"scheduled_at\": \"2027-01-15T10:30:00Z\",
      \"actor\": \"demo-ci-user\"
    }" \
    "${BASE_URL}/api/appointments"
)

echo "${CREATE_RESPONSE}"

APPOINTMENT_ID=$(
  printf "%s" "${CREATE_RESPONSE}" |
    node --input-type=module -e '
      import fs from "node:fs";

      const response = JSON.parse(
        fs.readFileSync(0, "utf8")
      );

      if (
        !response.appointment ||
        !response.appointment.appointment_id
      ) {
        throw new Error("Appointment ID was not returned");
      }

      console.log(
        response.appointment.appointment_id
      );
    '
)

echo
echo "Created appointment: ${APPOINTMENT_ID}"

echo
echo "=== Confirm appointment ==="

CONFIRM_RESPONSE=$(
  curl -fsS \
    -X PATCH \
    -H "Content-Type: application/json" \
    -H "x-correlation-id: ci-confirm-appointment" \
    -d '{
      "status": "confirmed",
      "actor": "demo-ci-user"
    }' \
    "${BASE_URL}/api/appointments/${APPOINTMENT_ID}/status"
)

echo "${CONFIRM_RESPONSE}"

echo
echo "=== Verify invalid transition is rejected ==="

INVALID_RESPONSE_FILE=$(
  mktemp
)

INVALID_STATUS_CODE=$(
  curl -sS \
    -o "${INVALID_RESPONSE_FILE}" \
    -w "%{http_code}" \
    -X PATCH \
    -H "Content-Type: application/json" \
    -H "x-correlation-id: ci-invalid-transition" \
    -d '{
      "status": "completed",
      "actor": "demo-ci-user"
    }' \
    "${BASE_URL}/api/appointments/${APPOINTMENT_ID}/status"
)

cat "${INVALID_RESPONSE_FILE}"
echo

if [ "${INVALID_STATUS_CODE}" != "409" ]; then
  echo "Expected HTTP 409 but received ${INVALID_STATUS_CODE}."
  rm -f "${INVALID_RESPONSE_FILE}"
  exit 1
fi

rm -f "${INVALID_RESPONSE_FILE}"

echo
echo "=== Verify audit history ==="

AUDIT_RESPONSE=$(
  curl -fsS \
    "${BASE_URL}/api/appointments/${APPOINTMENT_ID}/audit"
)

echo "${AUDIT_RESPONSE}"

printf "%s" "${AUDIT_RESPONSE}" |
  node --input-type=module -e '
    import fs from "node:fs";

    const response = JSON.parse(
      fs.readFileSync(0, "utf8")
    );

    const events = response.audit_events.map(
      (event) => event.event_type
    );

    const requiredEvents = [
      "appointment_created",
      "appointment_status_changed"
    ];

    for (const requiredEvent of requiredEvents) {
      if (!events.includes(requiredEvent)) {
        throw new Error(
          `Missing audit event: ${requiredEvent}`
        );
      }
    }

    if (response.count !== 2) {
      throw new Error(
        `Expected 2 audit events, received ${response.count}`
      );
    }

    console.log(
      "Audit history contains all required events."
    );
  '

echo
echo "CareFlow end-to-end smoke test passed."
