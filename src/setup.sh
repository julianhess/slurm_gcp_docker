#!/bin/bash

set -e

# TODO: implement a better check for whether gcloud is properly configured
#       simply checking for the existence of ~/.config/gcloud is insufficient
[ -d ~/.config/gcloud ] || { echo -e "gcloud has not yet been configured. Please run:\n * gcloud auth login\n * gcloud auth application-default login\n * gcloud auth docker"; exit 1; }

sudo apt-get -y install nfs-common

VERSION=$(cat VERSION)
IVERSION=$(tr . - <<< $VERSION)

./generate_container_host_image.py -i slurm-gcp-docker-${IVERSION}-`git rev-parse --short HEAD`-$USER

sudo docker build -t broadinstitute/slurm_gcp_docker:$VERSION \
  -t broadinstitute/slurm_gcp_docker:latest \
  --build-arg HOST_USER=$USER --build-arg UID=$UID --build-arg GID=$(id -g) .
