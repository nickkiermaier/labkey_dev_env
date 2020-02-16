#!/bin/bash
cd $LABKEY_HOME/.idea
svn revert gradle.xml
rm -rf modules
rm modules.xml
