#!/usr/bin/env bash
set -e

if [ "$DEPLOY_ENV" == "local" ]; then
  mkdir -p /var/solr/data
  for CORE in authority oai qaevent search statistics suggestion
  do
    if [ -d "/data/cores/$CORE" ]; then
      echo "Configuring core $CORE..."
      cp -r "/data/cores/$CORE" "/var/solr/data/$CORE"
        cat > "/var/solr/data/$CORE/core.properties" << EOF
name=$CORE
EOF
    fi
    # solr-precreate $CORE "/var/solr/data/$CORE"
  done

  # Avoid IO race condition if next step is startup.
  sleep 10
fi
