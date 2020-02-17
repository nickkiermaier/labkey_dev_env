# set env vars
LABKEY_ROOT=/labkey
LABKEY_REPO=$LABKEY_ROOT/labkey
LABKEY_HOME=$LABKEY_REPO/trunk
JAVA_VERSION="jdk-13.0.2"
TOMCAT_VERSION="apache-tomcat-9.0.31"

echo "create generic symlinks"
sudo ln -s $LABKEY_ROOT/apps/$JAVA_VERSION /usr/local/java
sudo ln -s $LABKEY_ROOT/apps/$TOMCAT_VERSION /usr/local/tomcat


echo "config profile"
echo "export LABKEY_HOME=$LABKEY_HOME" >> /etc/profile
echo 'export CATALINA_HOME="/usr/local/tomcat"' >> /etc/profile
echo 'export JAVA_HOME="/usr/local/java"' >> /etc/profile
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> /etc/profile
echo 'export PATH=$PATH:$LABKEY_HOME/build/deploy/bin' >> /etc/profile
source /etc/profile




echo "config profile"
echo "export LABKEY_HOME=$LABKEY_HOME" >> ~/.bashrc
echo 'export CATALINA_HOME="/usr/local/tomcat"' >> ~/.bashrc
echo 'export JAVA_HOME="/usr/local/java"' >> ~/.bashrc
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> ~/.bashrc
echo 'export PATH=$PATH:$LABKEY_HOME/build/deploy/bin' >> ~/.bashrc
source ~/.bashrc


echo "intellij"
cp $LABKEY_HOME/.idea/workspace.template.xml $LABKEY_HOME/.idea/workspace.xml

echo "gradle"
mkdir ~/.gradle
cp $LABKEY_HOME/gradle/global_gradle.properties_template  ~/.gradle/gradle.properties
sed -i "s|systemProp.tomcat.home=/path/to/tomcat/home|systemProp.tomcat.home=$CATALINA_HOME|g" ~/.gradle/gradle.properties
echo "org.gradle.parallel=true" >> ~/.gradle/gradle.properties
echo "org.gradle.jvmargs=-Xmx4g" >> ~/.gradle/gradle.properties


echo "configure tomcat"
mkdir -p $CATALINA_HOME/conf/Catalina/localhost

echo "config mssql"
# sed -i "s|<TBI>|<TBI>|g" $LABKEY_HOME/server/configs/mssql.properties
# sed -i "s|<TBI>|<TBI>|g" $LABKEY_HOME/server/configs/mssql.properties

