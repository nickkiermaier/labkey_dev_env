#!/bin/bash

read -s -p "Enter Password for sudo: " sudoPW


source ../shared-variables.sh

echo ""

# config mssql
echo "config gradle mssql.properties"
sed -i '' -e "s|jdbcUser=sa|jdbcUser=$SQL_USER|g" $LABKEY_REPO/server/configs/mssql.properties
sed -i '' -e "s|jdbcPassword=sa|jdbcPassword=$SQL_PASSWORD|g" $LABKEY_REPO/server/configs/mssql.properties

# copy workspace template
echo "config intellij workspace template"
cp $LABKEY_REPO/.idea/workspace.template.xml $LABKEY_REPO/.idea/workspace.xml


# setup user gradle file
echo "config user gradle ~/.gradle"
rm -rf ~/.gradle && mkdir ~/.gradle
cp $LABKEY_REPO/gradle/global_gradle.properties_template  ~/.gradle/gradle.properties
sed -i '' -e "s|systemProp.tomcat.home=/path/to/tomcat/home|systemProp.tomcat.home=$TOMCAT_HOME|g" ~/.gradle/gradle.properties
echo "org.gradle.parallel=true" >> ~/.gradle/gradle.properties
echo "org.gradle.jvmargs=-Xmx4g" >> ~/.gradle/gradle.properties


echo "Please logout and login again."
