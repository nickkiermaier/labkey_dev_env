#!/bin/bash


LABKEY_ROOT=/labkey
LABKEY_REPO=$LABKEY_ROOT/labkey
LABKEY_HOME=$LABKEY_REPO/trunk


# config mssql file
SQL_USER=sa
SQL_PASSWORD=Labkey1098!
echo "config gradle mssql.properties"
sed -i "s|jdbcUser=sa|jdbcUser=$SQL_USER|g" $LABKEY_HOME/server/configs/mssql.properties
sed -i "s|jdbcPassword=sa|jdbcPassword=$SQL_PASSWORD|g" $LABKEY_HOME/server/configs/mssql.properties


# copy worksapce template
echo "config intellij workspace template"
cp $LABKEY_HOME/.idea/workspace.template.xml $LABKEY_HOME/.idea/workspace.xml
