#!/bin/bash

#
# create, attach, format, and mount NFS disk (if these things have not yet already
# been done)
. nfs_make_disk.sh

sudo docker run --rm --network host -ti --name "pype_host" broadinstitute/pydpiper /bin/bash
