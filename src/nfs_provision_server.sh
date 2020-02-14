#!/bin/bash

#
# Usage: nfs_provision_server.sh <disk size in GB> [disk type [disk image [disk image project]]]

set -e -o pipefail

#
# parse arguments; create, attach, format, and mount NFS disk (if these things
# have not yet already been done)
SIZE=$1
shift
DISKTYPE=$1
[ ! -z "$DISKTYPE" ] && shift
IMAGE=$1
[ ! -z "$IMAGE" ] && shift
IMAGEPROJ=$1

# set default disk to spinning
case "$DISKTYPE" in
	pd-standard)
		;;
	pd-ssd)
		;;
	*)
		DISKTYPE="pd-standard"
		;;
esac

# set default image project to current project
if [ -z "$IMAGEPROJ" ]; then
	IMAGEPROJ=`gcloud config list --format='value(core.project)'`
fi

# format disk image string, if it exists
if [ ! -z "$IMAGE" ]; then
	IMAGESTRING="--image $IMAGE --image-project $IMAGEPROJ"
else
	IMAGESTRING=""
fi

# if we did not specify an image, then we will initialize the NFS disk to
# 10 GB (and subsequenty resize to the requested size)
# if we did specify an image, we will initialize the NFS disk to the image isze
# (and subsequently resize)
# this dramatically improves NFS creation performance -- resize2fs is much faster
# than mkfs

if [ -z "$IMAGESTRING" ]; then
	INIT_SIZE=10
else
	INIT_SIZE=`gcloud compute images describe $IMAGE --project $IMAGEPROJ --format 'value(diskSizeGb)'`
fi

#
# get zone of instance
ZONE=$(gcloud compute instances list --filter="name=${HOSTNAME}" \
  --format='csv[no-heading](zone)')

#
# create and attach NFS disk (if it does not already exist)
echo -e "Creating NFS disk ...\n"

gcloud compute disks list --filter="name=${HOSTNAME}-nfs" --format='csv[no-heading](type)' | \
  grep -q $DISKTYPE || \
  gcloud compute disks create ${HOSTNAME}-nfs --size ${INIT_SIZE}GB --type $DISKTYPE --zone $ZONE $IMAGESTRING
[ -b /dev/disk/by-id/google-${HOSTNAME}-nfs ] && \
  echo "Disk is already attached!" || \
  { gcloud compute instances attach-disk $HOSTNAME --disk ${HOSTNAME}-nfs --zone $ZONE \
      --device-name ${HOSTNAME}-nfs && \
    gcloud compute instances set-disk-auto-delete $HOSTNAME --disk ${HOSTNAME}-nfs \
      --zone $ZONE; }

#
# format NFS disk if it's not already formatted (ext4)

# XXX: we assume that this will always be /dev/disk/by-id/google-$HOSTNAME-nfs.
#      In the future, if we are attaching multiple disks, this might not be the case.

[[ $(lsblk -no FSTYPE /dev/disk/by-id/google-${HOSTNAME}-nfs) == "ext4" ]] || {
echo -e "\nFormatting disk ...\n"
sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/disk/by-id/google-${HOSTNAME}-nfs;
}

#
# resize to full user-requested size
gcloud compute disks resize ${HOSTNAME}-nfs --size ${SIZE}GB --zone $ZONE --quiet || \
echo "Disk is already larger than user requested size!"

#
# mount NFS disk
echo -e "\nMounting disk ...\n"

# this should already be present, but let's do this just in case
[ ! -d /mnt/nfs ] && sudo mkdir -p /mnt/nfs
sudo mount -o discard,defaults /dev/disk/by-id/google-${HOSTNAME}-nfs /mnt/nfs
sudo chmod 777 /mnt/nfs

# if disk was initialized with a smaller image than the target size, we need to
# expand.
sudo resize2fs /dev/disk/by-id/google-${HOSTNAME}-nfs

#
# add to exports; restart NFS server

# XXX: this will preclude having any preexisting NFS mounts defined in the base image.
sudo tee /etc/exports > /dev/null <<EOF
/mnt/nfs ${HOSTNAME%-nfs}*(rw,async,no_subtree_check,insecure,no_root_squash)
EOF

sudo service nfs-kernel-server restart
sudo exportfs -ra
