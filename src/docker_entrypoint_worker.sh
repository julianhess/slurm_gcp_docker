#!/bin/bash

sudo /usr/local/share/slurm_gcp_docker/src/docker_copy_gcloud_credentials.sh

. /usr/local/share/slurm_gcp_docker/src/slurm_start.sh
/bin/bash
