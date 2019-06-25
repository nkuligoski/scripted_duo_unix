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
    read os <<< $(lsb_release -d | awk '{ print $2,$3 }')
    echo "Detected: $os"
else
    echo "'lsb_release' package required to proceed"
    # Centos/Redhat: sudo yum install redhat-lsb-core
    # Ubuntu/Debian: sudo apt-get install lsb-core
    # Fedora: sudo dnf install redhat-lsb-core
    # OpenSUSE: sudo zypper install lsb-core
    # Arch: pacman -Syu lsb-release
    exit 0
fi

if [ "$os" = "Ubuntu 16.04.6" ]; then
	echo "Calling 'ubuntu_duo' script. Sending along Duo keys and OS version."
	bash systems/ubuntu_duo.sh $integration_key $secret_key $api_hostname $os
elif [ "$os" = "CentOS" ]; then
	echo "Call 'centos_duo' script"
else
	echo "Couldn't match on an OS"
fi