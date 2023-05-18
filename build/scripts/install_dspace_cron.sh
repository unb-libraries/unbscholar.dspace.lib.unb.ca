#!/usr/bin/env sh
# Install and enable cron.
apt-get update
apt-get install cron
rm -rf /var/lib/apt/lists/*

mkdir -p /etc/cron.d/
$RSYNC_MOVE /scripts/dspace_cron /etc/cron.d/dspace_cron
chmod 644 /etc/cron.d/dspace_cron

service cron start
