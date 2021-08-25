#!/bin/bash

source ../shared-variables.sh

cd $LABKEY_REPO || exit

./gradlew ijWorkspaceSetup
./gradlew ijConfigure
./gradlew deployApp

