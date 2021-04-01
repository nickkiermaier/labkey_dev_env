#!/bin/bash
# run as user!
source ../shared-variables.sh



# checkout main app
echo "Checkout Main App"
cd $LABKEY_HOME || exit
git clone $LABKEY_SERVER_REPO_URL
cd $LABKEY_REPO || exit
git checkout $GIT_BRANCH


# ensure main repo successful
if [ $? -eq 0 ]; then
    echo "GIT PULL SUCCESSFUL"
else
    echo "GIT PULL NOT SUCCESSFUL"
    exit
fi



# # clone testAutomation folder
echo "Download testAutomation"

cd $LABKEY_REPO/server || exit
git clone https://github.com/LabKey/testAutomation.git
cd testAutomation || exit
git checkout $GIT_BRANCH


