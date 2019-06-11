#!/usr/bin/bash

# Integration key, Secret key, and API Hostname
INTEGRATION_KEY=xxxxxxxxxx
SECRET_KEY=xxxxxxxxxxxxxx
API_HOSTNAME=api-xxxxxxx.duosecurity.com

# Update and upgrade  machine (assume yes to all questions)
sudo yum update -y

# Install pam_duo prerequisites
sudo yum install -y openssl-devel pam-devel wget
sudo yum group install -y "Development Tools"

# Install pam_duo
wget https://dl.duosecurity.com/duo_unix-latest.tar.gz
tar zxf duo_unix-latest.tar.gz
cd duo_unix-1.11.1
./configure --with-pam --prefix=/usr && make && sudo make install

# Configure /etc/duo/pam_duo.conf with Duo application keys
sudo sed -i "s/^ikey = .*/ikey = $INTEGRATION_KEY/" /etc/duo/pam_duo.conf
sudo sed -i "s/^skey = .*/skey = $SECRET_KEY/" /etc/duo/pam_duo.conf
sudo sed -i "s/^host = .*/host = $API_HOSTNAME/" /etc/duo/pam_duo.conf
sudo cat /etc/duo/pam_duo.conf

# Switch PubkeyAuthentication to yes
sudo sed -i "s/#PubkeyAuthentication yes/PubkeyAuthentication yes/" /etc/ssh/sshd_config

# Check PasswordAuthentication (default is no)

# Switch ChallengeResponseAuthentication to yes
sudo sed -i "s/^#ChallengeResponseAuthentication yes.*/ChallengeResponseAuthentication yes/" /etc/ssh/sshd_config
sudo sed -i "s/^ChallengeResponseAuthentication no.*/#ChallengeResponseAuthentication no/" /etc/ssh/sshd_config

# Enable AuthenticationMethods and place it after ChallengeResponseAuthentication
sudo sed -i "/^ChallengeResponseAuthentication yes.*/a AuthenticationMethods publickey,keyboard-interactive" /etc/ssh/sshd_config

# Check UsePAM (default is yes)

# Switch UseDNS to no (default is yes but commented out)
sudo sed -i "s/^#UseDNS yes.*/UseDNS no/" /etc/ssh/sshd_config

# Configure SSH Public Key Authentication
sudo sed -i '3 s/^/#/' /etc/pam.d/sshd
sudo sed -i "/^#auth.*/a auth required pam_env.so\nauth sufficient /lib64/security/pam_duo.so\nauth required pam_deny.so" /etc/pam.d/sshd

# SE Linux
cd duo_unix-1.11.1
sudo make -C pam_duo semodule
sudo make -C pam_duo semodule-install
sudo semodule -l | grep duo

# Restart SSH service
sudo service sshd restart