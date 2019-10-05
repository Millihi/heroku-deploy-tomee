#!/bin/sh

JAVA_OPTS=""
JAVA_OPTS="${JAVA_OPTS} -Xms32m -Xmx256m -XX:MaxMetaspaceSize=64m"
JAVA_OPTS="${JAVA_OPTS} -XX:+CMSClassUnloadingEnabled"
JAVA_OPTS="${JAVA_OPTS} -XX:+UseCodeCacheFlushing"
JAVA_OPTS="${JAVA_OPTS} -XX:MinHeapFreeRatio=1"
JAVA_OPTS="${JAVA_OPTS} -XX:MaxHeapFreeRatio=1"
JAVA_OPTS="${JAVA_OPTS} -Dsun.io.useCanonCaches=false"
JAVA_OPTS="${JAVA_OPTS} -Djava.awt.headless=true"
JAVA_OPTS="${JAVA_OPTS} -Djava.net.preferIPv4Stack=true"
JAVA_OPTS="${JAVA_OPTS} -Dhttp.port=${PORT:-8080}"
