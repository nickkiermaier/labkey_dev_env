#!/bin/bash

# add paths to system
file=/etc/profile.d/labkey_config.sh
if test -f "$file"; then
    rm $file
fi
touch $file
echo "export LABKEY_HOME=$LABKEY_HOME" >> $file
echo "export PATH=\$PATH:$LABKEY_HOME/build/deploy/bin" >> $file
