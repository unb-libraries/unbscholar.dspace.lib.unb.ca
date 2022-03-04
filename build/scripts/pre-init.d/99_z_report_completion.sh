#!/usr/bin/env sh
STARTUP_TIME=$(cat /tmp/startup_time)
printf "\nDeployment Complete!\n\n> Step Times:\n"
column /tmp/deploy_step_times -t -s "|"
printf "\n"
printf "> Total Container Startup Time: ${STARTUP_TIME}s"
printf "\n"
