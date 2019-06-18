#!/usr/bin/bash
# Purpose: Assist administrators install Duo on CentOS and Ubuntu

echo "Please enter your integration key: "
read integration_key

echo "Please enter your secret key: "
read secret_key

echo "Please enter your api hostname: "
read api_hostname

# Capture Operating System
if [ lsb_release > /dev/null 2>&1 ]; then
    read OS <<< $(lsb_release -d | awk '{ print $2,$3 }')
    echo "Detected: $OS"
else
    echo "'lsb_release' package required to proceed"
    # Centos/Redhat: sudo yum install redhat-lsb-core
    # Ubuntu/Debian: sudo apt-get install lsb-core
    # Fedora: sudo dnf install redhat-lsb-core
    # OpenSUSE: sudo zypper install lsb-core
    # Arch: pacman -Syu lsb-release
    exit 0
fi

if [ "$OS" = "Ubuntu 16.04.6" ]; then
	echo "Call 'ubuntu_duo' script (pass in Duo keys)"

	# Duo script 
	bash systems/ubuntu_duo.sh $integration_key $secret_key $api_hostname
elif [ "$OS" = "CentOS" ]; then
	echo "Call 'centos_duo' script"
else
	echo "Couldn't match on an OS"
fi