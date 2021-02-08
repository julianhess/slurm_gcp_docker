ARG DOCKER_BASE_IMAGE=gcr.io/broad-getzlab-workflows/slurm_gcp_docker_base
FROM $DOCKER_BASE_IMAGE

# add current user to container; enable passwordless sudo and rootless docker
ARG UID
ARG GID
ARG HOST_USER
ENV UID=$UID
ENV GID=$GID
ENV HOST_USER=$HOST_USER
RUN groupadd -g $GID $HOST_USER && adduser --gid $GID -u $UID --gecos "" \
  --disabled-password $HOST_USER && \
adduser $HOST_USER sudo && groupadd -g 1338 docker && adduser $HOST_USER docker && \
ssed -i '/^%sudo/s/ALL$/NOPASSWD:ALL/' /etc/sudoers
