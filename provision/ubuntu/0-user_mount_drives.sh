# required for scripts

# unmount all vbox drives
sudo umount -a -t vboxsf

# mount two drives
sudo mount -t vboxsf -o dmode=777,fmode=777 labkey_vm_mount_point  /labkey
sudo mount -t vboxsf -o dmode=700,fmode=600 .ssh  ~/.ssh

# optional
mkdir ~/Desktop/labkey_vm_share
sudo mount -t vboxsf -o dmode=777,fmode=777 labkey_vm_share  ~/Desktop/labkey_vm_share

sudo mount -t vboxsf -o dmode=777,fmode=777 ubuntu  ~/provision