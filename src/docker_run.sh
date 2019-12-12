#!/bin/bash

#
# create, attach, format, and mount NFS disk (if these things have not yet already
# been done)
. make_nfs_disk.sh

sudo docker run --rm --network host -ti --name "pype_host" broadinstitute/pydpiper /bin/bash
