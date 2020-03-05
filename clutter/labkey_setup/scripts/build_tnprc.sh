#!/bin/bash

cd $LABKEY_HOME/server/optionalmodules
git clone https://github.com/labkey/dataintegration
git clone https://github.com/labkey/tnprc_ehr


cd $LABKEY_HOME/server/modules
git clone https://github.com/LabKey/commonAssays 
git clone https://github.com/LabKey/custommodules
git clone https://github.com/labkey/discvrlabkeymodules DiscvrLabKeyModules
git clone https://github.com/labkey/ehrModules
git clone https://github.com/labkey/LabDevKitModules
git clone https://github.com/labkey/platform


