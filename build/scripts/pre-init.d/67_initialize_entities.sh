#!/usr/bin/env sh
set -e
FLAG="/dspace/var/entities_initialized"
if [ ! -f "$FLAG" ]; then
  ${DSPACE_BIN} initialize-entities -f ${DSPACE_INSTALL}/config/entities/relationship-types.xml
  mkdir -p /dspace/var
  touch "$FLAG"
fi
