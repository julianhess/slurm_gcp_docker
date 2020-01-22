#!/bin/bash

export CLOUDSDK_CONFIG=/etc/gcloud

/usr/local/share/slurm_gcp_docker/src/nfs_provision_server.sh $1 $2

. /usr/local/share/slurm_gcp_docker/src/slurm_start.sh
