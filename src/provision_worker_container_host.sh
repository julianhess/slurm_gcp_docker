#!/bin/bash

set -e

export SLURMCTL_HOST=${1}

# mount NFS
/usr/local/share/slurm_gcp_docker/src/nfs_provision_worker.sh ${SLURMCTL_HOST}

# start Slurm docker
. /usr/local/share/slurm_gcp_docker/src/docker_run.sh
