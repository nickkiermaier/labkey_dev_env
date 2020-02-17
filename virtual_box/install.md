### Virtual Box Setup
1. Spin up labkey clean Ubuntu instance 
    * username is labkey/password is pwd
    * specs:
        * hard drive at least 50G
        * RAM at least 10G
        * cpu cores as many as possible
        * cpu max around 80 or 85
        
2. Share these folders between the boxes
    * share the folder you want labkey installed to /labkey on the VM
    * share the location of your ssh keys(for github) to /labkey_ssh
        * make this read only
    *  ensure auto-mount is checked for both

3. Install guest addons, if not already available (for full screen functionality and more)

### Internal VM Labkey Setup
