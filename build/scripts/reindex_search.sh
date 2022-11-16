#!/usr/bin/env sh
curl -X POST -H 'Content-Type: application/json' --data-binary '{"delete":{"query":"*:*" }}' http://unbscholar-solr-lib-unb-ca:8983/solr/search/update
/dspace/bin/dspace index-discovery

