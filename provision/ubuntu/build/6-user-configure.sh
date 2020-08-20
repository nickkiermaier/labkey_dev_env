#!/bin/bash
## RUN AS USER

# one off configs
LABKEY_ROOT=/labkey
LABKEY_REPO=$LABKEY_ROOT/labkey
LABKEY_HOME=$LABKEY_REPO/trunk
CATALINA_HOME=/usr/local/tomcat


# source /etc/profile in user account
tmp=$(mktemp)
file=~/.profile
grep -v "source /etc/profile" "$file" > "$tmp" && mv "$tmp" "$file"
echo "source /etc/profile"  >> $file

file=~/.bashrc
grep -v "source /etc/profile" "$file" > "$tmp" && mv "$tmp" "$file"
echo "source /etc/profile"  >> $file


echo "config user gradle ~/.gradle"
rm -rf ~/.gradle && mkdir ~/.gradle
cp $LABKEY_HOME/gradle/global_gradle.properties_template  ~/.gradle/gradle.properties
sed -i "s|systemProp.tomcat.home=/path/to/tomcat/home|systemProp.tomcat.home=$CATALINA_HOME|g" ~/.gradle/gradle.properties
echo "org.gradle.parallel=true" >> ~/.gradle/gradle.properties
echo "org.gradle.jvmargs=-Xmx4g" >> ~/.gradle/gradle.properties

# chown the labkey directory as the user
WHOAMI=$(whoami)
sudo chown -R $WHOAMI $LABKEY_ROOT

# docker post installation
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker