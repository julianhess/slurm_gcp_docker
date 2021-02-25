#!/bin/bash

# uncomment for logging (to debug resume script)
/mnt/nfs/clust_scripts/slurm_resume.py $@ &> /dev/null # &> /mnt/nfs/resume_log.txt
