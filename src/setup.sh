#!/bin/bash

docker run --rm -d --network host --name registry registry:2 && \
./docker_build.sh && ./generate_container_host_image.sh k9-20-image && \
docker stop registry
