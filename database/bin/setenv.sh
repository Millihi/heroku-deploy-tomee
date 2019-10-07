#!/bin/sh

NAME="${NAME:-"${0##*/}"}"

if [ ! -d "${DERBY_HOME}" ]; then
   echo "${NAME}: Error: DERBY_HOME isn't set."
   exit 1
fi

DERBY_DB="${DERBY_HOME}/db"
DERBY_LIB="${DERBY_HOME}/lib"

DERBY_OPTS="${JAVA_OPTS} -Dderby.system.home=${DERBY_DB}"
DERBY_OPTS="${DERBY_OPTS} -Dderby.install.url=${DERBY_LIB}"
DERBY_OPTS="${DERBY_OPTS} -Dderby.authentication.provider=NATIVE:CredsDB:LOCAL"

DERBY_CLASSPATH="${DERBY_LIB}/derby.jar"
DERBY_CLASSPATH="${DERBY_CLASSPATH}:${DERBY_LIB}/derbyclient.jar"
DERBY_CLASSPATH="${DERBY_CLASSPATH}:${DERBY_LIB}/derbynet.jar"
DERBY_CLASSPATH="${DERBY_CLASSPATH}:${DERBY_LIB}/derbyoptionaltools.jar"
DERBY_CLASSPATH="${DERBY_CLASSPATH}:${DERBY_LIB}/derbyrun.jar"
DERBY_CLASSPATH="${DERBY_CLASSPATH}:${DERBY_LIB}/derbytools.jar"
