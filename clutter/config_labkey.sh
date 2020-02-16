sudo ln -s $LABKEY_ROOT/apps/$JAVA_VERSION /usr/local/java
echo 'export JAVA_HOME="/usr/local/java"' >> /etc/profile
echo 'export PATH=$PATH:/usr/local/java/bin' >> /etc/profile
source /etc/profile


sudo ln -s /usr/local/labkey/apps/$TOMCAT_VERSION /usr/local/tomcat
echo 'export CATALINA_HOME="/usr/local/tomcat"' >> /etc/profile
source /etc/profile


# # ~/.gradle setup
# https://www.labkey.org/Documentation/wiki-page.view?name=devMachine#gradle
cd ~
mkdir .gradle
cp $LABKEY_HOME/gradle/global_gradle.properties_template  ~/.gradle/gradle.properties
sed -i "s|systemProp.tomcat.home=/path/to/tomcat/home|systemProp.tomcat.home=$TOMCAT_WIN_DIR_LOCATION|g" ~/.gradle/gradle.properties


cp $LABKEY_HOME/.idea/workspace.template.xml $LABKEY_HOME/.idea/workspace.xml

echo "Please add these environmental variables."
echo "JAVA_HOME: $JAVA_HOME"
echo "CATALINA_HOME: $CATALINA_HOME"
echo "LABKEY_HOME: $LABKEY_HOME_WIN"

echo "Please add the following to your path"
echo $PATH_ADDITION

echo "Run $CATALINA_HOME\bin\startup.bat on windows or startup.sh on linux then visit localhost:8080."

sudo ln -s /usr/local/labkey/apps/$TOMCAT_VERSION /usr/local/tomcat
echo 'export CATALINA_HOME="/usr/local/tomcat"' >> /etc/profile
source /etc/profile
v


sudo ln -s $LABKEY_ROOT/apps/$JAVA_VERSION /usr/local/java
echo 'export JAVA_HOME="/usr/local/java"' >> /etc/profile
echo 'export PATH=$PATH:/usr/local/java/bin' >> /etc/profile
source /etc/profile
