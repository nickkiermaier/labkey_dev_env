#!/bin/bash -e
# run as root
# Use the following variables to control your install:

# Password for the SA user (required)
MSSQL_SA_PASSWORD='Password01!'

# Product ID of the version of SQL server you're installing
# Must be evaluation, developer, express, web, standard, enterprise, or your 25 digit product key
# Defaults to developers
MSSQL_PID='express'

# enable mssql agent
MSSQL_AGENT_ENABLED=true

# Create an additional user with sysadmin privileges (optional)
SQL_INSTALL_USER='labkey'
SQL_INSTALL_USER_PASSWORD='Password01!'


if [ -z $MSSQL_SA_PASSWORD ]
then
  echo Environment variable MSSQL_SA_PASSWORD must be set for unattended install
  exit 1
fi

# Install
echo Adding Microsoft repositories...
sudo wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
sudo add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/16.04/mssql-server-2019.list)"
sudo apt-get update -y
sudo apt-get install -y mssql-server

# Configure
echo Running mssql-conf setup...
sudo MSSQL_SA_PASSWORD=$MSSQL_SA_PASSWORD \
     MSSQL_PID=$MSSQL_PID \
     /opt/mssql/bin/mssql-conf -n setup accept-eula

# Configure firewall to allow TCP port 1433:
echo Configuring UFW to allow traffic on port 1433...
sudo ufw allow 1433/tcp
sudo ufw reload

curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list
echo Installing mssql-tools and unixODBC developer...
sudo apt-get update
sudo ACCEPT_EULA=Y apt-get install -y mssql-tools unixodbc-dev

# Add SQL Server tools to the path by default:
echo Adding SQL Server tools to your path...
echo PATH="$PATH:/opt/mssql-tools/bin" >> /etc/profile
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> /etc/profile
source /etc/profile

# Restart SQL Server after installing:
echo Restarting SQL Server...
sudo systemctl restart mssql-server

count=1
while [ $(systemctl is-active mssql-server) = "inactive" ] && [ $count -le 5 ]; do
   echo "Waiting for sql server to start";
   sleep 3s;
   ((count++))
done


/opt/mssql-tools/bin/sqlcmd \
  -S localhost \
  -U SA \
  -P $MSSQL_SA_PASSWORD \
  -Q "SELECT @@VERSION" 2>/dev/null


# Optional new user creation:
if [ ! -z $SQL_INSTALL_USER ] && [ ! -z $SQL_INSTALL_USER_PASSWORD ]
then
  echo Creating user $SQL_INSTALL_USER
  /opt/mssql-tools/bin/sqlcmd \
    -S localhost \
    -U SA \
    -P $MSSQL_SA_PASSWORD \
    -Q "CREATE LOGIN [$SQL_INSTALL_USER] WITH PASSWORD=N'$SQL_INSTALL_USER_PASSWORD', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=ON, CHECK_POLICY=ON; ALTER SERVER ROLE [sysadmin] ADD MEMBER [$SQL_INSTALL_USER]"
fi

echo Done!