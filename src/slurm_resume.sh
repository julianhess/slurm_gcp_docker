#!/bin/bash

export SLURM_CONF=/mnt/nfs/clust_conf/slurm/slurm.conf

# get zone of instance
ZONE=$(/snap/bin/gcloud compute instances list --filter="name=${HOSTNAME}" \
  --format='csv[no-heading](zone)')

INST_LIST=$(scontrol show hostnames $@)

/snap/bin/gcloud compute instances start $INST_LIST --zone $ZONE
