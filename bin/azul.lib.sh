#!/bin/sh

__azul_FS=" "
__azul_RS="
"

__azul_JDK_REPO_URL="https://cdn.azul.com/zulu/bin"
__azul_JDK_LIST_URL="https://cdn.azul.com/zulu/bin"
__azul_JDK_LIST=""

__azul_loadListSource () {
   local -

   set +e

   if [ -z "$1" ]
   then
      echo "azul.obtainListSource (url) requires parameter" >&2
      exit 255
   fi

   curl --silent --location "$1" 2>/dev/null \
   | grep -o "href=[\"']\?zulu[^\"'<>[:space:]]\{1,\}" \
   | sed -e "s/^href=[\"']\?//; s/[\"'<>[:space:]].*$//"
}

__azul_loadList () {
   local - file line build type jvm arch record

   set +e

   while read file
   do
      if [ -z "${file}" ]
      then
         continue
      fi

      line="${file#zulu}"
      build="${line%%-*}"
      line="${line#*-}"
      line="${line#ca-}"

      if [ "${line%%-*}" = "fx" -o "${line%%-*}" = "dbg" ]
      then
         continue
      fi

      type="${line}"
      line="${line#???}"
      type="${type%${line}}"
      type="$(echo -n "${type}" | tr "[:lower:]" "[:upper:]")"
      jvm="${line%%-*}"
      line="${line#*-}"
      arch="${line%.tar.gz}"

      record=""
      record="${record}${type}${__azul_FS}"
      record="${record}${build}${__azul_FS}"
      record="${record}${jvm}${__azul_FS}"
      record="${record}${arch}${__azul_FS}"
      record="${record}${file}"

      __azul_JDK_LIST="${__azul_JDK_LIST}${__azul_JDK_LIST:+${__azul_RS}}${record}"
   done \
<<-EOF
   $(__azul_loadListSource "${__azul_JDK_LIST_URL}")
EOF

   if [ -z "${__azul_JDK_LIST}" ]
   then
      echo "azul.loadList (): Unable to load Zulu JVM list" >&2
      exit 255
   fi
}

azul_getUrl () {
   local - \
      type jvm arch jvmP1 jvmP2 \
      _type _build _jvm _arch _file \
      record result

   set +e

   if [ -z "$1" -o -z "$2" -o -z "$3" ]
   then
      echo "azul.getUrl (type, jvm, arch) requires parameter" >&2
      exit 255
   fi

   type="$(echo -n "$1" | tr "[:lower:]" "[:upper:]")"; shift
   jvm="$1"; shift
   arch="$1"; shift

   jvmP1="${jvm}"
   jvmP2="${jvm#1.}"

   while read _type _build _jvm _arch _file
   do
      if [ -z "${_file}" ]
      then
         continue
      fi

      if [ "${_type}" != "${type}" -o "${_arch}" != "${arch}" ]
      then
         continue
      fi

      if [ "${_jvm#${jvmP1}}" = "${_jvm}" -a "${_jvm#${jvmP2}}" = "${_jvm}" ]
      then
         continue
      fi

      record=""
      record="${record}${_jvm}${__azul_FS}"
      record="${record}${_file}"

      result="${result}${result:+${__azul_RS}}${record}"
   done \
<<-EOF
   ${__azul_JDK_LIST}
EOF

   if [ "${result}" ]
   then
      result="$(echo "${result}" | sort -Vbrk 1 | sed -ne "1p")"
   fi

   if [ "${result}" ]
   then
      echo -n "${__azul_JDK_REPO_URL}/${result#*${__azul_FS}}"
   else
      echo -n ""
   fi
}

azul_getFilename () {
   local - url file

   set +e

   if [ -z "$1" ]
   then
      echo "azul.getFilename (url) requires parameter" >&2
      exit 255
   fi

   file="$1"
   file="${file##*/}"
   file="${file%.tar.gz}"

   echo -n "${file}"
}

__azul_loadList
