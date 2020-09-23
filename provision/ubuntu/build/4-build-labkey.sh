#!/bin/bash

LABKEY_ROOT=/labkey
LABKEY_REPO=$LABKEY_ROOT/labkey

# For using trunk
# LABKEY_HOME=$LABKEY_REPO/trunk
# LABKEY_URL=https://svn.mgt.labkey.host/stedi/trunk

# For using branches
LABKEY_BRANCH=release20.7-SNAPSHOT
GIT_BRANCH=$LABKEY_BRANCH
# LABKEY_HOME=$LABKEY_REPO/$LABKEY_BRANCH
LABKEY_URL=https://svn.mgt.labkey.host/stedi/branches/$LABKEY_BRANCH/

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