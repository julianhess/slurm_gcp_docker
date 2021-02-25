#!/bin/bash

set -e

# mount NFS
/usr/local/share/slurm_gcp_docker/src/nfs_provision_worker.sh ${1}

# start Slurm docker
. /usr/local/share/slurm_gcp_docker/src/docker_run.sh
