#!/bin/bash

# runs inside each worker container, checks every 5 minutes if the container is
# healthy. if not, blacklist this node.

while true; do
	# check if Podman is responsive
	if ! timeout 30 podman info; then
		scontrol update nodename=$HOSTNAME state=FAIL reason="podman flatlined" && \
		scontrol update nodename=$HOSTNAME state=DOWN reason="podman flatlined"
	fi

	# check if disk is full (<5% space remaining on root partition)
	if ! df / | awk 'NR == 2 { if($4/($4 + $3) < 0.05) { exit 1 } }'; then
		scontrol update nodename=$HOSTNAME state=FAIL reason="local disk full" && \
		scontrol update nodename=$HOSTNAME state=DOWN reason="local disk full"
	fi

	sleep 300
done
