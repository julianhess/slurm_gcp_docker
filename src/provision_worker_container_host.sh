#!/bin/bash

set -e

# mount NFS
/usr/local/share/cga_pipeline/src/nfs_provision_worker.sh ${1}-nfs

# start Slurm docker
docker run -dti --rm --network host -v /mnt/nfs:/mnt/nfs \
  --entrypoint /usr/local/share/cga_pipeline/src/slurm_start.sh --name slurm \
  ${1}:5000/broadinstitute/pydpiper
