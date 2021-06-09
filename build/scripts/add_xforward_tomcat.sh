#!/usr/bin/env sh
#
# Adds incoming X-Forwarded-Proto and X-Forwarded-For values to tomcat app headers.
sed -i 's|</Host>|<Valve className="org.apache.catalina.valves.RemoteIpValve" remoteIpHeader="X-Forwarded-For" protocolHeader="X-Forwarded-Proto"/></Host>|' /usr/local/tomcat/conf/server.xml
