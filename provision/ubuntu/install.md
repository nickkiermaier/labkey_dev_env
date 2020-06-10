### Setup Developer Machine Part 1


###  Pre-Build
* Add a github ssh key for root to /root/.ssh so root has access to private repos(can delete this after install)

### Install
1. run all of the scripts, build first then config.
    * all scripts except the last one in config should be run as root

2. install intellij via app store or however
    * save it to task bar
    * set all startup options to defaults
    
3. configure intellij according to this section
    * open /labkey/labkey/trunk directory
    * https://www.labkey.org/Documentation/wiki-page.view?name=devMachine#ijconfig
    * note on Ubuntu/Mac/Linux the path separator is a :  on windows its a ;
    * note workspace template has already been copied in the scripts
    * Increase the Heap size in intellij
        * Help | Edit Custom VM Options
        * adjust the value of -Xmx to around 4024m
        * save and restart IntelliJ IDEA
        * https://stackoverflow.com/questions/17221725/how-to-increase-the-memory-heap-size-on-intellij-idea/17947603

4. Configuring the Appropriate .properties File has already been done by scripting! Skip to:

5. Optional: Increase the inotify limit if intellij asks for it.
    * https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit

5. In the root folder run:
    * `./gradlew pickMSSQL`
    * `./gradlew deployApp`

6. add this to <tomcat home>/conf/Catalina/localhost/labkey.xml
```
 <Resource name="jdbc/tnprcDataSource" auth="Container"
        type="javax.sql.DataSource"
        username="labkey"
        password="password"
        driverClassName="net.sourceforge.jtds.jdbc.Driver"
        url="jdbc:jtds:sqlserver://tsprlsqlc1d01.tulane.local:1433/prc"
        maxAcive="20"
        maxTotal="20"
        maxIdle="10"
        accessToUnderlyingConnectionAllowed="true"
        validationQuery="SELECT 1"
        />
```

### Setup Developer Machine Part 2

* https://www.labkey.org/TNPRC/wiki-page.view?name=ehr_project_setup
* also see this folder for a pdf copy

