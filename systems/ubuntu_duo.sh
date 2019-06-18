#!/usr/bin/bash
# Purpose: Configure Ubuntu with primary authentication (pubkey or password) + Duo

# Install pam_duo prerequisites
# Download and extract the latest version of duo_unix
# Build and install duo_unix with PAM support
# Update /etc/duo/pam_duo.conf with IKEY, SKEY, and HOST
# PubKey + Duo or Password + Duo?
# Configure /etc/pam.d/
