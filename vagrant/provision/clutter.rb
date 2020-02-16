	# config.vm.provision "shell" do |s|
 #    	s.path = "provision/build_labkey.sh"
	# end


	# config.vm.synced_folder "<hostmachine folder>", "<location inside VM>", create: true, group: "root", owner: "root"

JAVA_HOME=C:\\Users\\nick\\Projects\\labkey\\apps\\jdk-13.0.1 # this is the windows path for apache
JAVA_DIR_LOCATION=$LABKEY_ROOT/apps/jdk-13.0.1


LABKEY_HOME=$LABKEY_ROOT/labkey/trunk
LABKEY_HOME_WIN=$LABKEY_ROOT\\labkey\\trunk
PATH_ADDITION="~/labkeytrunk\\build\\deploy\\bin"



TOMCAT_GRADLE_DIR_LOCATION=C:/Users/nick/Projects/labkey/apps/apache-tomcat-9.0.29 # this is the windows path for apache
CATALINA_HOME=C:\\Users\\nick\\Projects\\labkey\\apps\\apache-tomcat-9.0.29 # this is the windows path for apache
rm -rf ~/.gradle


# cleanup
# delete entire app if present
rm -rf $LABKEY_ROOT
rm /usr/local/java /usr/local/tomcat
