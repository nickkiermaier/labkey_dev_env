# required for scripts
# note the format of mount is as follows
# sudo mount -t vboxsf -o dmode=777,fmode=777 <last folder in path on host machine> <location on guest>

# unmount all vbox drives
sudo umount -a -t vboxsf

# mount two drives
# mounting svn as a shared drive does not work at the moment, figure that out.
# sudo mount -t vboxsf -o dmode=777,fmode=777 labkey_vm_mount_point  /labkey
mkdir ~/.ssh
sudo mount -t vboxsf -o dmode=700,fmode=600 .ssh  ~/.ssh

# optional
# mkdir ~/Desktop/labkey_vm_share
# sudo mount -t vboxsf -o dmode=777,fmode=777 labkey_vm_share  ~/Desktop/labkey_vm_share
# mkdir ~/provision
# sudo mount -t vboxsf -o dmode=777,fmode=777 provision  ~/provision