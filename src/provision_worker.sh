#!/bin/bash

set -e

/usr/local/share/cga_pipeline/src/nfs_provision_worker.sh ${1}-nfs

. /usr/local/share/cga_pipeline/src/slurm_start.sh
