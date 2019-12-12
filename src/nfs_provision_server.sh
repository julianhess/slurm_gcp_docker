#!/bin/bash

#
# Usage: nfs_provision_server.sh <disk size in GB> [disk type] 

set -e -o pipefail

#
# parse arguments; create, attach, format, and mount NFS disk (if these things
# have not yet already been done)
. nfs_make_disk.sh

#
# add to exports; restart NFS server

# XXX: this will preclude having any preexisting NFS mounts defined in the base image.
sudo tee /etc/exports > /dev/null <<< \
"/mnt/nfs ${HOSTNAME}-worker*(rw,async,no_subtree_check,insecure,no_root_squash)"

[ ! -d /run/sendsigs.omit.d ] && sudo mkdir -p /run/sendsigs.omit.d
sudo service rpcbind restart

sudo service nfs-kernel-server restart
sudo exportfs -ra
