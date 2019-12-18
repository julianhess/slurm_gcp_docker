#!/usr/bin/python3

import argparse
import io
import os
import pandas as pd
import re
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
			f.write("{k}={v}\n".format(
			  k = re.sub(r"^(NodeName|PartitionName)\d+$", r"\1", r[0]),
			  v = r[1]
			))

if __name__ == "__main__":
	CLUST_PROV_ROOT = os.environ["CLUST_PROV_ROOT"] if "CLUST_PROV_ROOT" in os.environ \
	                  else "/usr/local/share/cga_pipeline"
	#TODO: check if this is indeed a valid path

	ctrl_hostname = socket.gethostname()

	#
	# mount NFS server
	subprocess.check_call("{CPR}/src/nfs_provision_worker.sh {HN}-nfs".format(
	  CPR = shlex.quote(CLUST_PROV_ROOT),
	  HN = ctrl_hostname
	), shell = True)

	#
	# copy common files to NFS

	# ensure directories exist
	subprocess.check_call("""
	  [ ! -d /mnt/nfs/clust_conf/slurm ] && mkdir -p /mnt/nfs/clust_conf/slurm ||
	    echo -n
	  """, shell = True, executable = '/bin/bash')
	subprocess.check_call("""
	  [ ! -d /mnt/nfs/clust_scripts ] && mkdir -p /mnt/nfs/clust_scripts ||
	    echo -n
	  """, shell = True, executable = '/bin/bash')

	# Slurm conf. file cgroup.conf can be copied-as is (other conf. files will
	# need editing below)
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

	#
	# slurm.conf
	C = parse_slurm_conf("{CPR}/conf/slurm.conf".format(CPR = shlex.quote(CLUST_PROV_ROOT)))
	C[["ControlMachine", "ControlAddr", "AccountingStorageHost"]] = ctrl_hostname
	C["SuspendExcNodes"] = ctrl_hostname + "-nfs"

	# node definitions
	C["NodeName8"] = "{HN}-worker[1-100] CPUs=8 RealMemory=28000 State=CLOUD".format(HN = ctrl_hostname)
	C["NodeName1"] = "{HN}-worker[101-2000] CPUs=1 RealMemory=3000 State=CLOUD".format(HN = ctrl_hostname)
	C["NodeName4"] = "{HN}-worker[2001-3000] CPUs=4 RealMemory=23000 State=CLOUD".format(HN = ctrl_hostname)
	C["NodeName99"] = "{HN}-nfs CPUs=4 RealMemory=14000 State=CLOUD".format(HN = ctrl_hostname)

	# partition definitions
	C["PartitionName"] = "DEFAULT MaxTime=INFINITE State=UP".format(HN = ctrl_hostname)
	C["PartitionName8"] = "n1-standard-8 Nodes={HN}-worker[1-100]".format(HN = ctrl_hostname)
	C["PartitionName1"] = "n1-standard-1 Nodes={HN}-worker[101-2000]".format(HN = ctrl_hostname)
	C["PartitionName4"] = "n1-highmem-4 Nodes={HN}-worker[2001-3000]".format(HN = ctrl_hostname)
	C["PartitionName99"] = "nfs Nodes={HN}-nfs DEFAULT=YES".format(HN = ctrl_hostname)

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
	  echo -n "Waiting for Slurm conf ..."
	  while [ ! -f {conf_path} ]; do
	    sleep 1
	    echo -n "."
	  done
	  echo
	  export SLURM_CONF={conf_path};
	  pgrep slurmdbd || slurmdbd;
	  echo -n "Waiting for database to be ready ..."
	  while ! sacctmgr -i list cluster &> /dev/null; do
	    sleep 1
	    echo -n "."
	  done
	  echo
	  sacctmgr -i add cluster cluster
	  pgrep slurmctld || slurmctld -c -f {conf_path} &&
	    slurmctld reconfigure;
	  pgrep munged || munged -f
	  """.format(conf_path = "/mnt/nfs/clust_conf/slurm/slurm.conf"),
	  shell = True,
	  stderr = subprocess.DEVNULL,
	  executable = '/bin/bash'
	)
