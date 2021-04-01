# config mssql file
SQL_USER=sa
SQL_PASSWORD=Labkey1098!
echo "config gradle mssql.properties"
sed -i "s|jdbcUser=sa|jdbcUser=$SQL_USER|g" $LABKEY_HOME/server/configs/mssql.properties
sed -i "s|jdbcPassword=sa|jdbcPassword=$SQL_PASSWORD|g" $LABKEY_HOME/server/configs/mssql.properties

# copy workspace template
echo "config intellij workspace template"
cp $LABKEY_HOME/.idea/workspace.template.xml $LABKEY_HOME/.idea/workspace.xml

# add Labkey environmental vars
tmpfile=/tmp/labkey_config.sh
echo "export LABKEY_HOME=$LABKEY_HOME" >> $tmpfile
echo "export PATH=\$PATH:$LABKEY_HOME/build/deploy/bin" >> $tmpfile

file=/etc/profile.d/labkey_config.sh
if test -f "$file"; then
    echo $sudoPW | sudo -S rm $file
fi
echo $sudoPW | sudo -S mv $tmpfile $file

# setup user gradle file
echo "config user gradle ~/.gradle"
rm -rf ~/.gradle && mkdir ~/.gradle
cp $LABKEY_HOME/gradle/global_gradle.properties_template  ~/.gradle/gradle.properties
sed -i "s|systemProp.tomcat.home=/path/to/tomcat/home|systemProp.tomcat.home=$TOMCAT_HOME|g" ~/.gradle/gradle.properties
echo "org.gradle.parallel=true" >> ~/.gradle/gradle.properties
echo "org.gradle.jvmargs=-Xmx4g" >> ~/.gradle/gradle.properties

#file=~/.bashrc
#grep -v "source /etc/profile" "$file" > "$tmp" && mv "$tmp" "$file"
#echo "source /etc/profile"  >> $file

## source /etc/profile in user account
#tmp=$(mktemp)
#file=~/.profile
#grep -v "source /etc/profile" "$file" > "$tmp" && mv "$tmp" "$file"
#echo "source /etc/profile"  >> $file