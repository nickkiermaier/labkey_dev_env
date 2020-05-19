# set env vars
# NOTE: Previous scripts need to be run to set /usr/local symlinks
LABKEY_ROOT=/labkey
LABKEY_REPO=$LABKEY_ROOT/labkey
LABKEY_HOME=$LABKEY_REPO/trunk
CATALINA_HOME=/usr/local/tomcat
APP_ROOT=/labkey_apps

echo "config profile"
echo "export LABKEY_HOME=$LABKEY_HOME" >> /etc/profile
echo 'export CATALINA_HOME="/usr/local/tomcat"' >> /etc/profile
echo 'export JAVA_HOME="/usr/local/java"' >> /etc/profile
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> /etc/profile
echo 'export PATH=$PATH:$LABKEY_HOME/build/deploy/bin' >> /etc/profile
source /etc/profile

echo "root profile"
echo "export LABKEY_HOME=$LABKEY_HOME" >> ~/.profile
echo 'export CATALINA_HOME="/usr/local/tomcat"' >> ~/.profile
echo 'export JAVA_HOME="/usr/local/java"' >> ~/.profile
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> ~/.profile
echo 'export PATH=$PATH:$LABKEY_HOME/build/deploy/bin' >> ~/.profile
source ~/.profile

echo "config tomcat directory for gradle msssql build"
mkdir -p $CATALINA_HOME/conf/Catalina/localhost

