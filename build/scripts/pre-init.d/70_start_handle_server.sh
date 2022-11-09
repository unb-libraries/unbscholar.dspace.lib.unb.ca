#!/usr/bin/env sh
if [ "$DEPLOY_ENV" != "local" ]; then
  # Disable until handle enables account
  # ${DSPACE_INSTALL}/bin/start-handle-server
  echo "Handle server disabled temporarily."
fi
