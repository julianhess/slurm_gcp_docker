#!/bin/bash

# alert controller that this host is being preempted; set status to fail
docker exec slurm scontrol update nodename=$HOSTNAME state=FAIL reason="preempted" && \
docker exec slurm scontrol update nodename=$HOSTNAME state=DOWN reason="preempted"
