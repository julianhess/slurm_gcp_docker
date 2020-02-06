FROM gcr.io/broad-getzlab-workflows/slurm_gcp_docker_base

# add current user to container; enable passwordless sudo and rootless docker
ARG UID
ARG GID
ARG USER
ENV UID=$UID
ENV GID=$GID
ENV USER=$USER
RUN groupadd -g $GID $USER && adduser --gid $GID -u $UID --gecos "" --disabled-password $USER && \
adduser $USER sudo && groupadd -g 1338 docker && adduser $USER docker && \
ssed -i '/^%sudo/s/ALL$/NOPASSWD:ALL/' /etc/sudoers
