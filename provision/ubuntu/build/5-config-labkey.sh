#!/bin/bash

LABKEY_ROOT=/labkey
LABKEY_REPO=$LABKEY_ROOT/labkey
LABKEY_HOME=$LABKEY_REPO/trunk
APP_ROOT=/labkey_apps

# config mssql file
SQL_USER=sa
SQL_PASSWORD=Labkey1098!
echo "config gradle mssql.properties"
sed -i "s|jdbcUser=sa|jdbcUser=$SQL_USER|g" $LABKEY_HOME/server/configs/mssql.properties
sed -i "s|jdbcPassword=sa|jdbcPassword=$SQL_PASSWORD|g" $LABKEY_HOME/server/configs/mssql.properties

# copy workspace template
echo "config intellij workspace template"
cp $LABKEY_HOME/.idea/workspace.template.xml $LABKEY_HOME/.idea/workspace.xml

# Ensure access
chmod 777 -R $APP_ROOT
chmod 777 -R $LABKEY_ROOT

# add paths to system
file=/etc/profile.d/labkey_config.sh
if test -f "$file"; then
    rm $file
fi
touch $file
echo "export LABKEY_HOME=$LABKEY_HOME" >> $file
echo "export PATH=\$PATH:$LABKEY_HOME/build/deploy/bin" >> $file
