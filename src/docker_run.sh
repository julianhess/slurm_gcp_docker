#!/bin/bash

sudo docker run --privileged --rm --network host -ti --name "pype_host" broadinstitute/pydpiper /bin/bash
