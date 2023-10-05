#!/bin/sh

# Function to configure the firewall

configure_firewall(){
	# Configure the firewall
	echo "-----------------------------------------------------"
	echo "Configuring the firewall..."
	echo "-----------------------------------------------------"

  sudo echo 'table inet my_table {
    chain my_input {
      type filter hook input priority filter; policy accept;
      iif "lo" accept comment "always accept loopback"
      iifname "wlo1" jump my_input_public
    }

    chain my_input_public {
      ct state { established, related } accept
      ct state invalid drop
      udp dport 68 accept
      tcp dport 68 accept
      reject comment "all other traffic"
    }

    chain my_output {
      type filter hook output priority filter; policy accept;
      accept
    }
  }' > /etc/nftables.conf

	# Reload the firewall
	sudo systemctl restart nftables.service
}

main(){
	clear
   echo "  _________                              .__   __            "
   echo " /   _____/  ____   ____   __ __ _______ |__|_/  |_  ___.__. "
   echo " \_____  \ _/ __ \_/ ___\ |  |  \\_  __ \|  |\   __\<   |  | "
   echo " /        \\  ___/\  \___ |  |  / |  | \/|  | |  |   \___  | "
   echo "/_______  / \___  >\___  >|____/  |__|   |__| |__|   / ____| "
   echo "        \/      \/     \/                            \/      "
	echo ""
	echo "by Puchy (2023)"
	echo "-----------------------------------------------------"
	echo "This install the software that I use to secure my systems and in my CTFs."
	echo "WARNING: This only install the software, secure a system is a more complex thing."
   echo "I recommend you to read the Arch Wiki for mor info: https://wiki.archlinux.org/title/Security"
	echo "-----------------------------------------------------"
	echo ""

   # Make a list of the software to install

   software=(
    "nmap"            # Network exploration tool and security / port scanner
    "wireshark-qt"    # Network protocol analyzer
    "bitwarden"       # Password manager
    "iptables-nft"    # Firewall
    "clamav"          # Antivirus
    "john"            # Password cracker
    "hashcat"         # Password cracker
    "zaproxy"			# Web application security scanner
    "hydra"				# Password cracker
    "traceroute"		# Traceroute utility
    "exploitdb"			# Offensive Security’s Exploit Database Archive (searchsploit)
    "gobuster"  # A directory/file & DNS busting tool.
    "webshells" # A collection of webshells for use in penetration testing
    "sqlmap"    # Automatic SQL injection and database takeover tool
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
      "whatweb"		# Web scanner
		  "burpsuite"	# Security testing of web applications
      "wordlists" # great set of wordlists. In /usr/share/wordlists
   )

   # Install the software from AUR

   echo "-----------------------------------------------------"
   echo "Installing the software from AUR..."
   echo "-----------------------------------------------------"

   paru -Syy --noconfirm "${aur_software[@]}"

   # Some configurations

   echo "-----------------------------------------------------"
   echo "Configuring the login..."
   echo "-----------------------------------------------------"

   # Enter delay after a failed login attempt
	sudo sed -i '/^auth/!b;n;n;a\auth optional pam_faildelay.so delay=4000000' /etc/pam.d/system-login

	# Lock the root account
  sudo passwd -l root

   # Question to the user if configure the firewall

   while true; do
		echo "-----------------------------------------------------"
      echo "Do you want to setup simple firewall configuration? (y/n)"
      echo "-----------------------------------------------------"
      read -r continue

		case $continue in
			"Y"|"y"|"")
            configure_firewall
				break
				;;
			"N"|"n")
				echo "-----------------------------------------------------"
				echo "Firewall configuration aborted."
				echo "-----------------------------------------------------"
				;;
			*)
				echo "Invalid option. Please select Y or N."
				;;
		esac
	done

	# Configure the antivirus

	echo "-----------------------------------------------------"
	echo "Configuring the antivirus..."
	echo "-----------------------------------------------------"

	# Update the antivirus database

	freshclam

	# Enable the antivirus

	sudo systemctl enable clamav-freshclam.service
	sudo systemctl enable clamav-daemon.service

	# Start the antivirus

	sudo systemctl start clamav-freshclam.service
	sudo systemctl start clamav-daemon.service

}

# MAIN
main
