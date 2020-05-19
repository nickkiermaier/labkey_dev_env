#!/bin/bash
## RUN AS USER

# one off configs
LABKEY_ROOT=/labkey
LABKEY_REPO=$LABKEY_ROOT/labkey
LABKEY_HOME=$LABKEY_REPO/trunk
CATALINA_HOME=/usr/local/tomcat

echo "bashrc profile"
echo "export LABKEY_HOME=$LABKEY_HOME" >> ~/.bashrc
echo 'export CATALINA_HOME="/usr/local/tomcat"' >> ~/.bashrc
echo 'export JAVA_HOME="/usr/local/java"' >> ~/.bashrc
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> ~/.bashrc
echo 'export PATH=$PATH:$LABKEY_HOME/build/deploy/bin' >> ~/.bashrc
source ~/.bashrc

echo "config user gradle ~/.gradle"
rm -rf ~/.gradle && mkdir ~/.gradle
cp $LABKEY_HOME/gradle/global_gradle.properties_template  ~/.gradle/gradle.properties
sed -i "s|systemProp.tomcat.home=/path/to/tomcat/home|systemProp.tomcat.home=$CATALINA_HOME|g" ~/.gradle/gradle.properties
echo "org.gradle.parallel=true" >> ~/.gradle/gradle.properties
echo "org.gradle.jvmargs=-Xmx4g" >> ~/.gradle/gradle.properties

# chown the labkey directory as the user
WHOAMI=$(whoami)
sudo chown -R $WHOAMI $LABKEY_ROOT