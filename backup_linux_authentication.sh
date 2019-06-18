#!/usr/bin/bash
# Purpose: Backup Linux authentication config

echo "This script will backup the system files used for authentication."

sleep 5

# Ask user if they want to backup or restore
echo "Would you like to backup or restore? [backup, restore]"

read response

if [ "$response" = "backup" ]; then
	# Backup SSH config file
	sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.default
	echo "Backed up sshd_config to: /etc/ssh/sshd_config.default"

	# Backup PAM files
	sudo cp /etc/pam.d/sshd /etc/pam.d/sshd.default
	echo "Backed up pam.d/sshd to: /etc/pam.d/sshd.default"

	sudo cp /etc/pam.d/common-auth /etc/pam.d/common-auth.default
	echo "Backed up pam.d/common-auth to: /etc/pam.d/common-auth.default"
elif [ "$response" = "restore" ]; then 
	# Restore SSH config file
	sudo cp /etc/ssh/sshd_config.default /etc/ssh/sshd_config
	echo "Restored sshd_config from: /etc/ssh/sshd_config.default"

	# Restore PAM files
	sudo cp /etc/pam.d/sshd.default /etc/pam.d/sshd
	echo "Restored pam.d/sshd from: /etc/pam.d/sshd"

	sudo cp /etc/pam.d/common-auth.default /etc/pam.d/common-auth
	echo "Restored pam.d/common-auth from: /etc/pam.d/common-auth"
else
	echo "Could not process response. Please enter 'backup' or 'restore'."
fi 