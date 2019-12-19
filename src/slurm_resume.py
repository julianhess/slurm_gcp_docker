#!/usr/bin/env python

import pandas as pd
import os
import sys
import subprocess
import pickle

# load node machine type lookup table
node_LuT = pd.read_pickle("/mnt/nfs/clust_conf/slurm/host_LuT.pickle")

# load Canine backend configuration
with open("/mnt/nfs/clust_conf/canine/backend_conf.pickle", "rb") as f:
	k9_backend_conf = pickle.load(f)

# export gcloud credential path
os.environ["CLOUDSDK_CONFIG"] = subprocess.check_output(
  "echo -n ~slurm/.config/gcloud", shell = True
).decode()

# get list of nodenames to create
hosts = subprocess.check_output("scontrol show hostnames {}".format(sys.argv[1]), shell = True).decode().rstrip().split("\n")

# create all the nodes of each machine type at once
for machine_type, host_list in node_LuT.loc[hosts].groupby("machine_type"):
	subprocess.check_call(
	  """gcloud compute instances create {HOST_LIST} --image {image} \
	     --machine-type {MT} --zone {compute_zone} {compute_script} {preemptible} \
	     --tags caninetransientimage
	  """.format(
	    HOST_LIST = " ".join(host_list.index), MT = machine_type, **k9_backend_conf
	  ), shell = True, executable = '/bin/bash'
	)
