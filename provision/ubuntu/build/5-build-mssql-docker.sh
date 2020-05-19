#!/bin/bash
# via this tut
# https://docs.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker?view=sql-server-ver15&pivots=cs1-bash

SQL_USER=SA
SQL_PASS=Labkey1098!

sudo docker pull mcr.microsoft.com/mssql/server:2019-CU3-ubuntu-18.04

sudo docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=$SQL_PASS" \
   -p 1433:1433 --name sql1 \
   -d mcr.microsoft.com/mssql/server:2019-CU3-ubuntu-18.04

# figure out how to script password changes




# install pyenv and pip mssql-cli