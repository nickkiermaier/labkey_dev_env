source ../shared-variables.sh


echo "Wipe and Rebuild Labkey folder structure "

read -s -p "Enter Password for sudo: " sudoPW

echo ""

echo "Deleting Labkey Folders."


echo $sudoPW | sudo -S rm -rf $LABKEY_ROOT

echo "Labkey Folders Deleted."

echo $sudoPW | sudo -S mkdir -p $LABKEY_ROOT

echo $sudoPW | sudo -S mkdir -p \
 $APP_ROOT \
 $APP_ROOT/tomcat \
 $APP_ROOT/java \
 $APP_ROOT/src \
 $LABKEY_ROOT/backups \
 $LABKEY_ROOT/labkey \
 $LABKEY_ROOT/labkey/externalModules \
 $LABKEY_ROOT/src \
 $LABKEY_ROOT/tomcat-tmp


# this is not needed?
echo $sudoPW | sudo -S chmod -R 777 $LABKEY_ROOT
echo "Set permissions for labkey directory"

