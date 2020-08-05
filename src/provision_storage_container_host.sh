#!/bin/bash

export CLOUDSDK_CONFIG=/etc/gcloud

# initialize NFS server
/usr/local/share/slurm_gcp_docker/src/nfs_provision_server.sh $1 $2 $3 $4

# start Slurm docker
. /usr/local/share/slurm_gcp_docker/src/docker_run.sh
