#!/bin/bash

sudo apt-get -y install nfs-common

# TODO: implement a better check for whether gcloud is properly configured
#       simply checking for the existence of ~/.config/gcloud is insufficient
[ -d ~/.config/gcloud ] || { echo "gcloud has not yet been configured. Please run \`gcloud auth login'"; exit 1; }
cp -r ~/.config/gcloud gc_conf
sudo docker build -t broadinstitute/pydpiper:v0.1 -t broadinstitute/pydpiper:latest .
rm -rf gc_conf
