#!/usr/bin/env sh
# Entrypoint for Kubernetes CronJob pods that share the DSpace image but
# bypass the Tomcat startup path. Renders local.cfg from env vars (same
# substitution the webapp uses) and execs the DSpace CLI.
set -e

/scripts/pre-init.d/40_wait_for_postgres.sh
/scripts/pre-init.d/50_update_dspace_config.sh

exec "${DSPACE_BIN}" "$@"
