#!/bin/bash

# uncomment for logging (to debug resume script)
/usr/local/share/slurm_gcp_docker/src/slurm_suspend.sh $@ &> /dev/null # &> /mnt/nfs/suspend_log.txt

