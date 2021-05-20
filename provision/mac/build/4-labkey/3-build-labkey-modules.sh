#!/bin/bash

source ../shared-variables.sh

for repo in "${LABKEY_REPO_MODULES_TO_INSTALL[@]}"
do
  cd $LABKEY_REPO/server/modules || exit
  git clone git@github.com:LabKey/$repo.git
	cd $repo || exit
	git checkout $GIT_BRANCH
done



