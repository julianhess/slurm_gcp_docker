#!/bin/bash

. /gcsdk/google-cloud-sdk/path.bash.inc

[ ! -d /run/munge ] && sudo mkdir -p /run/munge

sudo mysqld &
cd /usr/local/share/cga_pipeline/src
sudo -E ./provision_server.py
export SLURM_CONF=/mnt/nfs/clust_conf/slurm/slurm.conf
/bin/bash
