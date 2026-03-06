#!/usr/bin/env sh
set -e
if [ "$DEPLOY_ENV" = "prod" ]; then
  echo "Enabling Shibboleth Authentication."
  printf "plugin.sequence.org.dspace.authenticate.AuthenticationMethod = org.dspace.authenticate.ShibAuthentication\n" >> "$DSPACE_INSTALL/config/local.cfg"
fi
