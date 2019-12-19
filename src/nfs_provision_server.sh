#!/bin/bash

#
# Usage: nfs_provision_server.sh <disk size in GB> [disk type] 

set -e -o pipefail

#
# parse arguments; create, attach, format, and mount NFS disk (if these things
# have not yet already been done)
SIZE=$1
shift
DISKTYPE=$1

case "$DISKTYPE" in
	pd-standard)
		;;
	pd-ssd)
		;;
	*)
		DISKTYPE="pd-standard"
		;;
esac

#
# get zone of instance
ZONE=$(gcloud compute instances list --filter="name=${HOSTNAME}" \
  --format='csv[no-heading](zone)')

#
# create and attach NFS disk (if it does not already exist)
echo -e "Creating NFS disk ...\n"

gcloud compute disks list --filter="name=${HOSTNAME}-nfs" --format='csv[no-heading](type)' | \
  grep -q $DISKTYPE || \
  gcloud compute disks create ${HOSTNAME}-nfs --size ${SIZE}GB --type $DISKTYPE --zone $ZONE
[ -b /dev/disk/by-id/google-${HOSTNAME}-nfs ] && \
  { echo "Disk is already attached!";
    sudo mount -o discard,defaults /dev/sdb /mnt/nfs;
  } || \
  { gcloud compute instances attach-disk $HOSTNAME --disk ${HOSTNAME}-nfs --zone $ZONE \
      --device-name ${HOSTNAME}-nfs && \
    gcloud compute instances set-disk-auto-delete $HOSTNAME --disk ${HOSTNAME}-nfs \
      --zone $ZONE; }

#
# format NFS disk (if it's not already mounted)
mountpoint -q /mnt/nfs || {
echo -e "\nFormatting disk ...\n"

# XXX: we assume that this will always be /dev/sdb. In the future, if we are
#      attaching multiple disks, this might not be the case.
sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb

#
# mount NFS disk
echo -e "\nMounting disk ...\n"

# this should already be present, but let's do this just in case
[ ! -d /mnt/nfs ] && sudo mkdir -p /mnt/nfs
sudo mount -o discard,defaults /dev/sdb /mnt/nfs
sudo chmod 777 /mnt/nfs;
}

#
# add to exports; restart NFS server

# XXX: this will preclude having any preexisting NFS mounts defined in the base image.
sudo tee /etc/exports > /dev/null <<EOF
/mnt/nfs ${HOSTNAME%-nfs}*(rw,async,no_subtree_check,insecure,no_root_squash)
EOF

sudo service nfs-kernel-server restart
sudo exportfs -ra
