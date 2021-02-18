#!/bin/bash

# uncomment for logging (to debug resume script)
/usr/local/share/slurm_gcp_docker/src/slurm_resume.py $@ &> /dev/null # &> /mnt/nfs/resume_log.txt
