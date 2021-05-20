### Add the following section to .bash_profile, edited to match your config

```
# -------------- LABKEY BEGIN -------------


export LABKEY_ROOT=~/labkey
export APP_ROOT=$LABKEY_ROOT/apps
export LABKEY_HOME=$LABKEY_ROOT/labkey
export LABKEY_REPO=$LABKEY_HOME/server
export JAVA_HOME=$APP_ROOT/apps/jdk-16.0.1.jdk
export TOMCAT_VERSION="apache-tomcat-9.0.46"
export TOMCAT_HOME=$APP_ROOT/apps/$TOMCAT_VERSION
export CATALINA_HOME=$TOMCAT_HOME
PATH=$PATH:$JAVA_HOME\bin:$LABKEY_REPO/build/deploy/bin

# ------------- LABKEY END ----------------

```