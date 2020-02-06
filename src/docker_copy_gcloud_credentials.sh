#!/bin/bash

# add gcloud credentials to slurm's home directory
[ ! -d ~slurm/.config ] && mkdir -p ~slurm/.config
cp -r /etc/gcloud ~slurm/.config/gcloud && \
chown -R slurm:slurm ~slurm/.config/gcloud

# add gcloud credentials to user's home directory
HOMEDIR=`eval echo ~$USER`
[ ! -d $HOMEDIR/.config ] && mkdir -p $HOMEDIR/.config
cp -r /etc/gcloud $HOMEDIR/.config/gcloud && chown -R $USER:$USER $HOMEDIR/.config/
