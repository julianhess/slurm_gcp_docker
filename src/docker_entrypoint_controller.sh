#!/bin/bash

. /gcsdk/google-cloud-sdk/path.bash.inc

sudo mysqld &
/usr/local/share/cga_pipeline/src/provision_server.py
export SLURM_CONF=/mnt/nfs/clust_conf/slurm/slurm.conf
/bin/bash
