#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys

def parse_args(zone, project):
	parser = argparse.ArgumentParser()
	parser.add_argument('--imagename', '-i', help = "Name of image to create")
	parser.add_argument('--zone', '-z', help = "Compute zone to create dummy instance in", default = zone)
	parser.add_argument('--project', '-p', help = "Compute project to create image in", default = project)

	args = parser.parse_args()

	# TODO: check args

	# validate zone
	# if ! grep -qE '(asia|australia|europe|northamerica|southamerica|us)-[a-z]+\d+-[a-z]' <<< "$ZONE"; then
	# 	echo "Error: invalid zone"
	# 	exit 1
	# fi

	return args

if __name__ == "__main__":
	#
	# ensure gcloud is installed
	try:
		subprocess.check_call("[ -f ~/.config/gcloud/config_sentinel ]", shell = True)
	except CalledProcessException:
		print("gcloud is not configured. Please run `gcloud auth login` and try again.", file = sys.stderr)
		sys.exit(1)

	#
	# get zone of current instance
	default_zone = subprocess.check_output("""gcloud compute instances list --filter="name=${HOSTNAME}" \
	  --format='csv[no-heading](zone)'""", shell = True)

	#
	# get current project (if any)
	default_proj = subprocess.check_output("gcloud config list --format='value(core.project)'", shell = True)

	#
	# parse arguments
	args = parse_args(zone, proj)
	zone = args.zone
	proj = args.project
	imagename = args.imagename

	#
	# get hostname
	host = "dummyhost-" + os.environ["USER"]

	#
	# create dummy instance to build image in
	try:
		subprocess.check_call("""gcloud compute --project {proj} instances create {host} --zone {zone} \
		  --machine-type n1-standard-1 --image ubuntu-minimal-1910-eoan-v20200107 \
		  --image-project ubuntu-os-cloud --boot-disk-size 50GB --boot-disk-type pd-standard \
		  --metadata-from-file startup-script=<(./container_host_image_startup_script.sh)""".format(
			host = host, proj = proj, zone = zone
		)

		#
		# wait for instance to be ready
		subprocess.check_call("""
		echo -n "Waiting for dummy instance to be ready ..."
		while ! gcloud compute ssh $HOST --zone $ZONE -- -o "UserKnownHostsFile /dev/null" \
		  "[ -f /started ]" &> /dev/null; do
			sleep 1
			echo -n ".";
		done
		echo""".format(
		)

		#
		# copy gcloud config to instance
		gcloud compute scp ~/.config/gcloud/* $HOST:.config/gcloud --zone $ZONE --recurse
		gcloud compute ssh $HOST --zone $ZONE -- -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -T \
		  "sudo cp -r ~/.config/gcloud /etc/gcloud"

		#
		# shut down dummy instance
		# (this is to avoid disk caching problems that can arise from imaging a running
		# instance)
		gcloud compute instances stop $HOST --zone $ZONE --quiet

		#
		# clone base image from dummy host's drive
		try:
			echo "Snapshotting dummy host drive ..."
			gcloud compute disks snapshot $HOST --snapshot-names ${HOST}-snap --zone $ZONE || \
			  { echo "Error creating snapshot!"; exit 1; }

			echo "Creating image from snapshot ..."
			gcloud compute images create $IMAGENAME --source-snapshot=${HOST}-snap --family slurm-gcp-docker-$USER || \
			  { echo "Error creating image!"; exit 1; }

		finally:
			echo "Deleting snapshot ..."
			gcloud compute snapshots delete ${HOST}-snap --quiet || { echo "Error deleting snapshot!"; exit 1; }

	#
	# delete dummy host
	finally:
		gcloud compute instances delete $HOST --zone $ZONE --quiet
