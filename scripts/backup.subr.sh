#!/bin/sh

NAME="${NAME:-"${0##*/}"}"

MAX_RETRIES="100"
TAR_FILE_PATH="/JavaDB_Backups/state.tar"
LOCK_FILE_PATH="/JavaDB_Backups/state.lock"

WEBAPPS_DIR="${CATALINA_HOME##*/}/webapps"
DBS_DIR="${DERBY_HOME##*/}/db"

getTimestamp () {
   echo -n "$(date +"%s")"
}

getAuthHeader () {
   echo -n "Authorization: Bearer $(getAuthToken)"
}

obtainState () {
   local - waitTime maxWaitTime attempts

   set -e

   maxWaitTime=360
   waitTime=1
   attempts=0

   while [ -n "$(isStateLocked)" ]; do
      echo "${NAME}: State is locked, waiting."

      if [ $attempts -ge $waitTime ]; then
         attempts=0

         if [ $((2 * $waitTime)) -lt $maxWaitTime ]; then
            waitTime=$((2 * $waitTime))
         fi
      else
         attempts=$(($attempts + 1))
      fi

      sleep $waitTime
   done

   loadState
   lockState
}

releaseState () {
   local -

   set -e

   saveState
   unlockState
}

saveState () {
   local -

   set -e

   tar -cf - -C "${HOME}" "${DBS_DIR}" "${WEBAPPS_DIR}/"*.war | \
      curl \
         --silent \
         --retry "${MAX_RETRIES}" \
         -X POST https://content.dropboxapi.com/2/files/upload \
         --header "$(getAuthHeader)" \
         --header "Dropbox-API-Arg: { \"path\": \"${TAR_FILE_PATH}\", \"mode\": \"overwrite\" }" \
         --header "Content-Type: application/octet-stream" \
         --data-binary @-
}

loadState () {
   local -

   set -e

   curl \
      --silent \
      --retry "${MAX_RETRIES}" \
      -X POST https://content.dropboxapi.com/2/files/download \
      --header "$(getAuthHeader)" \
      --header "Dropbox-API-Arg: { \"path\": \"${TAR_FILE_PATH}\" }" | \
      tar -xf - -C "${HOME}"
}

lockState () {
   local -

   set -e

   echo "$(getTimestamp)" | \
      curl \
         --silent \
         --retry "${MAX_RETRIES}" \
         -X POST https://content.dropboxapi.com/2/files/upload \
         --header "$(getAuthHeader)" \
         --header "Dropbox-API-Arg: { \"path\": \"${LOCK_FILE_PATH}\", \"mode\": \"add\" }" \
         --header "Content-Type: application/octet-stream" \
         --data-binary @-
}

unlockState () {
   local -

   set -e

   curl \
      --silent \
      --retry "${MAX_RETRIES}" \
      -X POST https://api.dropboxapi.com/2/files/delete_v2 \
      --header "$(getAuthHeader)" \
      --header "Content-Type: application/json" \
      --data "Dropbox-API-Arg: { \"path\": \"${LOCK_FILE_PATH}\" }"
}

isStateLocked () {
   local - result

   set -e

   result="$(curl \
      --silent \
      --retry "${MAX_RETRIES}" \
      -X POST https://content.dropboxapi.com/2/files/download \
      --header "$(getAuthHeader)" \
      --header "Dropbox-API-Arg: { \"path\": \"${LOCK_FILE_PATH}\" }" | \
      sed -ne '/error_summary/p')"

   if [ -z "${result}" ]; then
      echo -n "true"
   else
      echo -n ""
   fi
}

checkIntegrity () {
   local webappsPath dbsPath

   webappsPath="${HOME}/${WEBAPPS_DIR}"
   dbsPath="${HOME}/${DBS_DIR}"

   if [ ! -d "${webappsPath}" ]; then
      echo "${NAME}: Error: TomEE webapps not found in [${webappsPath}]."
      exit 1
   fi

   if [ ! -d "${dbsPath}" ]; then
      echo "${NAME}: Error: Derby databases not found in [${dbsPath}]."
      exit 1
   fi
}

checkIntegrity
