#!/usr/bin/env bash

set -e

VERSION=$(cat VERSION)

## Choose the docker base image to build from:
## 1. (For developer) If broadinstitute/slurm_gcp_docker_base:$VERSION exists locally, use it.
##    This is the local image built by docker_build_base.sh
## 2. Otherwise use gcr.io/broad-getzlab-workflows/slurm_gcp_docker_base:$VERSION

#if sudo docker image inspect broadinstitute/slurm_gcp_docker_base:$VERSION >/dev/null 2>/dev/null; then
#    echo "Building docker image from broadinstitute/slurm_gcp_docker_base:$VERSION (local)"
#    docker_base_image=broadinstitute/slurm_gcp_docker_base:$VERSION
#else
#    echo "Building docker image from gcr.io/broad-getzlab-workflows/slurm_gcp_docker_base:$VERSION"
#    docker_base_image=gcr.io/broad-getzlab-workflows/slurm_gcp_docker_base:$VERSION
#fi

docker_base_image=$(cat DOCKER_SRC)

sudo docker build -t broadinstitute/slurm_gcp_docker:$VERSION \
  -t broadinstitute/slurm_gcp_docker:latest \
  --build-arg HOST_USER=$USER --build-arg UID=$UID --build-arg GID=$(id -g) \
  --build-arg DOCKER_BASE_IMAGE="$docker_base_image":"$VERSION" \
  .
