#!/usr/bin/env sh
if [ "$DEPLOY_ENV" == "local" ]; then
  ${DSPACE_BIN} create-administrator -e "${DSPACE_ADMIN_EMAIL}" -f Dspace -l Administrator -c en -p "${DSPACE_ADMIN_PASS}"
fi
