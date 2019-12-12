#!/bin/bash

export CLOUDSDK_CONFIG=/etc/gcloud

/usr/local/share/cga_pipeline/src/nfs_provision_server.sh $1 $2

. /usr/local/share/cga_pipeline/src/slurm_start.sh
