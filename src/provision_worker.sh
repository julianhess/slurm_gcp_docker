#!/bin/bash

set -e

/usr/local/share/slurm_gcp_docker/src/nfs_provision_worker.sh ${1}-nfs

. /usr/local/share/slurm_gcp_docker/src/slurm_start.sh
