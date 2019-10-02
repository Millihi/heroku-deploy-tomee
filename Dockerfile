FROM openjdk:8-jdk-alpine as build
COPY . /usr/src/server
WORKDIR /usr/src/server

FROM tomee:8-jre-7.1.0-plus
COPY bin/run_tomee.sh /usr/local/tomee/bin/
COPY bin/setenv.sh /usr/local/tomee/bin/
COPY config/system.properties /usr/local/tomee/conf/
COPY config/server.xml /usr/local/tomee/conf/
COPY config/tomcat-users.xml /usr/local/tomee/conf/
COPY --from=0 /usr/src/server/webapps/captcha.war /usr/local/tomee/webapps/
COPY --from=0 /usr/src/server/webapps/tetris.war /usr/local/tomee/webapps/
CMD /usr/local/tomee/bin/run.sh

