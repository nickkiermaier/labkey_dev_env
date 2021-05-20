# wipe/re-build folder structure

source ../shared-variables.sh

echo "Wipe and Rebuild Labkey folder structure" # https://www.labkey.org/Documentation/wiki-page.view?name=installComponents#folder

rm -rf ${LABKEY_ROOT:?}/*

mkdir -p $LABKEY_ROOT/apps \
 $LABKEY_ROOT/backups \
 $LABKEY_ROOT/labkey \
 $LABKEY_ROOT/labkey/externalModules \
 $LABKEY_ROOT/src

chmod -R 777 $LABKEY_ROOT