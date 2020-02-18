### Virtual Box Setup
1. Spin up labkey clean Ubuntu instance 
    * username is labkey/password is pwd
    * specs:
        * hard drive at least 50G
        * RAM at least 10G
        * cpu cores as many as possible
        * cpu max around 80 or 85
    * Install guest addons, if not already available (for full screen functionality, file share, and more)
    
2. Share these specific folders between the boxes
    * .ssh  
        * this is where your host ssh keys should be
    * ensure no boxes are checked in the shared folder screen!!! 
        * i.e. uncheck automount, permanant, readonly, etc.! 
        * These get mounted during install with specific permissions

### Internal VM Labkey Setup
1. Copy provisioning or mount the scripts
    * there's a mount option in the first script
    
1. run all of the scripts.
    * note: the user you should be using is in the name of the script.
        * all root scripts need to be run as `sudo su`
        * all user scripts should be run as labkey user

2. install intellij via app store
    * save it to task bar
    * set all startup options to defaults
    
3. configure intellij according to this section
    * open /labkey/labkey/trunk directory
    * https://www.labkey.org/Documentation/wiki-page.view?name=devMachine#ijconfig
    * note workspace template has already been copied in the scripts
    * Increase the Heap size in intellij
        * Help | Edit Custom VM Options
        * adjust the value of -Xmx to around 4024m
        * save and restart IntelliJ IDEA
        * https://stackoverflow.com/questions/17221725/how-to-increase-the-memory-heap-size-on-intellij-idea/17947603

4. Configuring the Appropriate .properties File has already been done by scripting! Skip to:

5. Increase the inotify limit
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

### labkey Console Setup




## Optional but Recommended tweaks

### tweak Vm settings
1. Set sleep to never 
1. Enable Bidrectional pointer
1. enable two monitors


### Share tomcat from guest to host
1. Add a second network adaptor
    * https://odan.github.io/2017/10/29/accessing-your-virtualbox-guest-from-your-host-os.html
    * ```   Shut down all running VM’s
        Right click on the VM > Change… > Network
        Open Tab: Adapter 1
        Enable the Adapter and select “NAT”
        The next step is importand to make it work:
        
        Open Tab: Adapter 2
        Enable the adapter and select: “Host-only Adapter”
        Select Name: “VirtualBox Host-only Ethernet Adapter”
        Click at “Extended”
        Select the adapter: “Intel PRO/1000 MT Desktop…”
        Select the modus: “Allow all and host”
        Click on “Ok” to save all settings.
        Yes, you have to enable two adapters at the same time to make it work. Realy. You need a “NAT” and a “Host-only Adapter”.
        
        Start the VM
        Open the terminal (with Ctrl+Alt+T)
        Enter: ifconfig
        Now you should see a local IP addresse like: 192.168.56.104
        The IP address is dynamic an can be different on your VM```