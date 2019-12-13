#!/bin/bash

. /root/google-cloud-sdk/path.bash.inc

[ ! -d /run/munge ] && mkdir -p /run/munge

mysqld &
cd /usr/local/share/cga_pipeline/src
./provision_server.py
export SLURM_CONF=/mnt/nfs/clust_conf/slurm/slurm.conf
/bin/bash
