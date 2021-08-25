[[ $_ != $0 ]] && echo "Script is being sourced" || (echo "Script is a subshell" && source ./shared-variables.sh)

echo ""
# create path variables
echo "ENSURE THIS IS ADDED TO YOUR ENVIRONMENT AND IS CORRECT:"
echo "export JAVA_HOME=\"$JAVA_HOME\""
echo "export CATALINA_HOME=\"$TOMCAT_HOME\""
echo "export LABKEY_HOME=\"$LABKEY_REPO\""
echo "export PATH=\$PATH:\$JAVA_HOME/bin:\$LABKEY_HOME/server/build/deploy/bin"
echo ""

read -p "Continue? " choice
case "$choice" in
  n|N ) echo "Exiting"; exit 1;;
  * ) echo "" ;;
esac


echo "COPY GRADLE TEMPLATE TO:  ~/.gradle from $LABKEY_REPO/gradle/global_gradle.properties_template"
echo "Add these settings to ~/.gradle/gradle.properties file(must be absolute path.):"
echo "systemProp.tomcat.home=$TOMCAT_HOME"
echo "org.gradle.parallel=true"
echo "org.gradle.jvmargs=-Xmx4g"
echo ""

echo "Currently seeing as:"
echo "---------------------------------"
cat ~/.gradle/gradle.properties
echo "---------------------------------"

read -p "Continue? " choice
case "$choice" in
  n|N ) echo "Exiting"; exit 1;;
  * ) echo "" ;;
esac

echo "Continuing"