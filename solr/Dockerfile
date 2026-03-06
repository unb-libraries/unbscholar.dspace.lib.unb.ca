FROM ghcr.io/unb-libraries/unbscholar.solr.lib.unb.ca:9.x

ENV SOLR_OPTS="-Dsolr.config.lib.enabled=true"

COPY build/scripts/pre-init.d/40_create_solr_cores.sh /scripts/pre-init.d/
COPY build/data /data

