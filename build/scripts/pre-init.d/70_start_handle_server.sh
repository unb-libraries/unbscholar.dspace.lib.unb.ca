#!/usr/bin/env sh
if [ "$DEPLOY_ENV" = "prod" ]; then
  echo "Starting handle server..."
  # ${DSPACE_INSTALL}/bin/start-handle-server
fi
