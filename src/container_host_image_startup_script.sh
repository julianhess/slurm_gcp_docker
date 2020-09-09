#!/bin/bash

# install NFS, Docker, associated files, gcloud
cat <<EOF
# NFS
sudo apt-get update && sudo apt-get -y install git nfs-kernel-server nfs-common portmap ssed iptables && \
# DOCKER
sudo groupadd -g 1338 docker && \
wget "https://download.docker.com/linux/ubuntu/dists/disco/pool/stable/amd64/containerd.io_1.2.6-3_amd64.deb" && \
wget "https://download.docker.com/linux/ubuntu/dists/disco/pool/stable/amd64/docker-ce-cli_19.03.3~3-0~ubuntu-disco_amd64.deb" && \
wget "https://download.docker.com/linux/ubuntu/dists/disco/pool/stable/amd64/docker-ce_19.03.3~3-0~ubuntu-disco_amd64.deb" && \
sudo dpkg -i "containerd.io_1.2.6-3_amd64.deb" && \
sudo dpkg -i "docker-ce-cli_19.03.3~3-0~ubuntu-disco_amd64.deb" && \
sudo dpkg -i "docker-ce_19.03.3~3-0~ubuntu-disco_amd64.deb" && \
# SLURM GCP SCRIPTS
sudo git clone https://github.com/getzlab/slurm_gcp_docker /usr/local/share/slurm_gcp_docker && \
sudo adduser $USER docker && \
# ENABLE CGROUPS
sudo ssed -R -i '/GRUB_CMDLINE_LINUX_DEFAULT/s/(.*)"(.*)"(.*)/\1"\2 cgroup_enable=memory swapaccount=1"\3/' /etc/default/grub && \
sudo update-grub && \
# INSTALL GCLOUD
[ ! -d ~$USER/.config/gcloud ] && sudo -u $USER mkdir -p ~$USER/.config/gcloud
sudo mkdir /gcsdk && \
sudo wget -O gcs.tgz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-272.0.0-linux-x86_64.tar.gz && \
sudo tar xzf gcs.tgz -C /gcsdk && \
sudo /gcsdk/google-cloud-sdk/install.sh --usage-reporting false --path-update true --quiet && \
sudo ln -s /gcsdk/google-cloud-sdk/bin/* /usr/bin
EOF

# make sure shutdown script that tells Slurm controller node is going offline
# runs before the Docker daemon shuts down
echo "[ ! -d /etc/systemd/system/google-shutdown-scripts.service.d ] && \
sudo mkdir -p /etc/systemd/system/google-shutdown-scripts.service.d; \
sudo tee /etc/systemd/system/google-shutdown-scripts.service.d/override.conf > /dev/null <<EOF
[Unit]
After=docker.service
After=docker.socket
EOF"

# build current user into container
VERSION=$(cat VERSION)
echo "sudo docker build -t broadinstitute/slurm_gcp_docker:$VERSION \
  -t broadinstitute/slurm_gcp_docker:latest \
  --build-arg HOST_USER=$USER --build-arg UID=$UID --build-arg GID=$(id -g) \
  /usr/local/share/slurm_gcp_docker/src"

echo "touch /started"
