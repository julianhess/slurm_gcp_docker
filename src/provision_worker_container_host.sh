#!/bin/bash

set -e

# mount NFS
/usr/local/share/slurm_gcp_docker/src/nfs_provision_worker.sh ${1}-nfs

# start Slurm docker
docker run -dti --rm --pid host --network host --privileged \
  -v /mnt/nfs:/mnt/nfs -v /sys/fs/cgroup:/sys/fs/cgroup \
  -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker \
  -v /etc/gcloud:/etc/gcloud -v /dev:/dev \
  --entrypoint /usr/local/share/slurm_gcp_docker/src/docker_entrypoint_worker.sh --name slurm \
  broadinstitute/slurm_gcp_docker
