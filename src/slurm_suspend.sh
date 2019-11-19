#!/bin/bash

# get zone of instance
ZONE=$(gcloud compute instances list --filter="name=${HOSTNAME}" \
  --format='csv[no-heading](zone)')

INST_LIST=$(scontrol show hostnames $@)

gcloud compute instances stop $INST_LIST --zone $ZONE --quiet
