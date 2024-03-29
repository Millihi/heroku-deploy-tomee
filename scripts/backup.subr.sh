#!/bin/sh

NAME="${NAME:-"${0##*/}"}"

###############################################################################
##  Package section                                                          ##
###############################################################################

__backup_MAX_WAIT_TIME="360"
__backup_MAX_RETRIES="100"

__backup_TAR_FILE_PATH="/JavaDB_Backups/state.tar"
__backup_LOGS_FILE_PATH="/JavaDB_Backups/logs.tar"
__backup_LOCK_FILE_PATH="/JavaDB_Backups/state.lock"

__backup_WEBAPPS_DIR="${CATALINA_HOME##*/}/webapps"
__backup_LOGS_DIR="${CATALINA_HOME##*/}/logs"
__backup_DBS_DIR="${DERBY_HOME##*/}/db"

__backup_obtained=""

###############################################################################
##  Public section                                                           ##
###############################################################################

backup_obtain () {
   local - waitTime attempts

   set +e

   if [ "${__backup_obtained}" ]
   then
      echo "${NAME}: The backup is already obtained, do nothing."
   else
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

      __backup_load &&
      __backup_lock &&
      __backup_obtained="true"
   fi
}

backup_release () {
   local -

   set +e

   if [ "${__backup_obtained}" ]
   then
      echo "${NAME}: An attemp to releasing backup is started."
      __backup_save &&
      __backup_unlock &&
      __backup_obtained=""
   else
      echo "${NAME}: No backup obtained, nothing to release."
   fi
}

###############################################################################
##  Private section                                                          ##
###############################################################################

__backup_save () {
   local - result

   set +e

   echo -n "${NAME}: Saving backup... "

   tar \
      -cf - \
      -C "${HOME}" \
      "${__backup_DBS_DIR}" \
      "${__backup_WEBAPPS_DIR}/"*.war \
      2>/dev/null \
   | curl \
      --silent \
      --retry "${__backup_MAX_RETRIES}" \
      -X POST https://content.dropboxapi.com/2/files/upload \
      --header "$(__backup_getAuthHeader)" \
      --header "Dropbox-API-Arg: { \"path\": \"${__backup_TAR_FILE_PATH}\", \"mode\": \"overwrite\" }" \
      --header "Content-Type: application/octet-stream" \
      --data-binary @- \
      2>&1 >/dev/null

   result="$?"

   tar \
      -cf - \
      -C "${HOME}" \
      "${__backup_LOGS_DIR}" \
      2>/dev/null \
   | curl \
      --silent \
      -X POST https://content.dropboxapi.com/2/files/upload \
      --header "$(__backup_getAuthHeader)" \
      --header "Dropbox-API-Arg: { \"path\": \"${__backup_LOGS_FILE_PATH}\", \"mode\": \"overwrite\" }" \
      --header "Content-Type: application/octet-stream" \
      --data-binary @- \
      2>&1 >/dev/null

   if [ "${result}" -eq "0" ]
   then
      echo "DONE"
   else
      echo "FAIL"
   fi

   return "${result}"
}

__backup_load () {
   local - result

   set +e

   echo -n "${NAME}: Loading backup... "

   curl \
      --silent \
      --retry "${__backup_MAX_RETRIES}" \
      -X POST https://content.dropboxapi.com/2/files/download \
      --header "$(__backup_getAuthHeader)" \
      --header "Dropbox-API-Arg: { \"path\": \"${__backup_TAR_FILE_PATH}\" }" \
      2>/dev/null \
   | tar \
      -xf - \
      -C "${HOME}" \
      2>&1 >/dev/null

   result="$?"

   if [ "${result}" -eq "0" ]
   then
      echo "DONE"
   else
      echo "FAIL"
   fi

   return "${result}"
}

__backup_lock () {
   local - result

   set +e

   echo -n "${NAME}: Locking backup... "

   echo \
      "$(__backup_getTimestamp)" \
      2>/dev/null \
   | curl \
      --silent \
      --retry "${__backup_MAX_RETRIES}" \
      -X POST https://content.dropboxapi.com/2/files/upload \
      --header "$(__backup_getAuthHeader)" \
      --header "Dropbox-API-Arg: { \"path\": \"${__backup_LOCK_FILE_PATH}\", \"mode\": \"add\" }" \
      --header "Content-Type: application/octet-stream" \
      --data-binary @- \
      2>&1 >/dev/null

   result="$?"

   if [ "${result}" -eq "0" ]
   then
      echo "DONE"
   else
      echo "FAIL"
   fi

   return "${result}"
}

__backup_unlock () {
   local - result

   set +e

   echo -n "${NAME}: Unlocking backup... "

   curl \
      --silent \
      --retry "${__backup_MAX_RETRIES}" \
      -X POST https://api.dropboxapi.com/2/files/delete_v2 \
      --header "$(__backup_getAuthHeader)" \
      --header "Content-Type: application/json" \
      --data "{ \"path\": \"${__backup_LOCK_FILE_PATH}\" }" \
      2>&1 >/dev/null

   result="$?"

   if [ "${result}" -eq "0" ]
   then
      echo "DONE"
   else
      echo "FAIL"
   fi

   return "${result}"
}

__backup_isLocked () {
   local - result

   set +e

   if [ "$(__backup_getLockState)" ]
   then
      echo -n ""
   else
      echo -n "true"
   fi
}

__backup_getLockState () {
   local -

   set +e

   curl \
      --silent \
      --retry "${__backup_MAX_RETRIES}" \
      -X POST https://content.dropboxapi.com/2/files/download \
      --header "$(__backup_getAuthHeader)" \
      --header "Dropbox-API-Arg: { \"path\": \"${__backup_LOCK_FILE_PATH}\" }" \
      2>/dev/null \
   | sed \
      -ne '/error_summary.\{1,\}not_found/p' \
      2>/dev/null
}

__backup_getTimestamp () {
   echo -n "$(date +"%s")"
}

__backup_getAuthHeader () {
   echo -n "Authorization: Bearer $(private_getDropboxAuthToken)"
}

__backup_checkIntegrity () {
   local webappsPath dbsPath

   webappsPath="${HOME}/${__backup_WEBAPPS_DIR}"
   logsPath="${HOME}/${__backup_LOGS_DIR}"
   dbsPath="${HOME}/${__backup_DBS_DIR}"

   if [ ! -d "${webappsPath}" ]
   then
      echo "${NAME}: Error: TomEE webapps not found in [${webappsPath}]."
      exit 1
   fi

   if [ ! -d "${logsPath}" ]
   then
      echo "${NAME}: Error: TomEE logs not found in [${logsPath}]."
      exit 1
   fi

   if [ ! -d "${dbsPath}" ]
   then
      echo "${NAME}: Error: Derby databases not found in [${dbsPath}]."
      exit 1
   fi
}

###############################################################################
##  Body section                                                             ##
###############################################################################

__backup_checkIntegrity
