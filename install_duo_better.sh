#!/usr/bin/bash
# Purpose: Help administrators install Duo on Ubuntu 14.04, 16.04, or 18.04

get_operating_system () {
	hostnamectl | sed -n -e 's/^.*Operating System: //p' 
}

# Capture Operating System
OS=$(get_operating_system)

# Install pam_duo prerequisites
# Download and extract the latest version of duo_unix
# Build and install duo_unix with PAM support
# Update /etc/duo/pam_duo.conf with IKEY, SKEY, and HOST
# PubKey + Duo or Password + Duo?
# Configure /etc/pam.d/


if [ "$OS" = "Ubuntu 14.04 LTS" ]; then
	echo "Configuring Duo for $OS"
elif [ "$OS" = "Ubuntu 16.04 LTS" ]; then
	echo "Configuring Duo for $OS"
elif [ "$OS" = "Ubuntu 18.04.2 LTS" ]; then
	echo "Configuring Duo for $OS"
else
	echo "Doing other stuff"
fi

