#!/bin/bash

#
# usage: nfs_provision_worker.sh <hostname of server>

SHOST=$1

# if the volume hasn't been bind mounted, then mount it as an NFS
if ! mountpoint -q /mnt/nfs; then
	# should already be present, but check just in case
	[ ! -d /mnt/nfs ] && sudo mkdir -p /mnt/nfs

	echo -n "Waiting for NFS to be ready ..."
	while ! sudo mount -o defaults,hard,intr ${SHOST}:/mnt/nfs /mnt/nfs &> /dev/null; do
		echo -n "."
		sleep 1
	done
	echo
fi
