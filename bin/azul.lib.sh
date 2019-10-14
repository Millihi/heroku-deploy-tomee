#!/bin/sh

__azul_RS="
"
__azul_FS=" "

__azul_JDK_REPO_URL="https://cdn.azul.com/zulu/bin"
__azul_JDK_LIST_URL="https://cdn.azul.com/zulu/bin"
__azul_JDK_LIST=""

__azul_loadListSource () {
   local - url

   set -e

   if [ -z "$1" ]
   then
      echo "azul.obtainListSource (url) requires parameter"
      exit 255
   fi

   url="$1"; shift

   curl --silent --location "${url}" 2>/dev/null \
   | grep -o "href=[\"']\?zulu[^>]\{1,\}\.tar\.gz" \
   | sed -e "s/^href=[\"']\?//"
}

__azul_loadList () {
   local - file line build type jvm arch record

   set -e

   while read file
   do
      if [ -z "${file}" ]
      then
         continue
      fi

      line="${file#zulu}"
      build="${line%%-*}"
      line="${line#*-}"

      if [ "${line%%-*}" != "ca" ]
      then
         continue
      fi

      line="${line#*-}"

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

      record="${type}${__azul_FS}"
      record="${record}${build}${__azul_FS}"
      record="${record}${jvm}${__azul_FS}"
      record="${record}${arch}${__azul_FS}"
      record="${record}${file}"

      if [ "${__azul_JDK_LIST}" ]
      then
         __azul_JDK_LIST="${__azul_JDK_LIST}${__azul_RS}"
      fi

      __azul_JDK_LIST="${__azul_JDK_LIST}${record}"
   done \
<<-EOF
   $(__azul_loadListSource "${__azul_JDK_LIST_URL}")
EOF

   if [ -z "${__azul_JDK_LIST}" ]
   then
      echo "__azul_loadList (): Unable to load Zulu JVM list"
      exit 255
   fi
}

azul_getUrl () {
   local - type jvm arch _type _build _jvm _arch _file record result

   set -e

   if [ -z "$1" -o -z "$2" -o -z "$3" ]
   then
      echo "azul.getUrl (type, jvm, arch) requires parameter"
      exit 1
   fi

   type="$(echo -n "$1" | tr "[:lower:]" "[:upper:]")"; shift
   jvm="$1"; shift
   arch="$1"; shift

   set +e

   while read _type _build _jvm _arch _file
   do
      if [ "${_file}" -a "${_type}" = "${type}" -a "${_arch}" = "${arch}" ]
      then
         record="${_jvm}${__azul_FS}"
         record="${record}${_file}"

         if [ "${result}" ]
         then
            result="${result}${__azul_RS}"
         fi

         result="${result}${record}"
      fi
   done \
<<-EOF
   ${__azul_JDK_LIST}
EOF

   if [ "${result}" ]
   then
      result="$(\
         echo "${result}" \
         | sed -ne "/^${jvm#1.}/p; /^${jvm}/p" \
         | sort -brk 1 \
         | sed -ne "1p" \
      )"
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

   set -e

   if [ -z "$1" ]
   then
      echo "azul.getFilename (url) requires parameter"
      exit 255
   fi

   url="$1"; shift

   set +e

   file="${url}"
   file="${file##*/}"
   file="${file%.tar.gz}"

   echo -n "${file}"
}

__azul_loadList

echo "$(azul_getUrl "JDK" "1.8" "linux_x64")"
echo "$(azul_getFilename "$(azul_getUrl "JDK" "1.8" "linux_x64")")"
