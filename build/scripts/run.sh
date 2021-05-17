#!/usr/bin/env bash
for i in /scripts/pre-init.d/*sh
do
 if [[ -e "${i}" ]]; then
   echo "[i] pre-init.d - processing $i"
   . "${i}"
 fi
done

catalina.sh run
