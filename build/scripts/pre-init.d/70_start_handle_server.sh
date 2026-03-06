#!/usr/bin/env sh
set -e
if [ "$DEPLOY_ENV" = "prod" ]; then
  echo "Starting handle server..."
  ${DSPACE_INSTALL}/bin/start-handle-server
fi
