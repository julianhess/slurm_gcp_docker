#!/bin/bash

[ ! -d /run/sendsigs.omit.d ] && sudo mkdir -p /run/sendsigs.omit.d
sudo service rpcbind restart

mysqld &
cd /usr/local/share/cga_pipeline/src
./provision_server.py
