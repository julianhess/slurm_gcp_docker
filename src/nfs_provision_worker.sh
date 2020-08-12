#!/bin/bash

#
# usage: nfs_provision_worker.sh <hostname of server>

SHOST=$1

# if the volume hasn't been bind mounted, then mount it as an NFS
echo -n "Waiting for NFS to be ready ..."

# check if mount is stale
timeout 30 stat -t /mnt/nfs &> /dev/null
EC=$?
if [[ $EC == 124 ]]; then
	# attempt to unmount
	if ! sudo timeout 2 umount -f /mnt/nfs; then
		echo -e "\nNFS mount is stale. Please close any open files (check with \`lsof -b | grep /mnt/nfs\`) and then \`sudo umount -f /mnt/nfs\`." > /dev/stderr
		exit 1
	fi
fi

# otherwise, wait for mount to be ready (NFS server is starting up)
[ ! -d /mnt/nfs ] && sudo mkdir -p /mnt/nfs
while ! mountpoint -q /mnt/nfs; do
	sudo mount -o defaults,hard,intr ${SHOST}:/mnt/nfs /mnt/nfs &> /dev/null
	echo -n "."
	sleep 1
done
echo
