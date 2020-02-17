sudo mount -t vboxsf -o uid=1000,gid=1000,rw,exec,dmode=777,fmode=777 labkey_vm_mount_point  /labkey
sudo mount -t vboxsf -o uid=1000,gid=1000,rw,exec,dmode=600,fmode=500 .ssh  ~/.ssh

