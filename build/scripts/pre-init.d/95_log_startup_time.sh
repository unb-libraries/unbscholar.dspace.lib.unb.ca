#!/usr/bin/env sh
set -e
START_TIME=$(cat /tmp/start_time)
NOW=$(date +%s)
STARTUP_TIME=$((NOW - START_TIME))
echo "$STARTUP_TIME" > /tmp/startup_time
