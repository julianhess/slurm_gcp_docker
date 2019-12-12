#!/bin/bash

sudo docker run --privileged --rm --network host -ti -v /mnt/nfs:/mnt/nfs --name "pype_host" broadinstitute/pydpiper /bin/bash
