#!/usr/bin/env sh
set -e

CFG="${DSPACE_INSTALL}/config/local.cfg"

# Single sed pass. Longer placeholders are listed before shorter ones that
# share the same prefix to prevent partial matches (e.g. POSTGRES_DB_HOST
# and POSTGRES_DB_PORT before POSTGRES_DB, DSPACE_REST_NAMESPACE before
# DSPACE_REST_HOST).
sed -i \
  -e "s|DSPACE_REST_SSRBASEURL|${DSPACE_REST_SSRBASEURL:-}|g" \
  -e "s|DSPACE_REST_NAMESPACE|${DSPACE_REST_NAMESPACE}|g" \
  -e "s|DSPACE_REST_HOST|${DSPACE_REST_HOST}|g" \
  -e "s|DSPACE_REST_PORT|${DSPACE_REST_PORT}|g" \
  -e "s|DSPACE_GOOGLE_ANALYTICS_KEY|${DSPACE_GOOGLE_ANALYTICS_KEY}|g" \
  -e "s|DSPACE_INSTALL|${DSPACE_INSTALL}|g" \
  -e "s|DSPACE_PROTOCOL|${DSPACE_PROTOCOL}|g" \
  -e "s|DSPACE_URI|${DSPACE_URI}|g" \
  -e "s|POSTGRES_DB_PORT|${POSTGRES_DB_PORT}|g" \
  -e "s|POSTGRES_DB_HOST|${POSTGRES_DB_HOST}|g" \
  -e "s|POSTGRES_PASSWORD|${POSTGRES_PASSWORD}|g" \
  -e "s|POSTGRES_USER|${POSTGRES_USER}|g" \
  -e "s|POSTGRES_DB|${POSTGRES_DB}|g" \
  -e "s|SOLR_PROTOCOL|${SOLR_PROTOCOL}|g" \
  -e "s|SOLR_HOST|${SOLR_HOST}|g" \
  -e "s|SOLR_PATH|${SOLR_PATH}|g" \
  -e "s|SOLR_PORT|${SOLR_PORT}|g" \
  "$CFG"

# If DSPACE_REST_SSRBASEURL was unset/empty, drop the now-valueless line so
# DSpace falls back to its default (${dspace.server.url}). DSpace#9856.
sed -i '/^dspace\.server\.ssr\.url[[:space:]]*=[[:space:]]*$/d' "$CFG"
