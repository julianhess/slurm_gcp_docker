#!/bin/bash

#
# Usage: attach_nfs_disk.sh <disk size in GB> [disk type] 

set -e -o pipefail

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
# create and attach NFS disk
echo -e "Creating NFS disk ...\n"

gcloud compute disks create ${HOSTNAME}-nfs --size ${SIZE}GB --type $DISKTYPE \
  --zone $ZONE
gcloud compute instances attach-disk $HOSTNAME --disk ${HOSTNAME}-nfs --zone $ZONE

#
# format NFS disk
echo -e "\nFormatting disk ...\n"

# XXX: we assume that this will always be /dev/sdb. In the future, if we are
#      attaching multiple disks, this might not be the case.
sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb
