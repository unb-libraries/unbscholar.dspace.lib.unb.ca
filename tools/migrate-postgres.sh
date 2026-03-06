#!/usr/bin/env bash
#
# PostgreSQL K8s Pod Migration Script
# Migrates a PostgreSQL database between Kubernetes pods using pg_dump and psql
#

set -euo pipefail

#######################################
# Configuration
#######################################

# Source pod configuration
SOURCE_POD="unbscholar-postgres-lib-unb-ca-5cd66794ff-zk2mw"
SOURCE_NAMESPACE="prod"
SOURCE_LOCAL_PORT=15432

# Target pod configuration
TARGET_POD="unbscholar-postgres-lib-unb-ca-68594fc58d-v8gdn"
TARGET_NAMESPACE="newscholar"
TARGET_LOCAL_PORT=15433

# PostgreSQL port inside the pods
PG_PORT=5432

# Dumps directory
DUMPS_DIR="${DUMPS_DIR:-./dumps}"
DUMP_FILE="${DUMPS_DIR}/postgres_dump_$(date +%Y%m%d_%H%M%S).sql"

# Port-forward PIDs
SOURCE_PF_PID=""
TARGET_PF_PID=""

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
    log "Cleaning up port-forwards..."
    if [[ -n "$SOURCE_PF_PID" ]] && kill -0 "$SOURCE_PF_PID" 2>/dev/null; then
        kill "$SOURCE_PF_PID" 2>/dev/null || true
        log "Stopped source port-forward (PID: $SOURCE_PF_PID)"
    fi
    if [[ -n "$TARGET_PF_PID" ]] && kill -0 "$TARGET_PF_PID" 2>/dev/null; then
        kill "$TARGET_PF_PID" 2>/dev/null || true
        log "Stopped target port-forward (PID: $TARGET_PF_PID)"
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
    local log_file="${DUMPS_DIR}/pf_${local_port}.log"

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
        # Check if port-forward is still running
        if ! kill -0 "$pf_pid" 2>/dev/null; then
            error "Port-forward process (PID: $pf_pid) died unexpectedly"
            local log_file="${DUMPS_DIR}/pf_${port}.log"
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

pg_dump_cli() {
    local host="$1"
    local port="$2"
    local user="$3"
    local password="$4"
    local db="$5"
    local output="$6"

    PGPASSWORD="$password" pg_dump \
        -h "$host" \
        -p "$port" \
        -U "$user" \
        -d "$db" \
        --clean \
        --if-exists \
        --no-owner \
        --no-acl \
        --format=plain \
        --encoding=UTF8 \
        -f "$output"
}

psql_cli() {
    local host="$1"
    local port="$2"
    local user="$3"
    local password="$4"
    local db="$5"
    local input="$6"

    PGPASSWORD="$password" psql \
        -h "$host" \
        -p "$port" \
        -U "$user" \
        -d "$db" \
        -v ON_ERROR_STOP=1 \
        -f "$input"
}

#######################################
# Main Script
#######################################

main() {
    log "=== PostgreSQL K8s Pod Migration ==="
    log "Source: $SOURCE_POD ($SOURCE_NAMESPACE)"
    log "Target: $TARGET_POD ($TARGET_NAMESPACE)"

    # Create dumps directory (needed early for port-forward logs)
    mkdir -p "$DUMPS_DIR"

    # Check for required tools
    for cmd in kubectl psql pg_dump; do
        if ! command -v "$cmd" &>/dev/null; then
            error "Required command not found: $cmd"
            exit 1
        fi
    done
    log "Required tools found: kubectl, psql, pg_dump"

    # Kill any existing port-forwards on our ports
    for port in "$SOURCE_LOCAL_PORT" "$TARGET_LOCAL_PORT"; do
        if lsof -ti:"$port" &>/dev/null; then
            log "Killing existing process on port $port..."
            lsof -ti:"$port" | xargs kill 2>/dev/null || true
            sleep 1
        fi
    done

    # Retrieve credentials from source pod
    log "Retrieving credentials from source pod..."
    SOURCE_USER=$(get_pod_env "$SOURCE_NAMESPACE" "$SOURCE_POD" "POSTGRES_USER")
    SOURCE_PASSWORD=$(get_pod_env "$SOURCE_NAMESPACE" "$SOURCE_POD" "POSTGRES_PASSWORD")
    SOURCE_DB=$(get_pod_env "$SOURCE_NAMESPACE" "$SOURCE_POD" "POSTGRES_DB")

    if [[ -z "$SOURCE_USER" || -z "$SOURCE_PASSWORD" || -z "$SOURCE_DB" ]]; then
        error "Failed to retrieve source credentials"
        exit 1
    fi
    log "Source database: $SOURCE_DB (user: $SOURCE_USER)"

    # Retrieve credentials from target pod
    log "Retrieving credentials from target pod..."
    TARGET_USER=$(get_pod_env "$TARGET_NAMESPACE" "$TARGET_POD" "POSTGRES_USER")
    TARGET_PASSWORD=$(get_pod_env "$TARGET_NAMESPACE" "$TARGET_POD" "POSTGRES_PASSWORD")
    TARGET_DB=$(get_pod_env "$TARGET_NAMESPACE" "$TARGET_POD" "POSTGRES_DB")

    if [[ -z "$TARGET_USER" || -z "$TARGET_PASSWORD" || -z "$TARGET_DB" ]]; then
        error "Failed to retrieve target credentials"
        exit 1
    fi
    log "Target database: $TARGET_DB (user: $TARGET_USER)"

    # Start port-forwards
    SOURCE_PF_PID=$(start_pf_pod "$SOURCE_NAMESPACE" "$SOURCE_POD" "$SOURCE_LOCAL_PORT" "$PG_PORT")
    log "Source port-forward started (PID: $SOURCE_PF_PID)"

    TARGET_PF_PID=$(start_pf_pod "$TARGET_NAMESPACE" "$TARGET_POD" "$TARGET_LOCAL_PORT" "$PG_PORT")
    log "Target port-forward started (PID: $TARGET_PF_PID)"

    # Wait for connections to be ready
    sleep 2  # Give port-forwards time to establish

    wait_for_postgres "127.0.0.1" "$SOURCE_LOCAL_PORT" "$SOURCE_USER" "$SOURCE_PASSWORD" "$SOURCE_DB" "$SOURCE_PF_PID"
    wait_for_postgres "127.0.0.1" "$TARGET_LOCAL_PORT" "$TARGET_USER" "$TARGET_PASSWORD" "$TARGET_DB" "$TARGET_PF_PID"

    # Dump source database
    log "Dumping source database to $DUMP_FILE..."
    pg_dump_cli "127.0.0.1" "$SOURCE_LOCAL_PORT" "$SOURCE_USER" "$SOURCE_PASSWORD" "$SOURCE_DB" "$DUMP_FILE"

    DUMP_SIZE=$(du -h "$DUMP_FILE" | cut -f1)
    log "Dump completed: $DUMP_FILE ($DUMP_SIZE)"

    # Restore to target database
    log "Restoring to target database..."
    psql_cli "127.0.0.1" "$TARGET_LOCAL_PORT" "$TARGET_USER" "$TARGET_PASSWORD" "$TARGET_DB" "$DUMP_FILE"
    log "Restore completed successfully"

    log "=== Migration Complete ==="
    log ""
    log "Verification commands:"
    log "  # List tables in target:"
    log "  kubectl exec -n $TARGET_NAMESPACE $TARGET_POD -- psql -U $TARGET_USER -d $TARGET_DB -c '\\dt'"
    log ""
    log "  # Compare row counts (example for a table):"
    log "  kubectl exec -n $SOURCE_NAMESPACE $SOURCE_POD -- psql -U $SOURCE_USER -d $SOURCE_DB -c 'SELECT COUNT(*) FROM <table_name>;'"
    log "  kubectl exec -n $TARGET_NAMESPACE $TARGET_POD -- psql -U $TARGET_USER -d $TARGET_DB -c 'SELECT COUNT(*) FROM <table_name>;'"
}

main "$@"
