#!/bin/bash

set -e

gcloud compute instances create ctest --image dummy-image \
  --machine-type n1-standard-2 --zone us-east1-d \
  --metadata startup-script="/usr/local/share/cga_pipeline/src/provision_server.py"

gcloud compute instances create ctest-worker{1..3} --image dummy-image \
  --machine-type n1-standard-8 --zone us-east1-d \
  --metadata startup-script="/usr/local/share/cga_pipeline/src/provision_worker.sh ctest" \
  --preemptible

gcloud compute ssh ctest --zone us-east1-d -- -t <<'EOF'
export SLURM_CONF=/mnt/nfs/clust_conf/slurm/slurm.conf
echo -n "Waiting for Slurm controller ..."
while ! pgrep slurmctld &> /dev/null; do
	sleep 1
	echo -n "."
done
echo

for i in {1..10}; do
	srun sh -c 'sleep 1; hostname' &
done
EOF

gcloud compute instances delete ctest ctest-worker{1..3} --zone us-east1-d --quiet

# for i in 1..10; do
# 	srun hostname
# done
