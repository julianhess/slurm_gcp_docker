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
--image-project ubuntu-os-cloud --boot-disk-size 10GB --boot-disk-type pd-standard

#
# wait for instance to be ready
echo -n "Waiting for dummy instance to be ready ..."
while ! gcloud compute ssh $HOST --zone $ZONE -- -o "UserKnownHostsFile /dev/null" \
  -t echo &> /dev/null; do
	sleep 1
	echo -n ".";
done
echo

# install software to dummy host
gcloud compute ssh $HOST --zone $ZONE -- -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -T <<'EOF'
sudo apt-get update && \
sudo apt-get -y install nfs-common iptables git ssed && \
wget "https://download.docker.com/linux/ubuntu/dists/disco/pool/stable/amd64/containerd.io_1.2.6-3_amd64.deb" && \
wget "https://download.docker.com/linux/ubuntu/dists/disco/pool/stable/amd64/docker-ce-cli_19.03.3~3-0~ubuntu-disco_amd64.deb" && \
wget "https://download.docker.com/linux/ubuntu/dists/disco/pool/stable/amd64/docker-ce_19.03.3~3-0~ubuntu-disco_amd64.deb" && \
sudo dpkg -i "containerd.io_1.2.6-3_amd64.deb" && \
sudo dpkg -i "docker-ce-cli_19.03.3~3-0~ubuntu-disco_amd64.deb" && \
sudo dpkg -i "docker-ce_19.03.3~3-0~ubuntu-disco_amd64.deb" && \
sudo git clone https://github.com/julianhess/cga_pipeline.git /usr/local/share/cga_pipeline && \
sudo adduser $USER docker && \
sudo ssed -R -i '/GRUB_CMDLINE_LINUX_DEFAULT/s/(.*)"(.*)"(.*)/\1"\2 cgroup_enable=memory swapaccount=1"\3/' /etc/default/grub && \
sudo update-grub
EOF
gcloud compute ssh $HOST --zone $ZONE -- -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -T \
  "sudo tee /etc/docker/daemon.json > /dev/null <<< '{ \"insecure-registries\" : [\"'$HOSTNAME':5000\"] }' && " \
  "sudo systemctl restart docker && sudo docker pull $HOSTNAME:5000/broadinstitute/pydpiper"

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

echo "Creating template disk from snapshot ..."
gcloud compute disks create ${HOST}-tmpdr --source-snapshot=${HOST}-snap --size 10GB \
  --zone $ZONE || { echo "Error creating template disk!"; exit 1; }

echo "Creating image from template disk ..."
gcloud compute images create $IMAGENAME --source-disk=${HOST}-tmpdr --source-disk-zone $ZONE --family pydpiper || \
  { echo "Error creating image!"; exit 1; }

echo "Deleting snapshot/template disk ..."
gcloud compute disks delete ${HOST}-tmpdr --zone $ZONE --quiet || \
  { echo "Error deleting template disk!"; exit 1; }
gcloud compute snapshots delete ${HOST}-snap --quiet || { echo "Error deleting snapshot!"; exit 1; }

#
# delete dummy host
gcloud compute instances delete $HOST --zone $ZONE --quiet
