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
    
    


### Internal VM Labkey Setup
