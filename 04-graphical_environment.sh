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

	# Let the user choose the drivers

	while true; do
		echo "-----------------------------------------------------"
		echo "Choose the drivers:"
		echo "-----------------------------------------------------"
		
		echo "1) Intel"
		echo "2) Nvidia"
		echo "3) PRIME render offload (intel + nvidia)"
		echo "4) Open source"
		echo "5) Virtual machine (qemu with qxl monitor)"
		echo "6) None"
		echo ""
		
		read -p "Option: " drivers

		case $drivers in
			1)
				# Intel drivers
				drivers=(
					"xf86-video-intel"	# Intel drivers
					"mesa"				# Open source version of OpenGL
					"lib32-mesa"
          "vulkan-intel"
          "lib32-vulkan-intel"
          "intel-media-driver"
          "libva-utils"
          "vdpauinfo"
          "clinfo"
          "intel-compute-runtime"
				)
				kernel_module="i915"
				break
				;;
			2)
				# Nvidia drivers
				drivers=(
					"nvidia"				# Nvidia drivers
					"nvidia-utils"		# Nvidia drivers
					"nvidia-settings"	# Nvidia drivers
					"nvidia-prime"		# Nvidia drivers
					"lib32-nvidia-utils"
          "opencl-nvidia"
				)
				kernel_module="nvidia nvidia_modeset nvidia_uvm nvidia_drm"
				break
				;;
			3)
				# PRIME render offload (use the dedicated GPU for specific applications)
				# Intel drivers
				drivers=(
					"xf86-video-intel"	# Intel drivers
					"mesa"				# Open source version of OpenGL
					"lib32-mesa"
          "vulkan-intel"
          "lib32-vulkan-intel"
          "intel-media-driver"
          "libva-utils"
          "vdpauinfo"
          "clinfo"
          "intel-compute-runtime"
					# Nvidia drivers
					"nvidia"				# Nvidia drivers
					"nvidia-utils"		# Nvidia drivers
					"nvidia-settings"	# Nvidia drivers
					"nvidia-prime"		# Nvidia drivers
					"lib32-nvidia-utils"
          "opencl-nvidia"
				)
				kernel_module="i915 nvidia nvidia_modeset nvidia_uvm nvidia_drm"
				break
				;;
			4)
				# Open source driver
				drivers=(
					"xf86-video-vesa"	# Open source driver
					"mesa"				# Open source version of OpenGL
				)
				kernel_module="vga bochs"
				break
				;;
			5)
				# Virtual machine (qemu with qxl monitor)
				drivers=(
					"xf86-video-qxl"
					"mesa"
				)
				kernel_module="qxl"
				break
				;;
			6)
				# None
				drivers=()
				break
				;;
			*)
				echo "Invalid option. Please choose a valid option."
				;;
		esac
	done

	# Modify the kernel parameters
	sudo sed -i "s/MODULES=()/MODULES=(${kernel_module})/" /etc/mkinitcpio.conf

	sudo sed -i "s/ kms//" /etc/mkinitcpio.conf

   # Make a list of the software to install

   software=(
		"xorg"				# Display server (xorg-server + xorg-apps)
		"arandr"				# Screen layout editor
		# Drivers
		"${drivers[@]}"		# Drivers
		# Windows manager
		"bspwm"						# Windows manager
		"sxhkd"						# Hotkey daemon
		"picom"						# Compositor
		"polybar"					# Status bar
		"rofi"						# Application launcher
		"feh"							# Wallpaper setter
		"lightdm"					# Display manager
		"lightdm-gtk-greeter"	# Display manager theme
		"light-locker"				# Screen locker
		"gtk3"						# GTK3
		"arc-gtk-theme"			# GTK3 theme
		"papirus-icon-theme"	# Papirus icon set
		"glxinfo"
		"vulkan-icd-loader"		# Vulkan Installable Client Driver (ICD) Loader
		"vulkan-tools"			# Vulkan Utilities and Tools
		"neofetch"
		"imagemagick"			# An image viewing/manipulation program
   )

   # Install the software

   echo "-----------------------------------------------------"
   echo "Installing the software..."
   echo "-----------------------------------------------------"

   sudo pacman -Syy --noconfirm "${software[@]}"

	# DRM kernel mode setting

	sudo mkinitcpio -P

	# Pray for not need extra configuration for Xorg

	# Change the greeter theme for lightdm

	echo "-----------------------------------------------------"
	echo "Changing the greeter theme for lightdm..."
	echo "-----------------------------------------------------"

	sudo sed -i "s/^#greeter-session=example-gtk-gnome/greeter-session=lightdm-gtk-greeter/" /etc/lightdm/lightdm.conf

	# Enable the display manager

	echo "-----------------------------------------------------"
	echo "Enabling the display manager..."
	echo "-----------------------------------------------------"

	sudo systemctl enable lightdm.service

	# Setting the keyboard layout

	echo "-----------------------------------------------------"
	echo "Setting the keyboard layout..."
	echo "-----------------------------------------------------"

	sudo localectl --no-convert set-x11-keymap es pc105 deadtilde

	# Config gtk theme

	echo "-----------------------------------------------------"
	echo "Setting the gtk theme and icons..."
	echo "-----------------------------------------------------"

	echo '[Settings]' >> /etc/gtk-3.0/settings.ini
	echo 'gtk-icon-theme-name = Papirus' >> /etc/gtk-3.0/settings.ini
	echo 'gtk-theme-name = Arc-Dark' >> /etc/gtk-3.0/settings.ini
	echo 'gtk-font-name = Mononoki Nerd Fonts 11' >> /etc/gtk-3.0/settings.ini

	# Setting rofi theme

	echo "-----------------------------------------------------"
	echo "Setting the rofi theme..."
	echo "-----------------------------------------------------"

	sudo wget https://raw.githubusercontent.com/davatorium/rofi-themes/master/Official%20Themes/Pop-Dark.rasi -O /usr/share/rofi/themes/Pop-Dark.rasi

	# Configuring NVChad

	git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1 && nvim

	# Copy the configuration files

	echo "-----------------------------------------------------"
	echo "Copying the configuration files..."
	echo "-----------------------------------------------------"

	cd $HOME
	
	git clone https://github.com/puchy22/dotfiles

	mv $HOME/.config .config2

	mv $HOME/dotfiles/* $HOME
	mv $HOME/dotfiles/.* $HOME

	rmdir $HOME/dotfiles

}

# MAIN
main
