# Path vars
# Run as user!
echo "LABKEY HOME: $LABKEY_HOME"
echo "JAVA HOME: $JAVA_HOME"
echo "CATALINA HOME: $CATALINA_HOME"

# user gradle is correct
cat ~/.gradle/gradle.properties

# labkey config with labkey variables
cat /etc/profile.d/labkey_config.sh

# test the workspace.xml was created
file=$LABKEY_HOME/.idea/workspace.xml
if test -f "$file"; then
    echo "$file exists!"
fi

# test that mssql.properties was working
cat $LABKEY_HOME/server/configs/mssql.properties

# test that the repos are on the right branch
for repo in platform commonAssays custommodules discvrlabkeymodules ehrModules LabDevKitModules dataintegration tnprc_ehr
do
	cd $LABKEY_HOME/server/modules/$repo
	echo "$repo"
	git branch
done