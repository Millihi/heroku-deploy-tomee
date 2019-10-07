#!/bin/sh

NAME="${NAME:-"${0##*/}"}"

if [ ! -d "${CATALINA_HOME}" ]; then
   echo "${NAME}: Error: CATALINA_HOME isn't set."
   exit 1
fi

JAVA_OPTS="${JAVA_OPTS} -Dhttp.port=${PORT:-8080}"
