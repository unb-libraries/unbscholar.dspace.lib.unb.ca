#!/usr/bin/env sh
if [ "$DEPLOY_ENV" == "local" ]; then
  /scripts/ingest_sample_content.sh
fi
