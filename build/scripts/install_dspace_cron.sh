#!/usr/bin/env sh
set -e
# Install and enable cron.
apt update
apt install -y cron
rm -rf /var/lib/apt/lists/*
cat /scripts/dspace_cron >> /etc/crontab
