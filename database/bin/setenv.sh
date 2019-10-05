#!/bin/sh

NAME="${NAME:-"${0##*/}"}"

if [ ! -d "${DERBY_HOME}" ]; then
   echo "${NAME}: Error: DERBY_HOME isn't set."
   exit 1
fi

DERBY_DB="${DERBY_HOME}/db"
DERBY_LIB="${DERBY_HOME}/lib"

DERBY_OPTS="-Xms32m -Xmx128m -XX:MaxMetaspaceSize=64m"
DERBY_OPTS="${DERBY_OPTS} -XX:+CMSClassUnloadingEnabled"
DERBY_OPTS="${DERBY_OPTS} -XX:+UseCodeCacheFlushing"
DERBY_OPTS="${DERBY_OPTS} -XX:MinHeapFreeRatio=1"
DERBY_OPTS="${DERBY_OPTS} -XX:MaxHeapFreeRatio=1"
DERBY_OPTS="${DERBY_OPTS} -Dsun.io.useCanonCaches=false"
DERBY_OPTS="${DERBY_OPTS} -Djava.awt.headless=true"
DERBY_OPTS="${DERBY_OPTS} -Djava.net.preferIPv4Stack=true"
DERBY_OPTS="${DERBY_OPTS} -Dderby.system.home=\"${DERBY_DB}\""
DERBY_OPTS="${DERBY_OPTS} -Dderby.install.url=\"${DERBY_LIB}\""
DERBY_OPTS="${DERBY_OPTS} -Dderby.authentication.provider=NATIVE:CredsDB:LOCAL"

DERBY_CLASSPATH="${DERBY_LIB}/lib/derby.jar"
DERBY_CLASSPATH="${DERBY_CLASSPATH}:${DERBY_LIB}/lib/derbyclient.jar"
DERBY_CLASSPATH="${DERBY_CLASSPATH}:${DERBY_LIB}/lib/derbynet.jar"
DERBY_CLASSPATH="${DERBY_CLASSPATH}:${DERBY_LIB}/lib/derbyoptionaltools.jar"
DERBY_CLASSPATH="${DERBY_CLASSPATH}:${DERBY_LIB}/lib/derbyrun.jar"
DERBY_CLASSPATH="${DERBY_CLASSPATH}:${DERBY_LIB}/lib/derbytools.jar"
