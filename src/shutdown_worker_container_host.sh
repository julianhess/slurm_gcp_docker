#!/bin/bash

# alert controller that this host is being preempted; set status to fail
docker exec slurm scontrol update nodename=$HOSTNAME state=FAIL reason="preempted" && \
docker exec slurm scontrol update nodename=$HOSTNAME state=DOWN reason="preempted" && \
docker exec slurm scontrol update nodename=$HOSTNAME state=POWER_DOWN reason="powerdown"

#
# detach any RO disks

# get zone of instance
export CLOUDSDK_CONFIG=/etc/gcloud
ZONE=$(gcloud compute instances list --filter="name=${HOSTNAME}" \
  --format='csv[no-heading](zone)')

# detach all RO disks
ls -1 /dev/disk/by-id/google-gsdisk* | grep -o 'gsdisk-.*$' | \
  xargs -I {} -n 1 -P 0 gcloud compute instances detach-disk $HOSTNAME --device-name {} --zone $ZONE
