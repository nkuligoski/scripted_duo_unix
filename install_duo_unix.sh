#!/usr/bin/bash
# Purpose: Assist administrators install Duo on CentOS and Ubuntu

# Capture Operating System
if [ lsb_release > /dev/null 2>&1 ]; then
    read OS <<< $(lsb_release -d | awk '/Description/')
    echo "$OS"
else
    echo "'lsb_release' package required to proceed"
    # Centos/Redhat: sudo yum install redhat-lsb-core
    # Ubuntu/Debian: sudo apt-get install lsb-core
    # Fedora: sudo dnf install redhat-lsb-core
    # OpenSUSE: sudo zypper install lsb-core
    # Arch: pacman -Syu lsb-release
    exit(0)
fi

# Will need to either shorten the OS variable to major system versions
# or use regex in the if statement so that it doesnt care about the minor version
if [ "$OS" =~ "Ubuntu 16.04.6 LTS" ]; then
	echo "Call 'ubuntu_duo' script"
else
	echo "Couldn't match on an OS"
fi