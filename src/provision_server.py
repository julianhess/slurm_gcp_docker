#!/usr/bin/python3

import argparse
import io
import os
import pandas as pd
import shlex
import socket
import subprocess

def parse_slurm_conf(path):
	output = io.StringIO()

	with open(path, "r") as a:
		for line in a:
			if len(line.split("=")) == 2:
				output.write(line)

	output.seek(0)

	return pd.read_csv(output, sep = "=", comment = "#", names = ["key", "value"], index_col = 0, squeeze = True)

def print_conf(D, path):
	with open(path, "w") as f:
		for r in D.iteritems():
			f.write("{k}={v}\n".format(k = r[0], v = r[1]))

if __name__ == "__main__":
	CLUST_PROV_ROOT = os.environ["CLUST_PROV_ROOT"] if "CLUST_PROV_ROOT" in os.environ \
	                  else "/usr/local/share/cga_pipeline"
	#TODO: check if this is indeed a valid path

	os.putenv("CLOUDSDK_CONFIG", "/etc/gcloud")

	#
	# process command line arguments
	argp = argparse.ArgumentParser()

	# NFS disk size
	argp.add_argument('--nfs_disk_size', '-s', type = int, default = 100)

	# NFS disk type
	argp.add_argument(
	  '--nfs_disk_type', '-t', type = str, choices = ['pd-standard', 'pd-ssd'], 
	  default = 'pd-standard'
	)

	args = argp.parse_args()

	#
	# set up NFS
	subprocess.check_call("{CPR}/src/nfs_provision_server.sh {disk_size} {disk_type}".format(
	  CPR = shlex.quote(CLUST_PROV_ROOT),
	  disk_size = shlex.quote(str(args.nfs_disk_size)),
	  disk_type = shlex.quote(args.nfs_disk_type)
	), shell = True)

	#
	# copy common files to NFS

	# ensure directories exist
	subprocess.check_call("""
	  [ ! -d /mnt/nfs/clust_conf/slurm ] && mkdir -p /mnt/nfs/clust_conf/slurm ||
	    echo -n
	  """, shell = True)
	subprocess.check_call("""
	  [ ! -d /mnt/nfs/clust_scripts ] && mkdir -p /mnt/nfs/clust_scripts ||
	    echo -n
	  """, shell = True)

	# Slurm conf. file cgroup.conf can be copied-as is (other conf. files will
	# need editing below
	subprocess.check_call(
	  "cp {CPR}/conf/cgroup.conf /mnt/nfs/clust_conf/slurm".format(
	    CPR = shlex.quote(CLUST_PROV_ROOT)
	  ),
	  shell = True
	)

	# scripts
	subprocess.check_call(
	  "cp {CPR}/src/* /mnt/nfs/clust_scripts".format(CPR = shlex.quote(CLUST_PROV_ROOT)),
	  shell = True
	)

	# TODO: copy the tool to run

	#
	# setup Slurm config files
	ctrl_hostname = socket.gethostname()

	#
	# slurm.conf
	C = parse_slurm_conf("{CPR}/conf/slurm.conf".format(CPR = shlex.quote(CLUST_PROV_ROOT)))
	C[["ControlMachine", "ControlAddr", "AccountingStorageHost", "SuspendExcNodes"]] = ctrl_hostname

	C["NodeName"] = "{HN}-worker[1-2000] CPUs=8 RealMemory=28000 State=CLOUD".format(HN = ctrl_hostname)
	C["PartitionName"] = "gce_cluster Nodes={HN}-worker[1-2000] Default=YES MaxTime=INFINITE State=UP OverSubscribe=YES:10".format(HN = ctrl_hostname)

	print_conf(C, "/mnt/nfs/clust_conf/slurm/slurm.conf")

	#
	# slurmdbd.conf
	C = parse_slurm_conf("{CPR}/conf/slurmdbd.conf".format(CPR = shlex.quote(CLUST_PROV_ROOT)))
	C["DbdHost"] = ctrl_hostname

	print_conf(C, "/mnt/nfs/clust_conf/slurm/slurmdbd.conf")

	#
	# start Slurm controller
	print("Checking for running Slurm controller ... ")

	subprocess.check_call("""
	  export SLURM_CONF={conf_path};
	  pgrep slurmdbd || slurmdbd;
	  pgrep slurmctld || slurmctld -c -f {conf_path} &&
	    slurmctld reconfigure;
	  pgrep munged || munged -f
	  """.format(conf_path = "/mnt/nfs/clust_conf/slurm/slurm.conf"),
	  shell = True,
	  stdout = subprocess.DEVNULL
	)
