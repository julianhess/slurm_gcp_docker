#!/bin/bash

# TODO: implement a better check for whether gcloud is properly configured
#       simply checking for the existence of ~/.config/gcloud is insufficient
[ -d ~/.config/gcloud ] || { echo "gcloud has not yet been configured. Please run \`gcloud auth login'"; exit 1; }

sudo apt-get -y install nfs-common
./generate_container_host_image.sh slurm-gcp-docker-v02

sudo docker build -t broadinstitute/slurm_gcp_docker:v0.2 \
  -t broadinstitute/slurm_gcp_docker:latest \
  --build-arg USER=$USER --build-arg UID=$UID --build-arg GID=$(id -g) .
