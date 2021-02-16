
## This is not startup script, but executed after slurm_gcp_docker source being copied to the image builder.
## This should run by user instead of root

## Redirect logs
sudo touch /post_started.log
sudo chmod 777 /post_started.log
exec > >(tee -a /post_started.log)
exec 2>&1

set -e

# Load docker base image
sudo docker load -i ~/tmp_docker_file

# Build current user into container
#cd /usr/local/share/slurm_gcp_docker/src/ && ./docker_build.sh && cd -
./docker_build.sh

sudo touch /post_started
