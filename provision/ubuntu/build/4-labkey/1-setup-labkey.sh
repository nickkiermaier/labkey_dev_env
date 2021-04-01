source ../shared-variables.sh



echo "Wipe and Rebuild Labkey folder structure "

read -s -p "Enter Password for sudo: " sudoPW

echo ""

echo $sudoPW | sudo -S rm -rf ${LABKEY_ROOT:?}/*

echo $sudoPW | sudo -S mkdir -p $LABKEY_ROOT/apps \
 $LABKEY_ROOT/backups \
 $LABKEY_ROOT/labkey \
 $LABKEY_ROOT/labkey/externalModules \
 $LABKEY_ROOT/src \
 $LABKEY_ROOT/tomcat-tmp

echo $sudoPW | sudo -S chmod 777 -R $LABKEY_ROOT