#!/bin/bash

set -e

/usr/local/share/cga_pipeline/src/nfs_provision_worker.sh $1
sudo munged -f
sudo slurmd -f /mnt/nfs/clust_conf/slurm/slurm.conf
