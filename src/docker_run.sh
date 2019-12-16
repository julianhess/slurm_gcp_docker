#!/bin/bash

# check if Slurm or Munge is already running; cannot start if this is the case
pgrep slurmctld &> /dev/null && { echo -e "A Slurm controller is already running on this machine.\nPlease run \`[sudo] killall slurmctld\` and try again.";
  exit 1; }
pgrep slurmdbd &> /dev/null && { echo -e "The Slurm database daemon is already running on this machine.\nPlease run \`[sudo] killall slurmdbd\` and try again.";
  exit 1; }
pgrep munged &> /dev/null && { echo -e "Munge is already running on this machine.\nPlease run \`[sudo] killall munged\` and try again."; exit 1; }

# check if mountpoint exists
# TODO: update path to setup script in error message
mountpoint -q /mnt/nfs || { echo "NFS is not mounted. Please run <setup script> again."; exit 1; }

sudo docker run -v /mnt/nfs:/mnt/nfs --rm --network host -ti --name "pype_host" broadinstitute/pydpiper /bin/bash
