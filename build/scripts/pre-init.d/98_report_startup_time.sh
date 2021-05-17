#!/usr/bin/env bash
START_TIME=$(cat /tmp/start_time)
NOW=$(date +%s)
STARTUP_TIME=$((NOW - START_TIME))
echo "Container startup time : ${STARTUP_TIME}s"
