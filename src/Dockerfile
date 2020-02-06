FROM <GCP Slurm> as build

WORKDIR /tmp

# add current user to container; enable passwordless sudo and rootless docker
ARG UID
ARG GID
ARG USER
RUN groupadd -g $GID $USER && adduser --gid $GID -u $UID --gecos "" --disabled-password $USER && \
adduser $USER sudo && groupadd -g 1338 docker && adduser $USER docker && \
HOMEDIR=`eval echo ~$USER` && mkdir -p $HOMEDIR/.config && \
cp -r /etc/gcloud $HOMEDIR/.config/gcloud && chown -R $USER:$USER $HOMEDIR/.config/ && \
ssed -i '/^%sudo/s/ALL$/NOPASSWD:ALL/' /etc/sudoers
