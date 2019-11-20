#!/bin/bash

set -e

/usr/local/share/cga_pipeline/src/nfs_provision_worker.sh $1

export SLURM_CONF=/mnt/nfs/clust_conf/slurm/slurm.conf

sudo munged -f
sudo -E slurmd -f /mnt/nfs/clust_conf/slurm/slurm.conf
