#!/usr/bin/env bash
printenv > /etc/environment
service cron start
crontab /etc/crontab
