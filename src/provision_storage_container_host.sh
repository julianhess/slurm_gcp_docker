#!/bin/bash

export CLOUDSDK_CONFIG=/etc/gcloud

# initialize NFS server
/usr/local/share/cga_pipeline/src/nfs_provision_server.sh $1 $2

# start Slurm docker
docker run -dti --rm --network host -v /mnt/nfs:/mnt/nfs -v /sys/fs/cgroup:/sys/fs/cgroup \
  -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker \
  --entrypoint /usr/local/share/cga_pipeline/src/docker_entrypoint_worker.sh --name slurm \
  broadinstitute/pydpiper
