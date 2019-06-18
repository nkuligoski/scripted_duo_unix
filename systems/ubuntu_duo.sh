#!/usr/bin/bash
# Purpose: Configure Ubuntu with primary authentication (pubkey or password) + Duo

# Print variables passed with script
echo "Integration key: $1"
echo "Secret key: $2"
echo "API Hostname: $3"

echo "Would you like to continue? [yes/no]"
read continue

if [ "$continue" = "yes" ]; then
	# Install pam_duo prerequisites
	echo "Installing pam_duo prerequisites"
	sudo apt install libssl-dev libpam-dev gcc

	# Download and extract the latest version of duo_unix
	echo "Downloading latest version of duo_unix"
	wget https://dl.duosecurity.com/duo_unix-latest.tar.gz

	echo "Extracting duo_unix"
	tar zxf duo_unix-latest.tar.gz

	echo "Changing into duo_unix directory"
	cd duo_unix-*

	# Build and install duo_unix with PAM support
	echo "Building and installing duo_unix with PAM support"
	./configure --with-pam --prefix=/usr && make && sudo make install

	# Update /etc/duo/pam_duo.conf with IKEY, SKEY, and HOST
	# echo "Configuring /etc/duo/pam_duo.conf with your Duo keys"
	# sudo sed -i "s/^ikey = .*/ikey = $INTEGRATION_KEY/" /etc/duo/pam_duo.conf
	# sudo sed -i "s/^skey = .*/skey = $SECRET_KEY/" /etc/duo/pam_duo.conf
	# sudo sed -i "s/^host = .*/host = $API_HOSTNAME/" /etc/duo/pam_duo.conf
	# sudo cat /etc/duo/pam_duo.conf

	# PubKey + Duo or Password + Duo?
	# Configure /etc/pam.d/
elif [ "$continue" = "no" ]; then
	echo "Exiting"
	exit 0
else
	echo "Please enter 'yes' or 'no'."
fi
