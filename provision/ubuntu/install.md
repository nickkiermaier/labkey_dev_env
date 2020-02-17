### Virtual Box Setup
1. Spin up labkey clean Ubuntu instance 
    * username is labkey/password is pwd
    * specs:
        * hard drive at least 50G
        * RAM at least 10G
        * cpu cores as many as possible
        * cpu max around 80 or 85
    * Enable Bidrectional pointer
    * Install guest addons, if not already available (for full screen functionality, file share, and more)
    
2. Share these specific folders between the boxes
    * create a shared folder pointing to host folder called: 
        * labkey_vm_mount_point
            * this is where your labkey files will go so they can be edited on the host
        * .ssh  
            * this is where your host ssh keys should be
    * ensure no boxes are checked in the shared folder screen!!! 
        * i.e. uncheck automount, permanant, readonly, etc.! 
        * These get mounted automatically on login
3. Add a second network adaptor
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


### Internal VM Labkey Setup
1. run all of the scripts.
    * note: the user you should be using is in the name of the script.
        * all root scripts need to be run as `sudo su`
        * all user scripts should be run as labkey user
