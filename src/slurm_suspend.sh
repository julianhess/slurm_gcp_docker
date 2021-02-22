#!/bin/bash

export CLOUDSDK_CONFIG=~slurm/.config/gcloud

# get zone of instance
ZONE=$(gcloud compute instances list --filter="name=${HOSTNAME}" \
  --format='csv[no-heading](zone)')

INST_LIST=$(scontrol show hostnames $@)

# XXX: gcloud assumes that sys.stdin will always be not None, so we need to pass
#      dummy stdin (/dev/null)
gcloud compute instances delete $INST_LIST --zone $ZONE --quiet < /dev/null
