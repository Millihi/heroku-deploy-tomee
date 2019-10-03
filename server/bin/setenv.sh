#!/bin/sh
export JAVA_OPTS="${JAVA_OPTS} -Xms32m -Xmx256m -XX:MaxMetaspaceSize=64m"
export JAVA_OPTS="${JAVA_OPTS} -XX:+CMSClassUnloadingEnabled -XX:+UseCodeCacheFlushing"
export JAVA_OPTS="${JAVA_OPTS} -XX:MinHeapFreeRatio=1 -XX:MaxHeapFreeRatio=1"
export JAVA_OPTS="${JAVA_OPTS} -Dsun.io.useCanonCaches=false -Djava.awt.headless=true"
export JAVA_OPTS="${JAVA_OPTS} -Djava.net.preferIPv4Stack=true"

