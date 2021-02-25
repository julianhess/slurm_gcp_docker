#!/usr/bin/env python

import pandas as pd
import os
import sys
import subprocess
import pickle
import json

# load node machine type lookup table
node_LuT = pd.read_pickle("/mnt/nfs/clust_conf/slurm/host_LuT.pickle")

## canine backend config is passed to docker via environment variables with prefix "BACKEND_CONFIG__"
## and saved as file.
def load_canine_backend_conf():
	with open("/usr/local/etc/canine_backend_conf.json", "r") as f:
		conf = json.load(f)
	return conf

# load Canine backend configuration
k9_backend_conf = load_canine_backend_conf()
default_preemptible_flag = k9_backend_conf['preemptible'] # this is '--preemptible' or ''

# for some reason, the USER environment variable is set to root when this
# script is run, even though it's run under user slurm ...
os.environ["USER"] = "slurm"

# export gcloud credential path
os.environ["CLOUDSDK_CONFIG"] = subprocess.check_output(
  "echo -n ~slurm/.config/gcloud", shell = True
).decode()

# get list of nodenames to create
hosts = subprocess.check_output("scontrol show hostnames {}".format(sys.argv[1]), shell = True).decode().rstrip().split("\n")

# create all the nodes of each machine type at once
# XXX: gcloud assumes that sys.stdin will always be not None, so we need to pass
#      dummy stdin (/dev/null)
for key, host_list in node_LuT.loc[hosts].groupby(["machine_type", "preemptible"]):
	machine_type, not_nonpreemptible_part = key

	# override 'preemptible' flag if this node is in the "non-preemptible" partition
	if not not_nonpreemptible_part:
	    k9_backend_conf['preemptible'] = ''
	else:
	    k9_backend_conf['preemptible'] = default_preemptible_flag

	host_table = subprocess.Popen(
	  """gcloud compute instances create {HOST_LIST} --image {image} \
	     --machine-type {MT} --zone {compute_zone} {compute_script} {preemptible} \
	     --tags caninetransientimage --format 'csv(name,networkInterfaces[0].networkIP)'
	  """.format(
	    HOST_LIST = " ".join(host_list.index), MT = machine_type, **k9_backend_conf
	  ), shell = True, executable = '/bin/bash', stdin = subprocess.DEVNULL, stdout = subprocess.PIPE
	)

	# update DNS (hostname -> internal IP)
	# TODO: replace this with SlurmctldParameters=cloud_dns in slurm.conf
	host_table = pd.read_csv(host_table.stdout)
	for _, name, ip in host_table.itertuples():
		subprocess.check_call("scontrol update nodename={} nodeaddr={}".format(name, ip), shell = True)
