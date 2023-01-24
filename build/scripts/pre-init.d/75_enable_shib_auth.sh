#!/usr/bin/env sh
if [ "$DEPLOY_ENV" = "prod" ]; then
  echo "Enabling Shibboleth Authentication."
  printf "plugin.sequence.org.dspace.authenticate.AuthenticationMethod = org.dspace.authenticate.ShibAuthentication\n" >> "$DSPACE_INSTALL/config/"
fi
