#!/usr/bin/env bash
#
# Export contributor names from DSpace PostgreSQL via K8s tunnel
# Produces one CSV per metadata field (e.g., dc.contributor.author, dc.contributor.advisor)
#

set -euo pipefail

#######################################
# Configuration
#######################################

# K8s pod — update when pod restarts
POD_NAME="unbscholar-postgres-lib-unb-ca-5bf8f857bb-npz22"
NAMESPACE="${NAMESPACE:-prod}"
LOCAL_PORT="${LOCAL_PORT:-15432}"

# PostgreSQL port inside the pod
PG_PORT=5432

# Output
OUTPUT_DIR="${OUTPUT_DIR:-./exports}"

# Metadata field qualifiers to export
FIELDS=("author" "advisor")

# Port-forward PID
PF_PID=""

#######################################
# Helper Functions
#######################################

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
}

cleanup() {
    log "Cleaning up port-forward..."
    if [[ -n "$PF_PID" ]] && kill -0 "$PF_PID" 2>/dev/null; then
        kill "$PF_PID" 2>/dev/null || true
        log "Stopped port-forward (PID: $PF_PID)"
    fi
}

trap cleanup EXIT

get_pod_env() {
    local namespace="$1"
    local pod="$2"
    local var="$3"
    kubectl exec -n "$namespace" "$pod" -- printenv "$var" 2>/dev/null
}

start_pf_pod() {
    local namespace="$1"
    local pod="$2"
    local local_port="$3"
    local remote_port="$4"
    local log_file="${OUTPUT_DIR}/pf_${local_port}.log"

    log "Starting port-forward to $pod in $namespace ($local_port:$remote_port)..."
    kubectl port-forward -n "$namespace" "$pod" "${local_port}:${remote_port}" >"$log_file" 2>&1 &
    local pid=$!
    sleep 1

    if ! kill -0 "$pid" 2>/dev/null; then
        error "Port-forward failed to start. Log output:"
        cat "$log_file" >&2
        return 1
    fi

    echo $pid
}

wait_for_postgres() {
    local host="$1"
    local port="$2"
    local user="$3"
    local password="$4"
    local db="$5"
    local pf_pid="$6"
    local max_attempts="${7:-30}"
    local attempt=1

    log "Waiting for PostgreSQL at $host:$port to accept connections..."
    while [[ $attempt -le $max_attempts ]]; do
        if ! kill -0 "$pf_pid" 2>/dev/null; then
            error "Port-forward process (PID: $pf_pid) died unexpectedly"
            local log_file="${OUTPUT_DIR}/pf_${port}.log"
            if [[ -f "$log_file" ]]; then
                error "Port-forward log:"
                cat "$log_file" >&2
            fi
            return 1
        fi

        local output
        if output=$(PGPASSWORD="$password" psql -h "$host" -p "$port" -U "$user" -d "$db" -c "SELECT 1;" 2>&1); then
            log "PostgreSQL is ready after $attempt attempt(s)"
            return 0
        fi

        if [[ $attempt -eq 1 ]]; then
            log "Connection attempt 1 failed: ${output:0:100}..."
        fi

        sleep 1
        ((attempt++))
    done

    error "PostgreSQL at $host:$port did not become ready after $max_attempts attempts"
    error "Last error: $output"
    return 1
}

export_field() {
    local qualifier="$1"
    local host="$2"
    local port="$3"
    local user="$4"
    local password="$5"
    local db="$6"
    local output_file
    output_file="$(cd "$OUTPUT_DIR" && pwd)/dc.contributor.${qualifier}.csv"

    log "Exporting dc.contributor.${qualifier}..."

    PGPASSWORD="$password" psql -h "$host" -p "$port" -U "$user" -d "$db" \
        --no-align --tuples-only --quiet \
        -c "\\copy (
WITH fields AS (
  SELECT mfr.metadata_field_id, mfr.element, mfr.qualifier
  FROM metadatafieldregistry mfr
  JOIN metadataschemaregistry msr ON mfr.metadata_schema_id = msr.metadata_schema_id
  WHERE msr.short_id = 'dc'
    AND (
      (mfr.element = 'contributor' AND mfr.qualifier = '${qualifier}')
      OR (mfr.element = 'title' AND mfr.qualifier IS NULL)
      OR (mfr.element = 'type' AND mfr.qualifier IS NULL)
    )
)
SELECT
  i.uuid AS item_uuid,
  mv.text_value AS person_name,
  t.text_value AS item_title,
  ty.text_value AS item_type
FROM metadatavalue mv
JOIN fields cf ON mv.metadata_field_id = cf.metadata_field_id
  AND cf.element = 'contributor'
JOIN item i ON mv.dspace_object_id = i.uuid
LEFT JOIN LATERAL (
  SELECT val.text_value
  FROM metadatavalue val
  WHERE val.dspace_object_id = i.uuid
    AND val.metadata_field_id IN (SELECT metadata_field_id FROM fields WHERE element = 'title')
  ORDER BY val.place LIMIT 1
) t ON true
LEFT JOIN metadatavalue ty ON ty.dspace_object_id = i.uuid
  AND ty.metadata_field_id IN (SELECT metadata_field_id FROM fields WHERE element = 'type')
WHERE i.in_archive = true
ORDER BY mv.text_value, i.uuid
) TO STDOUT WITH CSV HEADER" > "$output_file"

    if [[ -f "$output_file" ]]; then
        local count
        count=$(tail -n +2 "$output_file" | wc -l)
        log "  -> ${output_file} (${count} rows)"
    else
        error "  -> ${output_file} was not created"
        return 1
    fi
}

#######################################
# Main Script
#######################################

main() {
    log "=== DSpace People Export ==="
    log "Pod: $POD_NAME ($NAMESPACE)"
    log "Fields: ${FIELDS[*]}"

    # Check for required tools
    for cmd in kubectl psql; do
        if ! command -v "$cmd" &>/dev/null; then
            error "Required command not found: $cmd"
            exit 1
        fi
    done
    log "Required tools found: kubectl, psql"

    # Create output directory
    mkdir -p "$OUTPUT_DIR"

    # Kill any existing port-forward on our port
    if lsof -ti:"$LOCAL_PORT" &>/dev/null; then
        log "Killing existing process on port $LOCAL_PORT..."
        lsof -ti:"$LOCAL_PORT" | xargs kill 2>/dev/null || true
        sleep 1
    fi

    # Retrieve credentials from pod
    log "Retrieving credentials from pod..."
    DB_USER=$(get_pod_env "$NAMESPACE" "$POD_NAME" "POSTGRES_USER")
    DB_PASSWORD=$(get_pod_env "$NAMESPACE" "$POD_NAME" "POSTGRES_PASSWORD")
    DB_NAME=$(get_pod_env "$NAMESPACE" "$POD_NAME" "POSTGRES_DB")

    if [[ -z "$DB_USER" || -z "$DB_PASSWORD" || -z "$DB_NAME" ]]; then
        error "Failed to retrieve database credentials"
        exit 1
    fi
    log "Database: $DB_NAME (user: $DB_USER)"

    # Start port-forward
    PF_PID=$(start_pf_pod "$NAMESPACE" "$POD_NAME" "$LOCAL_PORT" "$PG_PORT")
    log "Port-forward started (PID: $PF_PID)"

    sleep 2  # Give port-forward time to establish

    # Wait for postgres
    wait_for_postgres "127.0.0.1" "$LOCAL_PORT" "$DB_USER" "$DB_PASSWORD" "$DB_NAME" "$PF_PID"

    # Export each field
    for field in "${FIELDS[@]}"; do
        export_field "$field" "127.0.0.1" "$LOCAL_PORT" "$DB_USER" "$DB_PASSWORD" "$DB_NAME"
    done

    # Summary
    log ""
    log "=== Export Complete ==="
    log "Output directory: $OUTPUT_DIR"
    for field in "${FIELDS[@]}"; do
        local file="${OUTPUT_DIR}/dc.contributor.${field}.csv"
        if [[ -f "$file" ]]; then
            local rows
            rows=$(tail -n +2 "$file" | wc -l)
            log "  dc.contributor.${field}: ${rows} rows"
        fi
    done
}

main "$@"
