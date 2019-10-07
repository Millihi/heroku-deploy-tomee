#!/bin/sh

NAME="${NAME:-"${0##*/}"}"

PING_DELAY="$((15 * 60))"

PINGER_JOB_ID=""

getPingerJobId () {
   echo -n "${PINGER_JOB_ID}"
}

isPingerRunning () {
   if [ -n "${PINGER_JOB_ID}" ]; then
      echo -n "true"
   else
      echo -n ""
   fi
}

startPinger () {
   local -

   set +e

   if [ -z "${PINGER_JOB_ID}" ]; then
      pingerProcess &
      PINGER_JOB_ID="$!"
      echo "${NAME}: Starting Pinger at ${PINGER_JOB_ID}"
   else
      echo "${NAME}: Pinger process ${PINGER_JOB_ID} already running"
   fi
}

stopPinger () {
   local -

   set +e

   if [ -n "${PINGER_JOB_ID}" ]; then
      echo "${NAME}: Killing Pinger job ${PINGER_JOB_ID}"
      kill "${PINGER_JOB_ID}"
      PINGER_JOB_ID=""
   else
      echo "${NAME}: No Pinger process found"
   fi
}

pingerProcess () {
   local -

   set +x

   while true; do
      echo "${name}: Ping host ${APP_HOST}"
      curl --silent -X GET "https://${APP_HOST}/" > /dev/null
      sleep "${PING_DELAY}"
   done
}

checkIntegrity () {
   if [ -z "${APP_HOST}" ]; then
      echo "${NAME}: Error: APP_HOST isn't set."
      exit 1
   fi
}

checkIntegrity
