#!/bin/bash

#
# usage: nfs_provision_worker.sh <hostname of server>

SHOST=$1

# if the volume hasn't been bind mounted, then mount it as an NFS
echo -n "Waiting for NFS to be ready ..."
[ ! -d /mnt/nfs ] && sudo mkdir -p /mnt/nfs
while ! mountpoint -q /mnt/nfs; do
	sudo mount -o defaults,hard,intr ${SHOST}:/mnt/nfs /mnt/nfs &> /dev/null
	echo -n "."
	sleep 1
done
echo
