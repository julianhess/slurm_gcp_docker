#!/bin/bash

. /root/google-cloud-sdk/path.bash.inc

[ ! -d /run/sendsigs.omit.d ] && mkdir -p /run/sendsigs.omit.d
service rpcbind restart

[ ! -d /run/munge ] && mkdir -p /run/munge

mysqld &
cd /usr/local/share/cga_pipeline/src
./provision_server.py
/bin/bash
