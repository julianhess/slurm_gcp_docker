#
# this file is meant to be sourced from other scripts, and should not be run
# as a standalone.

export SLURM_CONF=/mnt/nfs/clust_conf/slurm/slurm.conf

sudo munged -f
sudo -E slurmd -f /mnt/nfs/clust_conf/slurm/slurm.conf
