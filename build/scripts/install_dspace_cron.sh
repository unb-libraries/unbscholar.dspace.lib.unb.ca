#!/usr/bin/env sh
$RSYNC_MOVE /scripts/dspace_cron /etc/cron.d/dspace_cron
chmod 644 /etc/cron.d/dspace_cron

# Install and enable cron.
apt-get update
apt-get install cron
rm -rf /var/lib/apt/lists/*
service cron start
