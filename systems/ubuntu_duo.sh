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
	sudo apt install libssl-dev libpam-dev build-essential

	# Download and extract the latest version of duo_unix
	# Check to see if this has already been downloaded (assumes home folder)
	if [ -f ~/duo_unix-latest.tar.gz ]; then
		echo "File already exists. Skipping."
	else
		echo "Downloading latest version of duo_unix to home folder (~/duo_unix-latest.tar.gz)"
		wget https://dl.duosecurity.com/duo_unix-latest.tar.gz -P ~/
	fi

	echo "Extracting duo_unix"
	tar zxf ~/duo_unix-latest.tar.gz -C ~/

	echo "Changing into duo_unix directory"
	cd ~/duo_unix-*

	# Build and install duo_unix with PAM support
	echo "Building and installing duo_unix with PAM support"
	./configure --with-pam --prefix=/usr && make && sudo make install

	# Update /etc/duo/pam_duo.conf with IKEY, SKEY, and HOST
	# Check if file has already been configured
	if [ -f /etc/duo/pam_duo.conf ]; then

		# Check for integration key, secret key and hostname
		keys_check=`sudo grep '$ikey\|$skey\|$host' /etc/duo/pam_duo.conf`
		if [ "$keys_check" = "" ]; then
			echo "Configuring /etc/duo/pam_duo.conf with your Duo keys"
			sudo sed -i 's/^ikey = .*/ikey = $1/' /etc/duo/pam_duo.conf
			sudo sed -i 's/^skey = .*/skey = $2/' /etc/duo/pam_duo.conf
			sudo sed -i 's/^host = .*/host = $3/' /etc/duo/pam_duo.conf
			sudo cat /etc/duo/pam_duo.conf
		else
			echo "/etc/duo/pam_duo.conf is configured correctly"
			# sudo cat /etc/duo/pam_duo.conf
		fi
	else
		echo "File not found. Did ./configure fail?"
	fi

	# PubKey + Duo or Password + Duo
	while true; do

		echo "Do you currently leverage public-key or password authentication? [public-key/password]"
		read authentication

		if [ "$authentication" = "public-key" ]; then
			echo "Configuring machine for public-key + Duo"

			# Create variables to check sshd_config parameters against
			pubkey_authentication=`sudo grep PubkeyAuthentication /etc/ssh/sshd_config`
			password_authentication=`sudo grep PasswordAuthentication /etc/ssh/sshd_config`
			authentication_methods=`sudo grep AuthenticationMethods /etc/ssh/sshd_config`
			use_pam=`sudo grep UsePAM /etc/ssh/sshd_config`
			challenge_response=`sudo grep ChallengeResponseAuthentication /etc/ssh/sshd_config`
			use_dns=`sudo grep UseDNS /etc/ssh/sshd_config`

			# Check PubkeyAuthentication parameter in /etc/ssh/sshd_config
			if [ "$pubkey_authentication" = "PubkeyAuthentication yes" ]; then 
				echo "PubkeyAuthentication parameter set correctly."; 
			else 
				# Remove PubkeyAuthentication line, then
				sudo sed -i '/PubkeyAuthentication/d' /etc/ssh/sshd_config
				# Append what we need to end of file
				echo "Replacing PubkeyAuthentication"
				sudo bash -c "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
			fi

			# Check PasswordAuthentication parameter in /etc/ssh/sshd_config
			if [ "$password_authentication" = "PasswordAuthentication no" ]; then
				echo "PasswordAuthentication parameter set correctly."
			else
				# Remove PasswordAuthentication line, then
				sudo sed -i '/PasswordAuthentication/d' /etc/ssh/sshd_config
				# Append what we need to end of file
				echo "Replacing PasswordAuthentication"
				sudo bash -c "PasswordAuthentication no" >> /etc/ssh/sshd_config
			fi

			# Check AuthenticationMethods parameter in /etc/ssh/sshd_config
			if [ "$authentication_methods" = "AuthenticationMethods publickey,keyboard-interactive" ]; then
				echo "AuthenticationMethods parameter set correctly."
			else
				# Try to remove AuthenticationMethods line, then
				sudo sed -i '/AuthenticationMethods/d' /etc/ssh/sshd_config
				# Append what we need to end of file
				echo "Replacing AuthenticationMethods"
				sudo bash -c "AuthenticationMethods publickey,keyboard-interactive" >> /etc/ssh/sshd_config
			fi

			# Check UsePAM parameter in /etc/ssh/sshd_config
			if [ "$use_pam" = "UsePAM yes" ]; then
				echo "UsePAM parameter set correctly."
			else
				# Try to remove UsePAM line, then
				sudo sed -i '/UsePAM/d' /etc/ssh/sshd_config
				# Append what we need to end of file
				echo "Replacing UsePAM"
				sudo bash -c "UsePam yes" >> /etc/ssh/sshd_config
			fi

			# Check ChallengeResponseAuthentication parameter in /etc/ssh/sshd_config
			if [ "$challenge_response" = "ChallengeResponseAuthentication yes" ]; then
				echo "ChallengeResponseAuthentication parameter set correctly."
			else
				# Try to remove UseDNS line, then
				sudo sed -i '/ChallengeResponseAuthentication/d' /etc/ssh/sshd_config
				# Append what we need to end of file
				echo "Replacing ChallengeResponseAuthentication"
				sudo bash -c "ChallengeResponseAuthentication yes" >> /etc/ssh/sshd_config
			fi

			# Check UseDNS parameter in /etc/ssh/sshd_config
			if [ "$use_dns" = "UseDNS no" ]; then
				echo "UseDNS parameter set correctly."
			else
				# Try to remove UseDNS line, then
				sudo sed -i '/UseDNS/d' /etc/ssh/sshd_config
				# Append what we need to end of file
				echo "Replacing UseDNS"
				sudo bash -c "UseDNS no" >> /etc/ssh/sshd_config
			fi

			# Configure /etc/pam.d/sshd
			# Required: All remaining modules are run, but the request will be denied if the required module fails.
			# Requisite: On failure, no remaining modules are run. On success, we keep going.
			# Sufficient: If no previously required modules failed, then on success we stop right away and 
			# return pass. If failure we keep going. Failure is not imminent though. If all required modules 
			# after this one pass the stack may pass.

			# Some logic to determine if pam_duo.so is in /lib64/security/ or /lib/security

			common_auth=`sudo grep common-auth /etc/pam.d/sshd`
			if [ "$common_auth" = "@include common-auth" ]; then
				# Comment out: @include common-auth
				sudo sed -i "s/@include common-auth/#@include common-auth/" /etc/pam.d/sshd
				# Add Duo lines
				sudo sed -i '/#@include common-auth/a auth  [success=1 default=ignore] /lib64/security/pam_duo.so' /etc/pam.d/sshd
				sudo sed -i '/pam_duo.so/a auth  requisite pam_deny.so' /etc/pam.d/sshd
				sudo sed -i '/pam_deny.so/a auth  required pam_permit.so' /etc/pam.d/sshd
			elif [ "$common_auth" = "#@include common-auth" ]; then
				echo "Line in /etc/pam.d/sshd already commented out."
			else
				echo "Could not find @include common-auth"
			fi


			echo "Configuring pam.d files for $authentication authentication"

			break
		elif [ "$authentication" = "password" ]; then
			echo "Configuring machine for password + Duo"
			break
		else
			echo "Please enter 'public-key' or 'password'"
		fi
	done

	echo "Time to test! Please do not close your current SSH session. Instead, open a new window and sign in."

elif [ "$continue" = "no" ]; then
	echo "Exiting"
	exit 0
else
	echo "Please enter 'yes' or 'no'."
fi
