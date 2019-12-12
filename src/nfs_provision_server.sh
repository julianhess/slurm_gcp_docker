#!/bin/bash

#
# Usage: nfs_provision_server.sh <disk size in GB> [disk type] 

set -e -o pipefail

#
# parse arguments; create, attach, format, and mount NFS disk (if these things
# have not yet already been done)
. make_nfs_disk.sh

#
# add to exports; restart NFS server

# XXX: this will preclude having any preexisting NFS mounts defined in the base image.
sudo tee /etc/exports > /dev/null <<< \
"/mnt/nfs ${HOSTNAME}-worker*(rw,async,no_subtree_check,insecure,no_root_squash)"

sudo service nfs-kernel-server restart
sudo exportfs -ra
