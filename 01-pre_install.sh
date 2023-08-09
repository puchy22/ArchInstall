#!/bin/sh

###############################################################################
# Function to check the boot mode
###############################################################################

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

###############################################################################
# Function to partition the disks and LVM setup
###############################################################################

prepare_disk_lvm_on_luks(){

	# Check if the number of params is correct
	if [ $# -ne 1 ]; then
		echo "Error: The number of params is incorrect."
		echo "Usage: prepare_disk_simple_luks_on_lvm <disk>"
		exit 1
	fi

	# Obtain teh GB of RAM for swap partition
	ram_gb=$(free --giga | awk '/Mem:/ {print $2}')

	# Check if the system is booted in UEFI mode
	check_boot_mode
	uefi=$?

	if [ $uefi -eq 1 ]; then
		# Create the partitions (one for boot, SWAP (GB of RAM) and the other for LUKS)
		parted --script $1 mklabel gpt \
			mkpart primary fat32 1MiB 1025MiB \
			set 1 boot on \
			mkpart primary linux-swap 1025MiB $(($ram_gb*1024 + 1025))MiB \
			mkpart primary ext4 $(($ram_gb*1024 + 1025))MiB 100%
	else
		# Create the partitions (one for boot and the other for LUKS)
		parted --script $1 mklabel msdos \
			mkpart primary ext4 1MiB 1025MiB \
			set 1 boot on \
			mkpart primary linux-swap 1025MiB $(($ram_gb*1024 + 1025))MiB \
			mkpart primary ext4 $(($ram_gb*1024 + 1025))MiB 100%
	fi
	# Create LUKS container
	cryptsetup luksFormat ${1}2
	# Open the LUKS container
	cryptsetup open ${1}2 cryptlvm

	# Prepare the LVM volumes
	pvcreate /dev/mapper/cryptlvm
	vgcreate RootVG /dev/mapper/cryptlvm
	# Create logical volume for SWAP (the size is the same as the RAM)
	lvcreate -L ${ram_gb}G RootVG -n SwapLV
	# Create logical volume for root
	lvcreate -l 100%FREE RootVG -n RootLV

	# Format the partitions
	if [ $uefi -eq 1 ]; then
		mkfs.fat -F32 ${1}1
	else
		mkfs.ext4 ${1}1
	fi
	mkfs.ext4 /dev/RootVG/RootLV
	mkswap /dev/RootVG/SwapLV
	
	# Mount the partitions
	mount /dev/RootVG/RootLV /mnt
	mount --mkdir ${1}1 /mnt/boot/EFI
	swapon /dev/RootVG/SwapLV
}

###############################################################################
# Function to partition the disks and LVM cache setup
###############################################################################

prepare_disk_cache_luks_on_lvm(){
	
	# Check if the number of params is correct
	if [ $# -lt 2 ]; then
		echo "Error: The number of params is incorrect."
		echo "Usage: prepare_disk_cache_luks_on_lvm <cache_disk> <storage_disk1> [<storage_disk2> ...]"
		exit 1
	fi

	# Process the params
	cache_disk=$1
	shift
	storage_disks=("$@")

	# Obtain teh GB of RAM for swap partition
	ram_gb=$(free --giga | awk '/Mem:/ {print $2}')

	# Check if the system is booted in UEFI mode
	check_boot_mode
	uefi=$?

	# Check if the system is UEFI booted
	if [ $uefi -eq 1 ]; then
		# Create the partitions for cache (one for boot, SWAP (GB of RAM) and the other for cache)
		parted --script $cache_disk mklabel gpt \
			mkpart primary fat32 1MiB 1025MiB \
			set 1 esp on \
			set 1 boot on \
			mkpart primary linux-swap 1025MiB $(($ram_gb*1024 + 1025))MiB \
			mkpart primary ext4 $(($ram_gb*1024 + 1025))MiB 100%

		# Creates the partitions for the rest of the disks
		for disk in ${storage_disks[@]}; do
			parted --script $disk mklabel gpt \
				mkpart primary ext4 1MiB 100%
		done
	else
		# Create the partitions (one for boot and the other for cache)
		parted --script $cache_disk mklabel msdos \
			mkpart primary ext4 1MiB 1025MiB \
			set 1 boot on \
			mkpart primary linux-swap 1025MiB $(($ram_gb*1024 + 1025))MiB \
			mkpart primary ext4 $(($ram_gb*1024 + 1025))MiB 100%
			
		# Creates the partitions for the rest of the disks
		for disk in ${storage_disks[@]}; do
			parted --script $disk mklabel msdos \
				mkpart primary ext4 1MiB 100%
		done
	fi

	# LVM setup for SWAP
	pvcreate ${cache_disk}2
	vgcreate SwapVG ${cache_disk}2
	lvcreate -l 100%FREE -n cryptswap SwapVG

	# LVM setup for Root
	pvcreate ${cache_disk}3
	# Create the physical volumes for the rest of the disks
	for disk in ${storage_disks[@]}; do
		pvcreate $disk
	done

	# Create the volume group for the cache
	vgcreate RootVG ${cache_disk}3 ${storage_disks[@]}1

	# Create the logical volumes for the root, only on the massives disks
	lvcreate -l 100%PVS -n cryptroot RootVG ${storage_disks[@]}1

	# Create the logical volume for the cache
	lvcreate --type cache-pool -l 100%PVS -n cryptroot_cache RootVG ${cache_disk}3

	# Combine the cache volume with the root volume
	lvconvert --type cache --cachemode writeback --cachepool RootVG/cryptroot_cache RootVG/cryptroot

	# Encryption setup
	cryptsetup luksFormat --type luks2 /dev/RootVG/cryptroot
	cryptsetup open /dev/RootVG/cryptroot root

	# Format the partitions
	mkfs.ext4 -L / /dev/mapper/root
	systemd-mount --discover /dev/mapper/root /mnt

	if [ $uefi -eq 1 ]; then
		mkfs.fat -F32 ${cache_disk}1
	else
		mkfs.ext4 ${cache_disk}1
	fi

	mkdir /mnt/boot
	systemd-mount ${cache_disk}1 /mnt/boot

}

###############################################################################
# Main function
###############################################################################

main(){
	clear
	echo "   _____                .__      __________                .___                 __         .__  .__   "
	echo "  /  _  \_______   ____ |  |__   \______   \_______   ____ |   | ____   _______/  |______  |  | |  |  "
	echo " /  /_\  \_  __ \_/ ___\|  |  \   |     ___/\_  __ \_/ __ \|   |/    \ /  ___/\   __\__  \ |  | |  |  "
	echo "/    |    \  | \/\  \___|   Y  \  |    |     |  | \/\  ___/|   |   |  \\___ \  |  |  / __ \|  |_|  |__"
	echo "\____|__  /__|    \___  >___|  /  |____|     |__|    \___  >___|___|  /____  > |__| (____  /____/____/"
	echo "        \/            \/     \/                          \/         \/     \/            \/            "
	echo ""
	echo "by Puchy (2023)"
	echo "-----------------------------------------------------"
	echo "This is the pre-installation set up script for Arch Linux."
	echo "Warning: Run this script at your own risk. The part of BIOS is not tested."
	echo "-----------------------------------------------------"
	echo ""

	# Set the keyboard layout
	loadkeys es

	# Check the boot mode
	check_boot_mode
	uefi=$?

	# Connect to internet

	echo "-----------------------------------------------------"
	echo "Connect to internet"
	echo "-----------------------------------------------------"

	# Loop until a valid option is selected
	while true; do
		# Select if wired or wireless
		echo "Select your connection type:"
		echo "1) Wired"
		echo "2) Wireless"
		echo "-----------------------------------------------------"
		read -p "Connection type [1-2]: " connection_type

		case $connection_type in
			1)
				# List available network interfaces
				echo "-----------------------------------------------------"
				echo "Available network interfaces:"
				echo "-----------------------------------------------------"
				ip link
				echo "-----------------------------------------------------"
				read -p "Enter the name of the interface to connect: " interface
				echo "-----------------------------------------------------"
				echo "Connecting to the network..."
				echo "-----------------------------------------------------"
				dhcpcd $interface
				echo "-----------------------------------------------------"
				echo "Connected!"
				echo "-----------------------------------------------------"
				break
				;;
			2)
				# List available network interfaces
				echo "-----------------------------------------------------"
				echo "Available network interfaces:"
				echo "-----------------------------------------------------"
				ip link
				echo "-----------------------------------------------------"
				read -p "Enter the name of the interface to connect: " interface
				echo "-----------------------------------------------------"
				echo "Connecting to the network..."
				echo "-----------------------------------------------------"
				# Enable the device and connect to the network
				iwctl device $interface set-property Powered on
				while true; do		
					# Scan networks
					iwctl station $interface scan
					echo "Wait 10 seconds to find the networks..."
					sleep 10
					# List available networks
					iwctl station $interface get-networks
					# Connect to the network
					read -p "Enter the name of the network to connect (or 'exit' to quit): " network

					# Check if the user wants to exit
					if [ "$network" = "exit" ]; then
						echo "Exiting the script."
						break
					fi

					# Try to connect to the network
					iwctl station $interface connect $network

					# Check if the connection was successful
					if [ $? -eq 0 ]; then
						echo "Connected to $network successfully."
						break
					else
						echo "Failed to connect to $network. Retrying..."
					fi
				done
				echo "-----------------------------------------------------"
				echo "Connected!"
				echo "-----------------------------------------------------"
				break
				;;
			*)
				echo "Invalid option. Please select 1 for Wired or 2 for Wireless."
				;;
		esac
	done

	# Update the system clock
	echo "-----------------------------------------------------"
	echo "Update the system clock"
	echo "-----------------------------------------------------"

	timedatectl set-ntp true

	# The installation will be encrypted (LUKS on LVM)

	# Lets the user choose to conitnue or not
	echo "-----------------------------------------------------"
	echo "The installation will be encrypted and the disk will be wiped."
	echo "-----------------------------------------------------"

	while true; do
		read -p "Do you want to continue? [Y/n]: " continue

		case $continue in
			"Y"|"y"|"")
				break
				;;
			"N"|"n")
				echo "-----------------------------------------------------"
				echo "Installation aborted."
				echo "-----------------------------------------------------"
				exit
				;;
			*)
				echo "Invalid option. Please select Y or N."
				;;
		esac
	done

	# Partition the disks
	echo "-----------------------------------------------------"
	echo "Partition the disks"
	echo "-----------------------------------------------------"

	# Check if there is one or more disks
	if [ $(lsblk -dplnx size -o name,size,fstype | grep -Ev "boot|rpmb|loop|iso" | wc -l) -eq 1 ]; then
		echo "-----------------------------------------------------"
		echo "There is only one disk."
		echo "-----------------------------------------------------"
		selected_disk=$(lsblk -dplnx size -o name,size,fstype | grep -Ev "boot|rpmb|loop|iso" | awk '{print $1}')
	else
		echo "-----------------------------------------------------"
		echo "There are more than one disk. Please select the disk to partition:"
		echo "-----------------------------------------------------"
		
		while true; do
			echo "Available disks:"
			lsblk -dplnx size -o name,size,fstype | grep -Ev "boot|rpmb|loop|iso" | tac

			read -p "Enter the name of the disk you want to use: " selected_disk

			if lsblk -dplnx size -o name,size,fstype | grep -Ev "boot|rpmb|loop|iso" | grep -wq "$selected_disk"; then
				# Enter the rest of disks in array
				rest_disks=($(lsblk -dplnx size -o name,fstype | grep -Ev "boot|rpmb|loop|iso|$selected_disk" | awk '{print $1}'))
				break
			else
				echo "Invalid disk name. Please try again."
			fi
		done
	fi

	echo "You have selected the disk: $selected_disk"

	# Prints the rest of the disks
	if [ ${#rest_disks[@]} -ne 0 ]; then
		echo "The rest of the disks are: ${rest_disks[@]}"
	fi

	# Wipe all the disks
	echo "-----------------------------------------------------"
	echo "Wiping the disks..."
	echo "-----------------------------------------------------"

	# Wipe the selected disk
	echo "-----------------------------------------------------"
	echo "Wiping the disk $selected_disk..."
	echo "-----------------------------------------------------"

	cryptsetup open --type plain -d /dev/urandom $selected_disk to_be_wiped
	dd if=/dev/zero of=/dev/mapper/to_be_wiped status=progress bs=1M
	cryptsetup close to_be_wiped

	# Wipe the rest of the disks
	if [ ${#rest_disks[@]} -ne 0 ]; then
		for disk in ${rest_disks[@]}; do
			echo "-----------------------------------------------------"
			echo "Wiping the disk $disk..."
			echo "-----------------------------------------------------"
			cryptsetup open --type plain -d /dev/urandom $disk to_be_wiped
			dd if=/dev/zero of=/dev/mapper/to_be_wiped status=progress bs=1M
			cryptsetup close to_be_wiped
		done
	fi

	# Create the partitions

	# Make a swith case to choose the partitioning scheme
	echo "-----------------------------------------------------"
	echo "Choose the partitioning scheme:"
	echo "-----------------------------------------------------"
	echo "1. LVM on LUKS (all in one disk)"
	echo "2. LUKS on LVM (SSD cache (principal disk) + HDD storage)"

	while true; do
		read -p "Enter the number of the partitioning scheme: " partitioning_scheme

		case $partitioning_scheme in
			1)
				echo "-----------------------------------------------------"
				echo "Installing... (LVM on LUKS)"
				echo "-----------------------------------------------------"
				prepare_disk_lvm_on_luks $selected_disk
				break
				;;
			2)
				echo "-----------------------------------------------------"
				echo "LUKS on LVM... (1 disk for cache + rest of disk for storage)"
				echo "-----------------------------------------------------"
				# Warn the principal disk will be used for cache, ask if continue
				echo "-----------------------------------------------------"
				echo "The principal disk selected before will be used for cache."
				echo "The rest of the disks will be used for storage."
				echo "Would you like to continue?"
				echo "-----------------------------------------------------"

				while true; do
					read -p "Do you want to continue? [Y/n]: " continue

					case $continue in
						"Y"|"y"|"")
							prepare_disk_cache_luks_on_lvm $selected_disk ${rest_disks[@]}
							break
							;;
						"N"|"n")
							echo "-----------------------------------------------------"
							echo "Installation aborted."
							echo "-----------------------------------------------------"
							exit
							;;
						*)
							echo "Invalid option. Please select Y or N."
							;;
					esac
				done

				break
				;;
			*)
				echo "Invalid option. Please select 1 or 2."
				;;
		esac
	done

	# Install essential packages
	echo "-----------------------------------------------------"
	echo "Installing essential packages..."
	echo "-----------------------------------------------------"

	pacstrap -K /mnt base base-devel linux linux-firmware neovim git networkmanager

	# Generate fstab
	echo "-----------------------------------------------------"
	echo "Generating fstab..."
	echo "-----------------------------------------------------"

	genfstab -U /mnt | tee /dev/stderr >> /mnt/etc/fstab

	# Copy auto scripts to the new system
	echo "-----------------------------------------------------"
	echo "Copying auto scripts to the new system..."
	echo "-----------------------------------------------------"

	cp -r /root/archinstall /mnt/root

	# Change root into the new system
	echo "-----------------------------------------------------"
	echo "Changing root into the new system..."
	echo "-----------------------------------------------------"

	arch-chroot /mnt
}

###############################################################################
# MAIN
###############################################################################
main
