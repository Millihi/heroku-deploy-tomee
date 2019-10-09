#!/bin/sh

NAME="${NAME:-"${0##*/}"}"

###############################################################################
##  Package section                                                          ##
###############################################################################

__pinger_PING_DELAY="$((15 * 60))"

__pinger_JOB_ID=""

###############################################################################
##  Public section                                                           ##
###############################################################################

pinger_getJobId () {
   echo -n "${__pinger_JOB_ID}"
}

pinger_isRunning () {
   if [ "${__pinger_JOB_ID}" ]
   then
      echo -n "true"
   else
      echo -n ""
   fi
}

pinger_start () {
   local -

   set +e

   if [ -z "${__pinger_JOB_ID}" ]
   then
      __pinger_process &
      __pinger_JOB_ID="$!"
      echo "${NAME}: Starting Pinger at ${__pinger_JOB_ID}"
   else
      echo "${NAME}: Pinger process ${__pinger_JOB_ID} already running"
   fi
}

pinger_stop () {
   local -

   set +e

   if [ "${__pinger_JOB_ID}" ]
   then
      echo "${NAME}: Killing Pinger job ${__pinger_JOB_ID}"
      kill "${__pinger_JOB_ID}" 2>&1 >/dev/null
      __pinger_JOB_ID=""
   else
      echo "${NAME}: No Pinger process found"
   fi
}

###############################################################################
##  Private section                                                          ##
###############################################################################

__pinger_process () {
   local -

   set +e

   while true
   do
      echo "${NAME}: Ping host ${APP_HOST}"
      curl --silent -X GET "https://${APP_HOST}/" >/dev/null 2>&1
      sleep "${__pinger_PING_DELAY}"
   done
}

__pinger_checkIntegrity () {
   if [ -z "${APP_HOST}" ]
   then
      echo "${NAME}: Error: APP_HOST isn't set."
      exit 1
   fi
}

###############################################################################
##  Body section                                                             ##
###############################################################################

__pinger_checkIntegrity
