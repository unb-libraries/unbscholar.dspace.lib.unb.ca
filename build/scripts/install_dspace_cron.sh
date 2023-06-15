#!/usr/bin/env sh
# Install and enable cron.
apt-get update
apt-get install cron
rm -rf /var/lib/apt/lists/*
cat /scripts/dspace_cron >> /etc/crontab
