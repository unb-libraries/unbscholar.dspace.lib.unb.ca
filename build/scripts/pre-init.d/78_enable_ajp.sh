#!/usr/bin/env sh
if [ "$DEPLOY_ENV" = "prod" ]; then
  echo "Enabling AJP connections."
  sed -i 's|<Connector port="8080"|<Connector protocol="AJP/1.3" address="0.0.0.0" port="8009" redirectPort="8443" secretRequired="false" /><Connector port="8080"|' /usr/local/tomcat/conf/server.xml
fi
