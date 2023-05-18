#!/usr/bin/env sh
CUR_YEAR=$(date +'%Y')
CUR_MONTH=$(date +'%m')
DB_FILE_NAME="dbip-city-lite-$CUR_YEAR-$CUR_MONTH.mmdb"
wget https://download.db-ip.com/free/$DB_FILE_NAME.gz -O /tmp/dbip-city-lite.mmdb.gz
gunzip /tmp/dbip-city-lite.mmdb.gz
mkdir -p /dbip
mv /tmp/dbip-city-lite.mmdb /dbip/dbip-city-lite.mmdb
chmod 755 /dbip/dbip-city-lite.mmdb
