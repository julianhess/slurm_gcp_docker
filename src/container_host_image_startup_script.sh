#!/bin/bash

# install NFS, Docker, files to build Slurm Docker image
cat <<EOF
sudo apt-get update && sudo apt-get -y install git nfs-kernel-server nfs-common portmap ssed iptables && \
sudo groupadd -g 1338 docker && \
wget "https://download.docker.com/linux/ubuntu/dists/disco/pool/stable/amd64/containerd.io_1.2.6-3_amd64.deb" && \
wget "https://download.docker.com/linux/ubuntu/dists/disco/pool/stable/amd64/docker-ce-cli_19.03.3~3-0~ubuntu-disco_amd64.deb" && \
wget "https://download.docker.com/linux/ubuntu/dists/disco/pool/stable/amd64/docker-ce_19.03.3~3-0~ubuntu-disco_amd64.deb" && \
sudo dpkg -i "containerd.io_1.2.6-3_amd64.deb" && \
sudo dpkg -i "docker-ce-cli_19.03.3~3-0~ubuntu-disco_amd64.deb" && \
sudo dpkg -i "docker-ce_19.03.3~3-0~ubuntu-disco_amd64.deb" && \
sudo git clone https://github.com/getzlab/slurm_gcp_docker /usr/local/share/slurm_gcp_docker && \
sudo adduser $USER docker && \
sudo ssed -R -i '/GRUB_CMDLINE_LINUX_DEFAULT/s/(.*)"(.*)"(.*)/\1"\2 cgroup_enable=memory swapaccount=1"\3/' /etc/default/grub && \
sudo update-grub
EOF

# make sure shutdown script that tells Slurm controller node is going offline
# run before the Docker daemon shuts down
echo "[ ! -d /etc/systemd/system/google-shutdown-scripts.service.d ] && \
sudo mkdir -p /etc/systemd/system/google-shutdown-scripts.service.d; \
sudo tee /etc/systemd/system/google-shutdown-scripts.service.d/override.conf > /dev/null <<EOF
[Unit]
After=docker.service
EOF"

# build current user into container
echo "sudo docker build -t broadinstitute/slurm_gcp_docker:v0.2 \
  -t broadinstitute/slurm_gcp_docker:latest \
  --build-arg USER=$USER --build-arg UID=$UID --build-arg GID=$(id -g) \
  /usr/local/share/slurm_gcp_docker/src"

echo "touch /started"
