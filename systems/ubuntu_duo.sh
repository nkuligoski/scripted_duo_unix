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
	# Check to see if this has already been downloaded (assumes home folder)
	if [ -f ~/duo_unix-latest.tar.gz ]; then
		echo "File already exists. Skipping."
	else
		echo "Downloading latest version of duo_unix to home folder (~/duo_unix-latest.tar.gz)"
		wget https://dl.duosecurity.com/duo_unix-latest.tar.gz -P ~/
	fi

	echo "Extracting duo_unix"
	tar zxf ~/duo_unix-latest.tar.gz

	echo "Changing into duo_unix directory"
	cd ~/duo_unix-*

	# Build and install duo_unix with PAM support
	echo "Building and installing duo_unix with PAM support"
	./configure --with-pam --prefix=/usr && make && sudo make install

	# Update /etc/duo/pam_duo.conf with IKEY, SKEY, and HOST
	# Check if file has already been configured
	if [ -f /etc/duo/pam_duo.conf ]; then

		# Check for integration key, secret key and hostname
		keys_check=`sudo grep "$ikey\|$skey\|$host" /etc/duo/pam_duo.conf`
		if [ "$keys_check" = "" ]; then
			echo "Configuring /etc/duo/pam_duo.conf with your Duo keys"
			sudo sed -i "s/^ikey = .*/ikey = $1/" /etc/duo/pam_duo.conf
			sudo sed -i "s/^skey = .*/skey = $2/" /etc/duo/pam_duo.conf
			sudo sed -i "s/^host = .*/host = $3/" /etc/duo/pam_duo.conf
			sudo cat /etc/duo/pam_duo.conf
		else
			echo "Looking like /etc/duo/pam_duo.conf is configured correctly"
			# sudo cat /etc/duo/pam_duo.conf
	else
		echo "File not found. Did ./configure fail?"
	fi

	# PubKey + Duo or Password + Duo
	while true; do

		echo "Do you currently leverage public-key or password authentication? [public-key/password]"
		read authentication

		if [ "$authentication" = "public-key" ]; then
			echo "Configuring machine for public-key + Duo"

			# Check PubkeyAuthentication parameters in /etc/ssh/sshd_config
			pubkey_authentication=`sudo grep PubkeyAuthentication /etc/ssh/sshd_config`
			password_authentication=`sudo grep PasswordAuthentication /etc/ssh/sshd_config`
			authentication_methods=`sudo grep AuthenticationMethods /etc/ssh/sshd_config`

			if [ "$pubkey_authentication" = "PubkeyAuthentication yes" ]; then 
				echo "PubkeyAuthentication parameter set correctly."; 
			else 
				# Remove PubkeyAuthentication line, then
				sudo sed -i '/PubkeyAuthentication/d' /etc/ssh/sshd_config
				# Append what we need to end of file
				echo "Replacing PubkeyAuthentication"
				sudo bash -c "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
			fi

			# Check PasswordAuthentication parameters in /etc/ssh/sshd_config
			if [ "$password_authentication" = "PasswordAuthentication no" ]; then
				echo "PasswordAuthentication parameter set correctly."
			else
				# Remove PasswordAuthentication line, then
				sudo sed -i '/PasswordAuthentication/d' /etc/ssh/sshd_config
				# Append what we need to end of file
				echo "Replacing PasswordAuthentication"
				sudo bash -c "PasswordAuthentication no" >> /etc/ssh/sshd_config
			fi

			# Check AuthenticationMethods parameters in /etc/ssh/sshd_config
			if [ "$authentication_methods" = "AuthenticationMethods publickey,keyboard-interactive" ]; then
				echo "AuthenticationMethods parameter set correctly."
			else
				# Try to remove AuthenticationMethods line, then
				sudo sed -i '/AuthenticationMethods/d' /etc/ssh/sshd_config
				# Append what we need to end of file
				echo "Replacing AuthenticationMethods"
				sudo bash -c "AuthenticationMethods publickey,keyboard-interactive" >> /etc/ssh/sshd_config
			fi

			break
		elif [ "$authentication" = "password" ]; then
			echo "Configuring machine for password + Duo"
			break
		else
			echo "Please enter 'public-key' or 'password'"
		fi
	done

	# Configure /etc/pam.d/
	# Required: All remaining modules are run, but the request will be denied if the required module fails.
	# Requisite: On failure, no remaining modules are run. On success, we keep going.
	# Sufficient: If no previously required modules failed, then on success we stop right away and 
	# return pass. If failure we keep going. Failure is not imminent though. If all required modules 
	# after this one pass the stack may pass.

	echo "Configuring pam.d files for $authentication"
	
elif [ "$continue" = "no" ]; then
	echo "Exiting"
	exit 0
else
	echo "Please enter 'yes' or 'no'."
fi
