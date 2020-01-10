#!/bin/bash

set -e

# mount NFS
/usr/local/share/cga_pipeline/src/nfs_provision_worker.sh ${1}-nfs

# start Slurm docker
docker run -dti --rm --network host -v /mnt/nfs:/mnt/nfs -v /sys/fs/cgroup:/sys/fs/cgroup \
  -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker \
  --entrypoint /usr/local/share/cga_pipeline/src/docker_entrypoint_worker.sh --name slurm \
  broadinstitute/pydpiper
