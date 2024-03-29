#!/usr/bin/env sh
sed -i "s|DSPACE_INSTALL|${DSPACE_INSTALL}|g" "${DSPACE_INSTALL}/config/local.cfg"
sed -i "s|DSPACE_URI|${DSPACE_URI}|g" "${DSPACE_INSTALL}/config/local.cfg"
sed -i "s|DSPACE_PROTOCOL|${DSPACE_PROTOCOL}|g" "${DSPACE_INSTALL}/config/local.cfg"
sed -i "s|POSTGRES_DB_PORT|${POSTGRES_DB_PORT}|g" "${DSPACE_INSTALL}/config/local.cfg"
sed -i "s|POSTGRES_DB_HOST|${POSTGRES_DB_HOST}|g" "${DSPACE_INSTALL}/config/local.cfg"
sed -i "s|POSTGRES_PASSWORD|${POSTGRES_PASSWORD}|g" "${DSPACE_INSTALL}/config/local.cfg"
sed -i "s|POSTGRES_USER|${POSTGRES_USER}|g" "${DSPACE_INSTALL}/config/local.cfg"
sed -i "s|POSTGRES_DB|${POSTGRES_DB}|g" "${DSPACE_INSTALL}/config/local.cfg"
sed -i "s|SOLR_HOST|${SOLR_HOST}|g" "${DSPACE_INSTALL}/config/local.cfg"
sed -i "s|SOLR_PATH|${SOLR_PATH}|g" "${DSPACE_INSTALL}/config/local.cfg"
sed -i "s|SOLR_PORT|${SOLR_PORT}|g" "${DSPACE_INSTALL}/config/local.cfg"
sed -i "s|SOLR_PROTOCOL|${SOLR_PROTOCOL}|g" "${DSPACE_INSTALL}/config/local.cfg"
sed -i "s|DSPACE_GOOGLE_ANALYTICS_KEY|${DSPACE_GOOGLE_ANALYTICS_KEY}|g" "${DSPACE_INSTALL}/config/local.cfg"
sed -i "s|DSPACE_REST_NAMESPACE|${DSPACE_REST_NAMESPACE}|g" "${DSPACE_INSTALL}/config/local.cfg"
sed -i "s|DSPACE_REST_PORT|${DSPACE_REST_PORT}|g" "${DSPACE_INSTALL}/config/local.cfg"
sed -i "s|DSPACE_REST_HOST|${DSPACE_REST_HOST}|g" "${DSPACE_INSTALL}/config/local.cfg"
