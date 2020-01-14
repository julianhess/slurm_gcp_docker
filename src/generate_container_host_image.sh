#!/bin/bash

set -e

#
# parse in zone, or use zone of current instance (if any)
ZONE=$(gcloud compute instances list --filter="name=${HOSTNAME}" \
  --format='csv[no-heading](zone)')
# if ! grep -qE '(asia|australia|europe|northamerica|southamerica|us)-[a-z]+\d+-[a-z]' <<< "$ZONE"; then
# 	echo "Error: invalid zone"
# 	exit 1
# fi

#
# get current project (if any)
PROJ=$(gcloud config list --format='value(core.project)')

#
# get hostname
HOST=dummyhost

#
# get image name
IMAGENAME=$1

#
# create dummy instance to build image in
gcloud compute --project $PROJ instances create $HOST --zone $ZONE \
  --machine-type n1-standard-1 --image ubuntu-minimal-1910-eoan-v20200107 \
  --image-project ubuntu-os-cloud --boot-disk-size 10GB --boot-disk-type pd-standard \
  --metadata-from-file startup-script=<(./container_host_image_startup_script.sh)

#
# wait for instance to be ready
echo -n "Waiting for dummy instance to be ready ..."
while ! gcloud compute ssh $HOST --zone $ZONE -- -o "UserKnownHostsFile /dev/null" \
  "[ -f /started ]" &> /dev/null; do
	sleep 1
	echo -n ".";
done
echo

# TODO: implement a better check for whether gcloud is properly configured
#       simply checking for the existence of ~/.config/gcloud is insufficient
[ -d ~/.config/gcloud ] || { echo "gcloud has not yet been configured. Please run \`gcloud auth login'"; exit 1; }
gcloud compute scp ~/.config/gcloud/* $HOST:.config/gcloud --zone $ZONE --recurse
gcloud compute ssh $HOST --zone $ZONE -- -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -T \
  "sudo cp -r ~/.config/gcloud /etc/gcloud"

# #
# # generate SSL certificates for internal Docker registry
# mkdir -p ../certs
# openssl req -batch -newkey rsa:4096 -nodes -sha256 -keyout ../certs/domain.key \
#   -x509 -days 11499 -out ../certs/domain.crt
# 
# # copy certs to dummy host
# gcloud compute scp ../certs root@$HOST:/usr/local/share/cga_pipeline/certs --zone $ZONE --recurse
# 
# CERT_DIR=/etc/docker/certs.d/$HOSTNAME:5000/
# 
# gcloud compute scp ../certs root@$HOST:/usr/local/share/cga_pipeline/certs --zone $ZONE --recurse
# gcloud compute ssh $HOST --zone $ZONE -- -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -T \
#   "[ ! -d $CERT_DIR ] && sudo mkdir -p $CERT_DIR"
# gcloud compute scp ../certs/domain.crt root@$HOST:$CERT_DIR --zone $ZONE --recurse
# 
# # copy cert locally
# [ ! -d $CERT_DIR ] && sudo mkdir -p $CERT_DIR
# sudo cp ../certs/domain.crt $CERT_DIR

#
# shut down dummy instance
# (this is to avoid disk caching problems that can arise from imaging a running
# instance)
gcloud compute instances stop $HOST --zone $ZONE --quiet

#
# clone base image from dummy host's drive
echo "Snapshotting dummy host drive ..."
gcloud compute disks snapshot $HOST --snapshot-names ${HOST}-snap --zone $ZONE || \
  { echo "Error creating snapshot!"; exit 1; }

echo "Creating image from snapshot ..."
gcloud compute images create $IMAGENAME --source-snapshot=${HOST}-snap --family pydpiper || \
  { echo "Error creating image!"; exit 1; }

echo "Deleting snapshot/template disk ..."
gcloud compute snapshots delete ${HOST}-snap --quiet || { echo "Error deleting snapshot!"; exit 1; }

#
# delete dummy host
gcloud compute instances delete $HOST --zone $ZONE --quiet
