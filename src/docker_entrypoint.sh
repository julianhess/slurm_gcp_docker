#!/bin/bash

. /root/google-cloud-sdk/path.bash.inc

[ ! -d /run/sendsigs.omit.d ] && sudo mkdir -p /run/sendsigs.omit.d
sudo service rpcbind restart

mysqld &
cd /usr/local/share/cga_pipeline/src
./provision_server.py
/bin/bash
