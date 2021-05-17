#!/usr/bin/env bash
set -e

if [ "$DEPLOY_ENV" == "local" ]; then
  for CORE in authority oai search statistics
  do
    echo "Creating Core $CORE..."
    /opt/docker-solr/scripts/precreate-core $CORE "/data/cores/$CORE"
  done

  # Avoid IO race condition if next step is startup.
  sleep 10
fi
