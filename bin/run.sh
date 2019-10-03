#!/bin/sh
export CATALINA_HOME="/usr/local/tomee"
export CATALINA_BASE="${CATALINA_HOME}"
export JAVA_OPTS="-Dhttp.port=${PORT}"
exec startup.sh

