#!/bin/sh

NAME="${NAME:-"${0##*/}"}"

__backup_MAX_WAIT_TIME="360"
__backup_MAX_RETRIES="100"

__backup_TAR_FILE_PATH="/JavaDB_Backups/state.tar"
__backup_LOCK_FILE_PATH="/JavaDB_Backups/state.lock"

__backup_WEBAPPS_DIR="${CATALINA_HOME##*/}/webapps"
__backup_DBS_DIR="${DERBY_HOME##*/}/db"

backup_obtain () {
   local - waitTime attempts

   set +e

   echo "${NAME}: An attemp to obtaining backup is started."

   waitTime=1
   attempts=0

   while [ "$(__backup_isLocked)" ]
   do
      echo "${NAME}: State is locked, waiting."

      if [ $attempts -ge $waitTime ]
      then
         attempts=0

         if [ $((2 * $waitTime)) -lt $__backup_MAX_WAIT_TIME ]
         then
            waitTime=$((2 * $waitTime))
         fi
      else
         attempts=$(($attempts + 1))
      fi

      sleep $waitTime
   done

   __backup_load
   __backup_lock
}

backup_release () {
   local -

   set +e

   echo "${NAME}: An attemp to releasing backup is started."

   __backup_save
   __backup_unlock
}

__backup_save () {
   local -

   set -e

   tar \
      -cf - \
      -C "${HOME}" \
      "${__backup_DBS_DIR}" \
      "${__backup_WEBAPPS_DIR}/"*.war \
   | curl \
      --silent \
      --retry "${__backup_MAX_RETRIES}" \
      -X POST https://content.dropboxapi.com/2/files/upload \
      --header "$(__backup_getAuthHeader)" \
      --header "Dropbox-API-Arg: { \"path\": \"${__backup_TAR_FILE_PATH}\", \"mode\": \"overwrite\" }" \
      --header "Content-Type: application/octet-stream" \
      --data-binary @-
}

__backup_load () {
   local -

   set -e

   curl \
      --silent \
      --retry "${__backup_MAX_RETRIES}" \
      -X POST https://content.dropboxapi.com/2/files/download \
      --header "$(__backup_getAuthHeader)" \
      --header "Dropbox-API-Arg: { \"path\": \"${__backup_TAR_FILE_PATH}\" }" \
   | tar \
      -xf - \
      -C "${HOME}"
}

__backup_lock () {
   local -

   set -e

   echo \
      "$(__backup_getTimestamp)" \
   | curl \
      --silent \
      --retry "${__backup_MAX_RETRIES}" \
      -X POST https://content.dropboxapi.com/2/files/upload \
      --header "$(__backup_getAuthHeader)" \
      --header "Dropbox-API-Arg: { \"path\": \"${__backup_LOCK_FILE_PATH}\", \"mode\": \"add\" }" \
      --header "Content-Type: application/octet-stream" \
      --data-binary @-
}

__backup_unlock () {
   local -

   set -e

   curl \
      --silent \
      --retry "${__backup_MAX_RETRIES}" \
      -X POST https://api.dropboxapi.com/2/files/delete_v2 \
      --header "$(__backup_getAuthHeader)" \
      --header "Content-Type: application/json" \
      --data "{ \"path\": \"${__backup_LOCK_FILE_PATH}\" }"
}

__backup_isLocked () {
   local - result

   set +e -x

   if [ "$(__backup_getLockState)" ]
   then
      echo -n ""
   else
      echo -n "true"
   fi
}

__backup_getLockState () {
   local -

   set +e -x

   echo -n "$( \
      curl \
         --silent \
         --retry "${__backup_MAX_RETRIES}" \
         -X POST https://content.dropboxapi.com/2/files/download \
         --header "$(__backup_getAuthHeader)" \
         --header "Dropbox-API-Arg: { \"path\": \"${__backup_LOCK_FILE_PATH}\" }" \
         2 > /dev/null \
      | sed \
         -ne '/error_summary.\{1,\}not_found/p' \
   )"
}

__backup_getTimestamp () {
   echo -n "$(date +"%s")"
}

__backup_getAuthHeader () {
   echo -n "Authorization: Bearer $(getAuthToken)"
}

__backup_checkIntegrity () {
   local webappsPath dbsPath

   webappsPath="${HOME}/${__backup_WEBAPPS_DIR}"
   dbsPath="${HOME}/${__backup_DBS_DIR}"

   if [ ! -d "${webappsPath}" ]
   then
      echo "${NAME}: Error: TomEE webapps not found in [${webappsPath}]."
      exit 1
   fi

   if [ ! -d "${dbsPath}" ]
   then
      echo "${NAME}: Error: Derby databases not found in [${dbsPath}]."
      exit 1
   fi
}

__backup_checkIntegrity
