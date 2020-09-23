#!/bin/bash
# run as user!

read -s -p "Enter Password for sudo: " sudoPW

LABKEY_ROOT=/labkey
LABKEY_REPO=$LABKEY_ROOT/labkey

# For using trunk
# LABKEY_HOME=$LABKEY_REPO/trunk
# LABKEY_URL=https://svn.mgt.labkey.host/stedi/trunk
# GIT_BRANCH=develop


# For using branches
LABKEY_BRANCH=release20.7-SNAPSHOT
GIT_BRANCH=$LABKEY_BRANCH
LABKEY_HOME=$LABKEY_REPO/$LABKEY_BRANCH
LABKEY_URL=https://svn.mgt.labkey.host/stedi/branches/$LABKEY_BRANCH/


# for sql server config
SQL_USER=sa
SQL_PASSWORD=Labkey1098!


# wipe/re-build folder structure
echo "Wipe and Rebuild Labkey folder structure" # https://www.labkey.org/Documentation/wiki-page.view?name=installComponents#folder
rm -rf ${LABKEY_ROOT:?}/*
mkdir -p $LABKEY_ROOT/apps \
 $LABKEY_ROOT/backups \
 $LABKEY_ROOT/labkey \
 $LABKEY_ROOT/labkey/externalModules \
 $LABKEY_ROOT/src \
 $LABKEY_ROOT/tomcat-tmp

chmod 777 $LABKEY_ROOT

# checkout main app
echo "Checkout Main App" # https://www.labkey.org/Documentation/wiki-page.view?name=devMachine#checkout
cd $LABKEY_REPO || exit
svn checkout $LABKEY_URL

# ensure main repo successful
if [ $? -eq 0 ]; then
    echo "SVN PULL SUCCESSFUL"
else
    echo "SVN PULL NOT SUCCESSFUL"
    exit
fi


# # clone modules
echo "Download labkey modules" # https://www.labkey.org/Documentation/wiki-page.view?name=devMachine#coregit

# clone modules in server folder
cd $LABKEY_BRANCH/server || exit
git clone https://github.com/LabKey/testAutomation.git
cd testAutomation || exit
git checkout $GIT_BRANCH
cd ..

# clone labkey modules in server/modules folder
cd modules || exit

for repo in platform commonAssays custommodules discvrlabkeymodules ehrModules LabDevKitModules dataintegration tnprc_ehr
do
	git clone git@github.com:LabKey/$repo.git
	cd $repo || exit
	git checkout $GIT_BRANCH
	cd ..
done

# config mssql file
echo "config gradle mssql.properties"
sed -i "s|jdbcUser=sa|jdbcUser=$SQL_USER|g" $LABKEY_HOME/server/configs/mssql.properties
sed -i "s|jdbcPassword=sa|jdbcPassword=$SQL_PASSWORD|g" $LABKEY_HOME/server/configs/mssql.properties

# copy workspace template
echo "config intellij workspace template"
cp $LABKEY_HOME/.idea/workspace.template.xml $LABKEY_HOME/.idea/workspace.xml

# add Labkey environmental vars
tmpfile=/tmp/labkey_config.sh
echo "export LABKEY_HOME=$LABKEY_HOME" >> $tmpfile
echo "export PATH=\$PATH:$LABKEY_HOME/build/deploy/bin" >> $tmpfile

file=/etc/profile.d/labkey_config.sh
if test -f "$file"; then
    echo $sudoPW | sudo -S rm $file
fi
echo $sudoPW | sudo -S mv $tmpfile $file

# setup user gradle file
echo "config user gradle ~/.gradle"
rm -rf ~/.gradle && mkdir ~/.gradle
cp $LABKEY_HOME/gradle/global_gradle.properties_template  ~/.gradle/gradle.properties
sed -i "s|systemProp.tomcat.home=/path/to/tomcat/home|systemProp.tomcat.home=$TOMCAT_HOME|g" ~/.gradle/gradle.properties
echo "org.gradle.parallel=true" >> ~/.gradle/gradle.properties
echo "org.gradle.jvmargs=-Xmx4g" >> ~/.gradle/gradle.properties

#file=~/.bashrc
#grep -v "source /etc/profile" "$file" > "$tmp" && mv "$tmp" "$file"
#echo "source /etc/profile"  >> $file

## source /etc/profile in user account
#tmp=$(mktemp)
#file=~/.profile
#grep -v "source /etc/profile" "$file" > "$tmp" && mv "$tmp" "$file"
#echo "source /etc/profile"  >> $file

