#!/usr/bin/bash
# Purpose: Assist administrators install Duo on CentOS and Ubuntu

# Capture Operating System
if lsb_release > /dev/null 2>&1 ; then
    read OS <<< $(lsb_release -d | awk '/Description/')
    echo "{$OS}"
else
    echo "lsb_release package required to proceed"
    # Centos/Redhat - redhat-lsb-core
    # Ubuntu - sb-core
fi
