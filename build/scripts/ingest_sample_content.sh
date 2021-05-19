#!/usr/bin/env sh
AIPZIP='https://github.com/DSpace-Labs/AIP-Files/raw/main/dogAndReport.zip'
AIPDIR='/tmp/aip-dir'

rm -rf ${AIPDIR}
mkdir ${AIPDIR} /dspace/upload
cd "${AIPDIR}" || exit
pwd
curl ${AIPZIP} -L -s --output aip.zip
unzip aip.zip
cd "${AIPDIR}" || exit
${DSPACE_BIN} packager -r -a -t AIP -e "${DSPACE_ADMIN_EMAIL}" -f -u SITE*.zip
${DSPACE_BIN} database update-sequences
touch /dspace/solr/search/conf/reindex.flag
${DSPACE_BIN} oai import
${DSPACE_BIN} oai clean-cache
