#!/usr/bin/bash
# Purpose: Assist administrators install Duo on CentOS and Ubuntu

USAGE="Usage: $0 ikey skey api_host"

echo "This script will layer Duo on top of your public-key or password authentication"

if [ "$1" = "" ]; then
	echo "$USAGE"
	exit 1
elif [ "$2" = "" ]; then
	echo "$USAGE"
	exit 1
elif [ "$3" = "" ]; then
	echo "$USAGE"
	exit 1
fi

integration_key=$1
secret_key=$2
api_hostname=$3

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

if [[ "$os" =~ (16.04)+ ]]; then
	echo "Calling 'ubuntu_duo' script. Sending along Duo keys and OS version."
	bash systems/ubuntu_duo.sh $integration_key $secret_key $api_hostname
elif [ "$os" = "CentOS" ]; then
	echo "Call 'centos_duo' script"
else
	echo "Couldn't match on an OS"
fi