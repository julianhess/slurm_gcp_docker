#!/bin/bash

# This builds the base container image. Generally, this will be pulled from the
# container registry.

sudo docker build -t broadinstitute/slurm_gcp_docker_base:v0.2 \
  -t broadinstitute/slurm_gcp_docker_base:latest \
  -f Dockerfile_base .

# This can then be pushed to a container repo, e.g. gcr.io:
#
# docker tag broadinstitute/slurm_gcp_docker_base:v0.2 \
#   gcr.io/broad-getzlab-workflows/slurm_gcp_docker_base:v0.2
# docker tag broadinstitute/slurm_gcp_docker_base:v0.2 \
#   gcr.io/broad-getzlab-workflows/slurm_gcp_docker_base:latest
# docker push gcr.io/broad-getzlab-workflows/slurm_gcp_docker_base:v0.2
# docker push gcr.io/broad-getzlab-workflows/slurm_gcp_docker_base:latest
