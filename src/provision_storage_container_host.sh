#!/bin/bash

export CLOUDSDK_CONFIG=/etc/gcloud

# initialize NFS server
/usr/local/share/cga_pipeline/src/nfs_provision_server.sh $1 $2

# start Slurm docker
docker run -dti --rm --network host -v /mnt/nfs:/mnt/nfs \
  --entrypoint /usr/local/share/cga_pipeline/src/slurm_start.sh --name slurm \
  broadinstitute/pydpiper
