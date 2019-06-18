# Scripted Duo Unix

### Objective

Make it easier for administrators to integrate Duo to their Linux systems.

### Approach

1. Capture current operating system
2. Install pam_duo prerequisites
3. Download and extract the latest version of duo_unix
4. Build and install duo_unix with PAM support
5. Update /etc/duo/pam_duo.conf with IKEY, SKEY, and HOST
6. PubKey + Duo or Password + Duo?
7. Configure /etc/pam.d/ appropriately

### Usage
1. Please utilize the `backup_linux_authentication.sh` script to backup first.
2. Run install_duo_unix.sh and follow the prompts.