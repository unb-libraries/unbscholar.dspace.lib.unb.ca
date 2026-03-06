#!/usr/bin/env sh
set -e
printenv > /etc/environment
service cron start
crontab /etc/crontab
