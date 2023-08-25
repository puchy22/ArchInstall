#!/bin/sh

# Function to check the boot mode

check_boot_mode(){

	# Verify the boot mode
	if [ -d /sys/firmware/efi/efivars ]; then
		echo "The system is booted in UEFI mode."
		uefi=1	# True
	else
		echo "The system is booted in BIOS mode."
		uefi=0	# False
	fi

	return $uefi
}

main(){
	clear
	echo "   _____                .__      .___                 __         .__  .__   "
	echo "  /  _  \_______   ____ |  |__   |   | ____   _______/  |______  |  | |  |  "
	echo " /  /_\  \_  __ \_/ ___\|  |  \  |   |/    \ /  ___/\   __\__  \ |  | |  |  "
	echo "/    |    \  | \/\  \___|   Y  \ |   |   |  \\___ \  |  |  / __ \|  |_|  |__"
	echo "\____|__  /__|    \___  >___|  / |___|___|  /____  > |__| (____  /____/____/"
	echo "        \/            \/     \/           \/     \/            \/            "
	echo ""
	echo "by Puchy (2023)"
	echo "-----------------------------------------------------"
	echo "This is the installation set up script for Arch Linux."
	echo "WARNING: This script is not compatible with BIOS systems."
	echo "This script is only thought for option 2 of partitions of pre-install."
	echo "-----------------------------------------------------"
	echo ""

	# Set the time zone (eg. Spain/Madrid)
	echo "-----------------------------------------------------"
	echo "Setting the time zone..."
	echo "-----------------------------------------------------"

	ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
	hwclock --systohc

	# Set the locale (eg. es_ES.UTF-8 UTF-8)
	echo "-----------------------------------------------------"
	echo "Setting the locale..."
	echo "-----------------------------------------------------"

	sed -i 's/#es_ES.UTF-8 UTF-8/es_ES.UTF-8 UTF-8/g' /etc/locale.gen
	locale-gen

	echo "LANG=es_ES.UTF-8" >> /etc/locale.conf

	# Set the keyboard layout (eg. es)
	echo "-----------------------------------------------------"
	echo "Setting the keyboard layout..."
	echo "-----------------------------------------------------"

	echo "KEYMAP=es" >> /etc/vconsole.conf

	# Set the hostname (eg. puchy)
	echo "-----------------------------------------------------"
	echo "Setting the hostname..."
	echo "-----------------------------------------------------"

	echo "PC-PUCHY" >> /etc/hostname

	# Set the hosts file
	echo "-----------------------------------------------------"
	echo "Setting the hosts file..."
	echo "-----------------------------------------------------"

	echo "# Static table lookup for hostnames." > /etc/hosts
	echo "# See hosts(5) for details." >> /etc/hosts
	printf "127.0.0.1\tlocalhost\n" >> /etc/hosts
	printf "::1\tlocalhost\n" >> /etc/hosts
	printf "127.0.1.1\tPC-PUCHY.localdomain\tPC-PUCHY\n" >> /etc/hosts
	echo "" >> /etc/hosts

	# Set the root password
	echo "-----------------------------------------------------"
	echo "Set the root password..."
	echo "-----------------------------------------------------"

	passwd

	# Install and configure the bootloader
	echo "-----------------------------------------------------"
	echo "Install and configure boot loader..."
	echo "-----------------------------------------------------"

	# Extract the name of the disk that is mounted on /boot
	disk=$(df /boot | grep /dev | awk '{print $1}' | sed 's/[0-9]//g')
	# Extract the UUID of the root crypt partition
	root_uuid=$(blkid | grep -E '/dev/mapper/RootVG-cryptroot' | awk '{print $2}' | sed 's/"//g' | sed 's/UUID=//g')

	pacman -Syy --noconfirm efibootmgr lvm2 intel-ucode sudo

	# Setting up the initramfs
	echo "-----------------------------------------------------"
	echo "Setting up the initramfs..."
	echo "-----------------------------------------------------"

	sed -i '
	/^HOOKS=/ {
		# use systemd
		s/base udev autodetect/base systemd autodetect/
		# use sd-vconsole instead of keymap and consolefont
		s/keyboard keymap consolefont/keyboard sd-vconsole/
		# use sd-encrypt and sd-lvm2 instead of lvm2 and encrypt
		s/block filesystems/block sd-encrypt lvm2 filesystems/
	}
	' /etc/mkinitcpio.conf

	mkinitcpio -P

	efibootmgr \
    --disk $disk \
    --part 1 \
	 --create \
    --label 'Arch-Linux' \
    --loader /vmlinuz-linux \
    --unicode 'initrd=\intel-ucode.img initrd=\initramfs-linux.img rd.luks.name='$root_uuid'=root root=/dev/mapper/root' \
    --verbose

	# Configure encrypted swap partition
	printf 'swap\t/dev/SwapVG/cryptswap\t/dev/urandom\tswap,cipher=aes-xts-plain64,size=256\n' >> /etc/crypttab
	printf '/dev/mapper/swap\tnone\tswap\tsw\t0\t0\n' >> /etc/fstab

	# Adding a user
	echo "-----------------------------------------------------"
	echo "Adding a user puchy..."
	echo "-----------------------------------------------------"

	useradd -m -g users -G wheel -s /bin/bash puchy
	passwd puchy

	# Configure sudo
	echo "-----------------------------------------------------"
	echo "Allowing wheel group to use sudo..."
	echo "-----------------------------------------------------"

	sed -i 's/^# %wheel ALL=(ALL:ALL) ALL$/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

	# Enable services
	echo "-----------------------------------------------------"
	echo "Enabling services..."
	echo "-----------------------------------------------------"

	systemctl enable NetworkManager

	# Finish installation
	echo "-----------------------------------------------------"
	echo "Installation finished"
	echo "-----------------------------------------------------"

	echo "Please reboot the system and remove the installation media."

}

# MAIN
main
