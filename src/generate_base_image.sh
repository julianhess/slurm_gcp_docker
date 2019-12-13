#!/bin/bash

#
# usage: generate_base_image.sh <image name> [dummy instance name [zone [project]]]

# TODO: add argument parsing (currently just falls back on defaults)

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
--machine-type n1-standard-1 --image ubuntu-minimal-1910-eoan-v20191113 \
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

#
# interactively authorize user's Google account
gcloud compute ssh $HOST --zone $ZONE -- -o "UserKnownHostsFile /dev/null" \
  -t 'echo -n "Waiting for gcloud ..."; while [ ! -f /snap/bin/gcloud ]; do sleep 1; echo -n "."; done; echo; /snap/bin/gcloud auth login --no-launch-browser'

#
# build environment on dummy host
ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -T $HOST <<'EOF'
sudo cp -r ~/.config/gcloud /etc/gcloud && \
sudo apt-get update && \
sudo apt-get -y install build-essential vim git python3-pip nfs-kernel-server \
  nfs-common portmap libmariadb-dev mariadb-client mariadb-server \
  munge libmunge-dev libhwloc-dev cgroup-tools libreadline-dev ssed && \
sudo ln -s /usr/bin/python3 /usr/bin/python && \
sudo ln -s /usr/bin/pip3 /usr/bin/pip && \
sudo mkdir -p /mnt/nfs && \
wget https://download.schedmd.com/slurm/slurm-19.05.3-2.tar.bz2 && \
tar xjf slurm-19.05.3-2.tar.bz2 && \
cd slurm-19.05.3-2 && \
./configure --prefix=/usr/local --sysconfdir=/usr/local/etc \
  --with-mysql_config=/usr/bin --with-hdf5=no && \
make && sudo make install && \
sudo ssed -R -i '/GRUB_CMDLINE_LINUX_DEFAULT/s/(.*)"(.*)"(.*)/\1"\2 cgroup_enable=memory swapaccount=1"\3/' /etc/default/grub && \
sudo update-grub && \
sudo adduser --gecos "" --disabled-password slurm && \
sudo mkdir -p ~slurm/.config && sudo cp -r /etc/gcloud ~slurm/.config/gcloud && \
sudo chown -R slurm:slurm ~slurm/.config/gcloud && \
sudo mkdir -p /var/spool/slurm && sudo chown slurm:slurm /var/spool/slurm && \
sudo systemctl start mariadb && \
sudo mysql -u root -e "create user 'slurm'@'localhost'" && \
sudo mysql -u root -e "grant all on slurm_acct_db.* TO 'slurm'@'localhost';" && \
sudo git clone https://github.com/julianhess/cga_pipeline.git /usr/local/share/cga_pipeline && \
sudo pip install pandas canine && \
rm -rf ~/*
EOF

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
gcloud compute images create $IMAGENAME --source-disk=${HOST}-tmpdr --source-disk-zone $ZONE || \
  { echo "Error creating image!"; exit 1; }

echo "Deleting snapshot/template disk ..."
gcloud compute disks delete ${HOST}-tmpdr --zone $ZONE --quiet || \
  { echo "Error deleting template disk!"; exit 1; }
gcloud compute snapshots delete ${HOST}-snap --quiet || { echo "Error deleting snapshot!"; exit 1; }

#
# delete dummy host
gcloud compute instances delete $HOST --zone $ZONE --quiet
