#!/bin/sh

#!/bin/sh

main(){
	clear
   echo "__________                 __   .___                   __           .__   .__    "
   echo "\______   \ ____   _______/  |_ |   |  ____    _______/  |_ _____   |  |  |  |   "
   echo " |     ___//  _ \ /  ___/\   __\|   | /    \  /  ___/\   __\\__  \  |  |  |  |   "
   echo " |    |   (  <_> )\___ \  |  |  |   ||   |  \ \___ \  |  |   / __ \_|  |__|  |__ "
   echo " |____|    \____//____  > |__|  |___||___|  //____  > |__|  (____  /|____/|____/ "
   echo "                      \/                  \/      \/             \/               "
	echo ""
	echo "by Puchy (2023)"
	echo "-----------------------------------------------------"
	echo "This install the software that I usually need for the college and personal projects."
	echo "WARNING: Recommend to install with the graphical environment in order to use this correctly."
	echo "-----------------------------------------------------"
	echo ""

   # Install AUR helper

   echo "-----------------------------------------------------"
   echo "Installing paru..."
   echo "-----------------------------------------------------"

   cd /tmp
   git clone https://aur.archlinux.org/paru.git
   cd paru
   makepkg -si
   cd $HOME

   # Install blackarch repository

   echo "-----------------------------------------------------"
   echo "Installing blackarch repository..."
   echo "-----------------------------------------------------"

   mkdir /tmp/blackarch
   cd /tmp/blackarch
   curl -O https://blackarch.org/strap.sh
   chmod +x strap.sh
   sudo ./strap.sh
   cd $HOME
   sudo pacman -Syy

   # Enable multilib repositories

   #sudo sed -i 's/#[multilib]/[multilib]/g' /etc/pacman.conf
   #sudo sed -i 's/#Include/Include/g' /etc/pacman.conf  FIX THIS

   # Make a list of the software to install
   # https://wiki.archlinux.org/title/List_of_applications

   software=(
      "chromium"		         # Browser
      "rclone"		            # Cloud sync https://wiki.archlinux.org/title/Synchronization_and_backup_programs
      "filezilla"		         # FTP client
      "flameshot"		         # Screenshot tool
      "pulseaudio"            # Soundo system
      "pulseaudio-alsa"       # Pulseaudio to manage ALSA drivers
      "pulseaudio-bluetooth"  # Pulseaudio to manage ALSA drivers
      "pavucontrol"           # Pulseaudio frontend
      "alsa-utils"            # ALSA utilities
      "haruna"                # Music and video player
      "kitty"			         # Terminal emulator
      "thunar"			         # File manager
      "gvfs"                  # Virtual file system (Thunar)
      "thunar-archive-plugin" # Adds archive operations to the Thunar file context menus
      "xarchiver"             # Archive manager (Thunar)
      "thunar-volman"         # Thunar volume manager (Thunar)
      "rsync"                 # File sync
      "tar"                   # File compression
      "unzip"                 # File compression
      "zip"                   # File compression
      "unrar"                 # File compression
      "p7zip"                 # File compression
      "findutils"             # File search
      "code"                  # Code editor
      "htop"                  # System monitor
      "conky"                 # System monitor
      "qemu-desktop"          # Virtualization (KVM)
      "libvirt"               # Virtualization API
      "virt-manager"          # Virtualization manager
      "dnsmasq"               # Virtualization networking (DHCP and DNS)
      "openbsd-netcat"        # Virtualization management SSH
      "vde2"                  # Virtualization networking
      "bridge-utils"          # Virtualization networking
      "okular"                # PDF reader
      "obsidian"              # Notes
      "gimp"                  # Image editor
      "wget"                  # Download manager
      "discord"               # Chat
      "neofetch"              # System info
      "networkmanager-openconnect" # VPN (cisco, paloalto, etc)
      "networkmanager-openvpn" # VPN (openvpn)
      "network-manager-applet"   # Network manager applet
      "python"                # Python
      "npm"
      # LaTeX installation (https://wiki.archlinux.org/title/TeX_Live)
      "tree"                  # Tree view
      "lsd"                   # ls with icons
      "bat"                   # cat with syntax highlight
      "zsh"                   # Shell
      "zsh-autosuggestions"   # ZSH command complete
      "zsh-syntax-highlighting"  # Fish shell like syntax highlighting for Zsh
      "thefuck"               # Fix commands wrote
      "fzf"                   # General-purpose command-line fuzzy finder
      "podman"                # Container manager
      "buildah"               # Container builder
      "fuse-overlayfs"        # Container overlay
      "netavark"              # Container networking
      "aardvark-dns"          # DNS for containers
      "podman-compose"        # Container compose
      "slirp4netns"           # Container networking rootless
      "wmname"                # A utility to set the name of your window manager

   )

   # Install the software

   echo "-----------------------------------------------------"
   echo "Installing the software..."
   echo "-----------------------------------------------------"

   sudo pacman -Syy --noconfirm "${software[@]}"

   # Prepare the software necesary from AUR

   echo "-----------------------------------------------------"
   echo "Preparing the software from AUR..."
   echo "-----------------------------------------------------"

   aur_software=(
      "librewolf-bin"   # Browser
      "notion-app"      # Notes
   )

   # Install the software from AUR

   echo "-----------------------------------------------------"
   echo "Installing the software from AUR..."
   echo "-----------------------------------------------------"

   paru -Syy --noconfirm "${aur_software[@]}"

   # Install some nerd fonts

   echo "-----------------------------------------------------"
   echo "Installing some nerd fonts..."
   echo "-----------------------------------------------------"

   wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Mononoki.zip -P /tmp
   unzip /tmp/Mononoki.zip -d /tmp
   sudo cp /tmp/*.ttf /usr/share/fonts/

   wget https://github.com/be5invis/Iosevka/releases/download/v26.2.1/super-ttc-iosevka-26.2.1.zip -P /tmp

   sudo pacman -S --noconfirm ttf-iosevka-nerd

   # QEMU/KVM configuration

   echo "-----------------------------------------------------"
   echo "Configuring QEMU/KVM..."
   echo "-----------------------------------------------------"

   sudo systemctl enable libvirtd.service
   sudo systemctl start libvirtd.service

   # Add user to the libvirt group

   sudo usermod -aG libvirt $USER

   # Configure for puchy a zsh terminal

   echo "-----------------------------------------------------"
   echo "Configuring zsh as principal shell..."
   echo "-----------------------------------------------------"

   sudo chsh -s /usr/bin/zsh $USER

   # Podman rootless config

   echo "-----------------------------------------------------"
   echo "Configuring podman rootless..."
   echo "-----------------------------------------------------"

   podman system reset

   sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 $USER

   podman system migrate

   # Configure audio
   echo "-----------------------------------------------------"
   echo "Configuring audio..."
   echo "-----------------------------------------------------"

   amixer sset Master unmute

}

# MAIN
main
