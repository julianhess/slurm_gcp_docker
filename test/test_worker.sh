#!/bin/bash

set -e

gcloud compute instances create ctest-nfs --image dummy-image \
  --machine-type n1-standard-4 --zone us-east1-d \
  --metadata startup-script="rm -rf /usr/local/share/cga_pipeline; git clone -b no_nfs_in_docker https://github.com/julianhess/cga_pipeline.git /usr/local/share/cga_pipeline; /usr/local/share/cga_pipeline/src/provision_storage.sh 100"

gcloud compute instances create ctest --image dummy-image \
  --machine-type n1-standard-2 --zone us-east1-d \
  --metadata startup-script="rm -rf /usr/local/share/cga_pipeline; git clone -b no_nfs_in_docker https://github.com/julianhess/cga_pipeline.git /usr/local/share/cga_pipeline; /usr/local/share/cga_pipeline/src/provision_server.py"

gcloud compute instances create ctest-worker1 --image dummy-image \
  --machine-type n1-standard-8 --zone us-east1-d \
  --metadata startup-script="rm -rf /usr/local/share/cga_pipeline; git clone -b no_nfs_in_docker https://github.com/julianhess/cga_pipeline.git /usr/local/share/cga_pipeline; /usr/local/share/cga_pipeline/src/provision_worker.sh ctest" \
  --preemptible

#gcloud compute instances delete ctest ctest-worker{1..3} --zone us-east1-d --quiet

# for i in 1..10; do
# 	srun hostname
# done
