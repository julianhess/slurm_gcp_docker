#!/bin/bash

#
# create, attach, format, and mount NFS disk (if these things have not yet already
# been done)
. nfs_make_disk.sh

sudo docker run --privileged --rm --network host -ti -v /mnt/nfs:/mnt/nfs --name "pype_host" broadinstitute/pydpiper /bin/bash
