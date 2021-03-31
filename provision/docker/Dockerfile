FROM docker_labkey:latest

# mount
ADD ./layers /tmp/layers
ADD ./dependencies /tmp/dependencies

# env vars
ENV APP_ROOT="/labkey_apps" \
    DEPENDENCY_DIR="/tmp/dependencies"  \
    JAVA_ZIP_FILE="openjdk-13.0.2_linux-x64_bin.tar.gz" \
    JAVA_VERSION="jdk-13.0.2" \
    JAVA_HOME=$APP_ROOT/apps/$JAVA_VERSION \
    TOMCAT_ZIP_FILE="apache-tomcat-9.0.38.tar.gz" \
    TOMCAT_VERSION="apache-tomcat-9.0.38" \
    TOMCAT_HOME=$APP_ROOT/apps/$TOMCAT_VERSION \
    CATALINA_HOME=$TOMCAT_HOME \
    PATH=$PATH:$JAVA_HOME/bin

# layers
RUN chmod +x -R /tmp/layers
RUN /tmp/layers/1-base.sh
RUN /tmp/layers/5-test-success.sh

