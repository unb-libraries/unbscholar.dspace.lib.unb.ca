#!/usr/bin/env sh
START_TIME=$(cat /tmp/start_time)
NOW=$(date +%s)
STARTUP_TIME=$(expr $NOW - $START_TIME)
echo "$STARTUP_TIME" > /tmp/startup_time
