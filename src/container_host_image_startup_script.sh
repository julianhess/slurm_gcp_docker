#!/bin/bash

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
sudo update-grub && \
[ ! -d ~$USER/.config/gcloud ] && sudo -u $USER mkdir -p ~$USER/.config/gcloud
EOF

echo "[ ! -d /etc/systemd/system/google-shutdown-scripts.service.d ] && \
sudo mkdir -p /etc/systemd/system/google-shutdown-scripts.service.d; \
sudo tee /etc/systemd/system/google-shutdown-scripts.service.d/override.conf > /dev/null <<EOF
[Unit]
After=docker.service
EOF"

echo "sudo tee /etc/docker/daemon.json > /dev/null <<< '{ \"insecure-registries\" : [\"'$HOSTNAME':5000\"] }' && " \
  "sudo systemctl restart docker && sudo docker pull $HOSTNAME:5000/broadinstitute/pydpiper && " \
  "sudo docker tag $HOSTNAME:5000/broadinstitute/pydpiper broadinstitute/pydpiper"

echo "touch /started"
