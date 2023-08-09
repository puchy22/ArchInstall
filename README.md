
# ArchInstall

Here is my set of scripts that I use to install Arch Linux normally.
They are focused in my SSD (cache) + HDD (storage) installation, but it can be useful in more situations.

# What does each script

1. **01-pre_install.sh**: Connect to internet, configure some features before changing root, partition and
format the disks, and install de essentials packages in the new root.
2. **02-install.sh**: Configure all the personal stuffs in the installation as the time zone, users and passwords,
and set up the EFISTUB as the bootloader.
3. **05-security**: This script install and configure some security features as the firewall, antivirus, etc.
and also install some useful packages for penteration testing.