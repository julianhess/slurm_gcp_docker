ARG DOCKER_BASE_IMAGE=gcr.io/broad-getzlab-workflows/slurm_gcp_docker_base
FROM $DOCKER_BASE_IMAGE

# add current user to container; enable passwordless sudo and rootless docker
ARG UID
ARG GID
ARG HOST_USER
ENV USER_UID=$UID
ENV USER_GID=$GID
ENV HOST_USER=$HOST_USER
RUN groupadd -g $USER_GID $HOST_USER && adduser --gid $USER_GID -u $USER_UID --gecos "" \
  --disabled-password $HOST_USER && \
  groupadd -g 1338 docker && adduser $HOST_USER docker
