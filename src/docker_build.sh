#!/bin/bash

sudo apt-get -y install nfs-common

# TODO: implement a better check for whether gcloud is properly configured
#       simply checking for the existence of ~/.config/gcloud is insufficient
[ -d ~/.config/gcloud ] || { echo "gcloud has not yet been configured. Please run \`gcloud auth login'"; exit 1; }
cp -r ~/.config/gcloud gc_conf
sudo docker build -t broadinstitute/pydpiper:v0.1 -t broadinstitute/pydpiper:latest \
  --build-arg USER=$USER --build-arg UID=$UID --build-arg GID=$(id -g) .
rm -rf gc_conf

#
# push image to private registry

# allow private registry to be recognized sans certificate
if [ -f /etc/docker/daemon.json ]; then
	echo "Not overwriting /etc/docker/daemon.json. Please manually allow insecure registries."
else
	sudo tee /etc/docker/daemon.json > /dev/null <<< '{ "insecure-registries" : ["'$HOSTNAME':5000"] }'
	sudo systemctl restart docker
fi

echo -n "Waiting for Docker daemon to restart ..."
while ! systemctl is-active --quiet docker; do
	sleep 1
	echo -n "."
done
echo
docker run --rm -d --network host --name registry registry:2

# FIXME: ugly hack to ensure the registry container is up and running -- a
# casual search didn't turn up a better way to do this easily
sleep 10
#echo -n "Waiting for registry container to start ... "
#while [ `docker inspect -f {{.State.Running}} registry` != "true" ]; do
#	sleep 1
#	echo -n "."
#done
#echo
docker tag broadinstitute/pydpiper $HOSTNAME:5000/broadinstitute/pydpiper
docker push $HOSTNAME:5000/broadinstitute/pydpiper
