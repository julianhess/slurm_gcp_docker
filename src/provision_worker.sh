#!/bin/bash

/mnt/nfs/clust_scripts/nfs_provision_worker.sh
sudo munged -f
sudo slurmd -f /mnt/nfs/clust_conf/slurm/slurm.conf
