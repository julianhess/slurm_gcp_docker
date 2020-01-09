#!/bin/bash

sudo apt-get -y install nfs-common

# TODO: implement a better check for whether gcloud is properly configured
#       simply checking for the existence of ~/.config/gcloud is insufficient
[ -d ~/.config/gcloud ] || { echo "gcloud has not yet been configured. Please run \`gcloud auth login'"; exit 1; }
cp -r ~/.config/gcloud gc_conf
sudo docker build -t broadinstitute/pydpiper:v0.1 -t broadinstitute/pydpiper:latest \
  --build-arg USER=$USER --build-arg UID=$UID .
rm -rf gc_conf

#
# push image to private registry

# allow private registry to be recognized sans certificate
[ -f /etc/docker/daemon.json ] && echo "Not overwriting /etc/docker/daemon.json. Please manually allow insecure registries." || \
{ sudo tee /etc/docker/daemon.json > /dev/null <<< '{ "insecure-registries" : ["'$HOSTNAME':5000"] }'
sudo systemctl restart docker; }

docker tag broadinstitute/pydpiper $HOSTNAME:5000/broadinstitute/pydpiper
docker push $HOSTNAME:5000/broadinstitute/pydpiper
