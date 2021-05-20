source ../shared-variables.sh


echo "Wipe and Rebuild Labkey folder structure "

read -s -p "Enter Password for sudo: " sudoPW

echo ""

echo $sudoPW | sudo -S rm -rf ${LABKEY_HOME:?}/*

mkdir -p $LABKEY_HOME

echo $sudoPW | sudo -S chmod -R 777  $LABKEY_ROOT

echo ""