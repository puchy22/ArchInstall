#!/bin/bash

# Function to configure the firewall

configure_firewall(){
	# Configure the firewall
	echo "-----------------------------------------------------"
	echo "Configuring the firewall..."
	echo "-----------------------------------------------------"

	# Create basic firewall configuration with nftables (https://wiki.archlinux.org/title/Nftables#Single_machine)

	# Flush the current ruleset

	nft flush ruleset

	# Create the tables and chains

	nft add table inet my_table

	nft add chain inet my_table my_input '{ type filter hook input priority 0 ; policy drop ; }'
	nft add chain inet my_table my_forward '{ type filter hook forward priority 0 ; policy drop ; }'
	nft add chain inet my_table my_output '{ type filter hook output priority 0 ; policy accept ; }'

	nft add chain inet my_table my_tcp_chain
	nft add chain inet my_table my_udp_chain

	# Add the rules

	# Related and established connections are accepted
	nft add rule inet my_table my_input ct state related,established accept
	# Loopback interface is accepted
	nft add rule inet my_table my_input iif lo accept
	# Invalid connections are dropped
	nft add rule inet my_table my_input ct state invalid drop
	# ICMP and IGMP are accepted
	nft add rule inet my_table my_input meta l4proto ipv6-icmp accept
	nft add rule inet my_table my_input meta l4proto icmp accept
	nft add rule inet my_table my_input ip protocol igmp accept
	# UDP traffic jump to chain my_udp_chain
	nft add rule inet my_table my_input meta l4proto udp ct state new jump my_udp_chain
	# TCP traffic jump to chain my_tcp_chain
	nft add rule inet my_table my_input 'meta l4proto tcp tcp flags & (fin|syn|rst|ack) == syn ct state new jump my_tcp_chain'
	# Other traffic is dropped
	nft add rule inet my_table my_input meta l4proto udp reject
	nft add rule inet my_table my_input meta l4proto tcp reject with tcp reset
	nft add rule inet my_table my_input counter reject with icmpx port-unreachable

	# Oppening ports example

	# HTTP
	# nft add rule inet my_table my_tcp_chain handle 88 tcp dport 80 accept
	# SSH
	# nft add rule inet my_table my_tcp_chain handle 22 tcp dport 22 accept

	# Remove open ports example
	# You have to get de handle number with: nft --handle --numeric list ruleset
	# nft delete rule inet my_table my_tcp_chain handle ?

	# Enable the firewall
	systemctl enable nftables.service

	# All rules are in /etc/nftables.conf

	nft list ruleset > /etc/nftables.conf

	# Reload the firewall
	systemctl restart nftables.service
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
		"nftables"        # Firewall
   )

   # Install the software

   echo "-----------------------------------------------------"
   echo "Installing the software..."
   echo "-----------------------------------------------------"

   sudo pacman -S --noconfirm "${software[@]}"

   # Some configurations

   echo "-----------------------------------------------------"
   echo "Configuring the login..."
   echo "-----------------------------------------------------"

   # Enter delay after a failed login attempt
	sed -i '/^auth/!b;n;n;a\auth optional pam_faildelay.so delay=4000000' /etc/pam.d/system-login

	# Lock the root account
	passwd -l root

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

}

# MAIN
main
