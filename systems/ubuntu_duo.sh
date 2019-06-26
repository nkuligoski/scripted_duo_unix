#!/usr/bin/bash
# Purpose: Configure Ubuntu with primary authentication (pubkey or password) + Duo

# Print variables passed with script
echo "Integration key: $1"
echo "Secret key: $2"
echo "API Hostname: $3"

echo "Would you like to continue? [y/n]"
read continue

if [ "$continue" = "y" ]; then
	# Update apt repos
	sudo apt update

	# Install pam_duo prerequisites
	echo "Installing pam_duo prerequisites"
	sudo apt instal -y libssl-dev libpam-dev build-essential

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
	duo_unix_directory=$(find ~/ -name "duo_unix-*" -type d)
	cd $duo_unix_directory

	# Build and install duo_unix with PAM support
	if [ -d /lib64/security ]; then
		echo "pam_duo already configured."
	else
		echo "Building and installing duo_unix with PAM support"
		./configure --with-pam --prefix=/usr && make && sudo make install
	fi

	# Update /etc/duo/pam_duo.conf with IKEY, SKEY, and HOST
	# Check if file has already been configured
	if [ -f /etc/duo/pam_duo.conf ]; then

		# Check for integration key, secret key and hostname
		keys_check=`sudo grep '$ikey\|$skey\|$host' /etc/duo/pam_duo.conf`
		if [ "$keys_check" = "" ]; then
			echo "Configuring /etc/duo/pam_duo.conf with your Duo keys"
			sudo sed -i "s/^ikey = .*/ikey = $1/" /etc/duo/pam_duo.conf
			sudo sed -i "s/^skey = .*/skey = $2/" /etc/duo/pam_duo.conf
			sudo sed -i "s/^host = .*/host = $3/" /etc/duo/pam_duo.conf
			sudo cat /etc/duo/pam_duo.conf
		else
			echo "/etc/duo/pam_duo.conf is configured correctly"
			# sudo cat /etc/duo/pam_duo.conf
		fi
	else
		echo "File not found. Did ./configure fail?"
		exit 1
	fi

	# PubKey + Duo or Password + Duo
	echo "Which would you like to integrat Duo with?"
	options=("public-key" "password" "system-auth")
	select opt in "${options[@]}"; do
		case $opt in
			"public-key")
				echo "Configuring machine for public-key + Duo"

				# Verify that the system is configured for pubkey authentication first

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
					echo "PubkeyAuthentication yes" | sudo tee -a /etc/ssh/sshd_config
				fi

				# Check PasswordAuthentication parameter in /etc/ssh/sshd_config
				if [ "$password_authentication" = "PasswordAuthentication no" ]; then
					echo "PasswordAuthentication parameter set correctly."
				else
					# Remove PasswordAuthentication line, then
					sudo sed -i '/PasswordAuthentication/d' /etc/ssh/sshd_config
					# Append what we need to end of file
					echo "Replacing PasswordAuthentication"
					echo "PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config
				fi

				# Check AuthenticationMethods parameter in /etc/ssh/sshd_config
				if [ "$authentication_methods" = "AuthenticationMethods publickey,keyboard-interactive" ]; then
					echo "AuthenticationMethods parameter set correctly."
				else
					# Try to remove AuthenticationMethods line, then
					sudo sed -i '/AuthenticationMethods/d' /etc/ssh/sshd_config
					# Append what we need to end of file
					echo "Replacing AuthenticationMethods"
					echo "AuthenticationMethods publickey,keyboard-interactive" | sudo tee -a /etc/ssh/sshd_config
				fi

				# Check UsePAM parameter in /etc/ssh/sshd_config
				if [ "$use_pam" = "UsePAM yes" ]; then
					echo "UsePAM parameter set correctly."
				else
					# Try to remove UsePAM line, then
					sudo sed -i '/UsePAM/d' /etc/ssh/sshd_config
					# Append what we need to end of file
					echo "Replacing UsePAM"
					echo "UsePam yes" | sudo tee -a /etc/ssh/sshd_config
				fi

				# Check ChallengeResponseAuthentication parameter in /etc/ssh/sshd_config
				if [ "$challenge_response" = "ChallengeResponseAuthentication yes" ]; then
					echo "ChallengeResponseAuthentication parameter set correctly."
				else
					# Try to remove UseDNS line, then
					sudo sed -i '/ChallengeResponseAuthentication/d' /etc/ssh/sshd_config
					# Append what we need to end of file
					echo "Replacing ChallengeResponseAuthentication"
					echo "ChallengeResponseAuthentication yes" | sudo tee -a /etc/ssh/sshd_config
				fi

				# Check UseDNS parameter in /etc/ssh/sshd_config
				if [ "$use_dns" = "UseDNS no" ]; then
					echo "UseDNS parameter set correctly."
				else
					# Try to remove UseDNS line, then
					sudo sed -i '/UseDNS/d' /etc/ssh/sshd_config
					# Append what we need to end of file
					echo "Replacing UseDNS"
					echo "UseDNS no" | sudo tee -a /etc/ssh/sshd_config
				fi

				# Restart SSHD service to pick up changes
				sudo service sshd restart

				# Configure /etc/pam.d/sshd
				# Some logic to determine if pam_duo.so is in /lib64/security/ or /lib/security

				common_auth=`sudo grep common-auth /etc/pam.d/sshd`
				if [ "$common_auth" = "@include common-auth" ]; then
					echo "Configuring /etc/pam.d/sshd with pam_duo.so"
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
			;;
			"password")
				echo "Configuring machine for password + Duo"

				# Verify machine is configured for using SSH + password and not SSH + PubKey
				permit_root_login=`sudo grep 'PermitRootLogin prohibit-password' /etc/ssh/sshd_config`
				pubkey_authentication=`sudo grep PubkeyAuthentication /etc/ssh/sshd_config`
				password_authentication=`sudo grep PasswordAuthentication /etc/ssh/sshd_config`
				use_pam=`sudo grep UsePAM /etc/ssh/sshd_config`
				challenge_response=`sudo grep ChallengeResponseAuthentication /etc/ssh/sshd_config`
				use_dns=`sudo grep UseDNS /etc/ssh/sshd_config`

				# PermitRootLogin prohibit-password	(default)
				if [ "$permit_root_login" = "PermitRootLogin yes" ]; then 
					echo "PermitRootLogin parameter set correctly for password auth."; 
				else
					# Remove PermitRootLogin line, then
					sudo sed -i '/PermitRootLogin/d' /etc/ssh/sshd_config
					# Append what we need to end of file
					echo "Setting 'PermitRootLogin yes' in sshd_config"
					echo "PermitRootLogin yes" | sudo tee -a /etc/ssh/sshd_config
				fi

				# Check PubkeyAuthentication parameter in /etc/ssh/sshd_config
				if [ "$pubkey_authentication" = "PubkeyAuthentication no" ]; then 
					echo "PubkeyAuthentication parameter set correctly for password auth."; 
				else
					# Remove PubkeyAuthentication line, then
					sudo sed -i '/PubkeyAuthentication/d' /etc/ssh/sshd_config
					# Append what we need to end of file
					echo "Setting 'PubkeyAuthentication no' in sshd_config"
					echo "PubkeyAuthentication no" | sudo tee -a /etc/ssh/sshd_config
				fi

				# PasswordAuthentication no (default)
				if [ "$password_authentication" = "PasswordAuthentication yes" ]; then 
					echo "PasswordAuthentication parameter set correctly for password auth."; 
				else
					# Remove PasswordAuthentication line, then
					sudo sed -i '/PasswordAuthentication/d' /etc/ssh/sshd_config
					# Append what we need to end of file
					echo "Setting 'PasswordAuthentication yes' in sshd_config"
					echo "PasswordAuthentication yes" | sudo tee -a /etc/ssh/sshd_config
				fi

				# Check UsePAM parameter in /etc/ssh/sshd_config
				if [ "$use_pam" = "UsePAM yes" ]; then
					echo "UsePAM parameter set correctly."
				else
					# Try to remove UsePAM line, then
					sudo sed -i '/UsePAM/d' /etc/ssh/sshd_config
					# Append what we need to end of file
					echo "Setting 'UsePam yes' in sshd_config"
					echo "UsePam yes" | sudo tee -a /etc/ssh/sshd_config
				fi

				# Check ChallengeResponseAuthentication parameter in /etc/ssh/sshd_config
				if [ "$challenge_response" = "ChallengeResponseAuthentication yes" ]; then
					echo "ChallengeResponseAuthentication parameter set correctly."
				else
					# Try to remove UseDNS line, then
					sudo sed -i '/ChallengeResponseAuthentication/d' /etc/ssh/sshd_config
					# Append what we need to end of file
					echo "Setting 'ChallengeResponseAuthentication yes' in sshd_config"
					echo "ChallengeResponseAuthentication yes" | sudo tee -a /etc/ssh/sshd_config
				fi

				# Check UseDNS parameter in /etc/ssh/sshd_config
				if [ "$use_dns" = "UseDNS no" ]; then
					echo "UseDNS parameter set correctly."
				else
					# Try to remove UseDNS line, then
					sudo sed -i '/UseDNS/d' /etc/ssh/sshd_config
					# Append what we need to end of file
					echo "Setting 'UseDNS no' in sshd_config"
					echo "UseDNS no" | sudo tee -a /etc/ssh/sshd_config
				fi	

				# Restart SSHD service to pick up changes
				sudo service sshd restart

				# Configuring PAM with Duo
				echo "Configuring /etc/pam.d/common-auth with pam_duo.so"
				# Comment out existing auth line: auth [success=1 default=ignore] pam_unix.so nullok_secure
				sudo sed -i $"s/.*pam_unix.so.*/#auth [success=1 default=ignore] pam_unix.so nullok_secure\\nauth requisite pam_unix.so nullok_secure\\nauth [success=1 default=ignore] \/lib64\/security\/pam_duo.so/" /etc/pam.d/common-auth
			;;
			"system-auth")
				echo "Congifuring machine for system-auth + Duo"
			;; 
		esac
		break
	done

	echo "Time to test! Please do not close your current SSH session. Instead, open a new window and sign in."

elif [ "$continue" = "n" ]; then
	echo "Exiting"
	exit 0
else
	echo "Please enter 'y' or 'n'."
fi
