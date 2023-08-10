#!/bin/sh

main(){
	clear
   echo "  ________                        .__     .__                 .__       ___________              .__                                                   __    "
   echo " /  _____/_______ _____   ______  |  |__  |__|  ____  _____   |  |      \_   _____/  ____ ___  __|__|_______   ____    ____    _____    ____    ____ _/  |_  "
   echo "/   \  ___\_  __ \\__  \  \____ \ |  |  \ |  |_/ ___\ \__  \  |  |       |    __)_  /    \\  \/ /|  |\_  __ \ /  _ \  /    \  /     \ _/ __ \  /    \\   __\ "
   echo "\    \_\  \|  | \/ / __ \_|  |_> >|   Y  \|  |\  \___  / __ \_|  |__     |        \|   |  \\   / |  | |  | \/(  <_> )|   |  \|  Y Y  \\  ___/ |   |  \|  |   "
   echo " \______  /|__|   (____  /|   __/ |___|  /|__| \___  >(____  /|____/    /_______  /|___|  / \_/  |__| |__|    \____/ |___|  /|__|_|  / \___  >|___|  /|__|   "
   echo "        \/             \/ |__|         \/          \/      \/                   \/      \/                                \/       \/      \/      \/        "
	echo ""
	echo "by Puchy (2023)"
	echo "-----------------------------------------------------"
	echo "This install the graphical user interface that I use."
	echo "For now is make for bspwm."
	echo "WARNING: I use X11 as display server, in my opinion it is worse than Wayland in security terms."
	echo "In a future I would like to use Wayland and river or Qtile as compositor."
	echo "-----------------------------------------------------"
	echo ""

   # Make a list of the software to install

   software=(
		"xorg"				# Display server (xorg-server + xorg-apps)
		"autorandr"			# Automatic screen configuration (https://linuxconfig.org/how-to-automatically-change-x11-displays-setup-with-autorandr-on-linux)
		"arandr"				# Screen configuration
		# PRIME render offload (use the dedicated GPU for specific applications)
		# Intel drivers
		"xf86-video-intel"	# Intel drivers
		"mesa"				# Open source version of OpenGL
		# Nvidia drivers
		"nvidia"				# Nvidia drivers
		"nvidia-utils"		# Nvidia drivers
		"nvidia-settings"	# Nvidia drivers
		"nvidia-prime"		# Nvidia drivers
		# Open source driver
		"xf86-video-vesa"	# Open source driver
		# Windows manager
		"bspwm"				# Windows manager
		"sxhkd"				# Hotkey daemon
		"picom"				# Compositor
		"polybar"			# Status bar
		"rofi"				# Application launcher
		"feh"					# Wallpaper setter
		"lightdm"			# Display manager
		"light-locker"		# Screen locker
		"xdg-user-dirs"	# Create user directories
   )

   # Install the software

   echo "-----------------------------------------------------"
   echo "Installing the software..."
   echo "-----------------------------------------------------"

   sudo pacman -S --noconfirm "${software[@]}"

	# DRM kernel mode setting

	echo "-----------------------------------------------------"
	echo "Configuring DRM kernel mode setting..."
	echo "-----------------------------------------------------"

	sed -i '
	/^HOOKS=/ {
		# use nvidia
		s/filesystems/filesystems nvidia nvidia_modeset nvidia_uvm nvidia_drm/
	}
	' /etc/mkinitcpio.conf

	mkinitcpio -P

	# Pray for not need extra configuration for Xorg

	# Enable the display manager

	echo "-----------------------------------------------------"
	echo "Enabling the display manager..."
	echo "-----------------------------------------------------"

	sudo systemctl enable lightdm.service

	# Create user directories

	echo "-----------------------------------------------------"
	echo "Creating user directories..."
	echo "-----------------------------------------------------"

	xdg-user-dirs-update

	# Copy the configuration files

	echo "-----------------------------------------------------"
	echo "Copying the configuration files..."
	echo "-----------------------------------------------------"

	git clone https://github.com/puchy22/dotfiles $HOME

}

# MAIN
main
