#!/bin/sh

NAME="${NAME:-"${0##*/}"}"
COMMAND="$1"

if [ ! -d "${DERBY_HOME}" ]; then
   echo "${NAME}: Error: DERBY_HOME points to a wrong folder."
   exit 1
fi

if [ ! -d "${JAVA_HOME}" ]; then
   echo "${NAME}: Error: JAVA_HOME points to a wrong folder."
   exit 1
fi

JAVA_CMD="${JAVA_HOME}/bin/java"

if [ ! -f "${JAVA_CMD}" -o ! -r "${JAVA_CMD}" -o ! -x "${JAVA_CMD}" ]; then
   echo "${NAME}: Error: Can not see 'java' in [${JAVA_HOME}/bin]."
   exit 1
fi

SETENV_LIB="${DERBY_HOME}/bin/setenv.sh"

if [ ! -f "${SETENV_LIB}" -o  ! -r "${SETENV_LIB}" ]; then
   echo "${NAME}: Error: Can not see 'setenv.sh' in [${DERBY_HOME}/bin]."
   exit 1
fi

. "${SETENV_LIB}"

cd "${DERBY_HOME}"

controlCommand=""

case "${COMMAND}" in
   [Ss][Tt][Aa][Rr][Tt])
      controlCommand="start"
      ;;
   [Ss][Tt][Oo][Pp])
      controlCommand="shutdown"
      ;;
   *)
      echo "${NAME}: Error: Invalid command '${COMMAND}' given."
      exit 1
      ;;
esac

export CLASSPATH="${DERBY_CLASSPATH}"
"${JAVA_CMD}"
   ${DERBY_OPTS}
   -classpath "${DERBY_CLASSPATH}"
   "org.apache.derby.drda.NetworkServerControl" "${controlCommand}"
