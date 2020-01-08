FROM ubuntu:19.10

WORKDIR /tmp

#
# install Slurm/MySQL/NFS/cluster scripts

# 1. prereqs from apt
RUN apt-get update && \
apt-get -y install build-essential vim git python3-pip \
  nfs-common portmap libmariadb-dev mariadb-client mariadb-server \
  munge libmunge-dev libhwloc-dev cgroup-tools libreadline-dev ssed wget sudo

# 2. convenient symlinks; NFS mount folder
RUN ln -s /usr/bin/python3 /usr/bin/python && \
ln -s /usr/bin/pip3 /usr/bin/pip && \
mkdir -p /mnt/nfs

# 3. build Slurm
RUN wget https://download.schedmd.com/slurm/slurm-19.05.3-2.tar.bz2 && \
tar xjf slurm-19.05.3-2.tar.bz2 && \
cd slurm-19.05.3-2 && \
./configure --prefix=/usr/local --sysconfdir=/usr/local/etc \
  --with-mysql_config=/usr/bin --with-hdf5=no && \
make && make install

# 4. copy in gcloud config from host's build directory
COPY gc_conf /etc/gcloud

# 5. make Slurm directories
RUN adduser -u 1337 --gecos "" --disabled-password slurm && \
mkdir -p ~slurm/.config && cp -r /etc/gcloud ~slurm/.config/gcloud && \
chown -R slurm:slurm ~slurm/.config/gcloud && \
mkdir -p /var/spool/slurm && chown slurm:slurm /var/spool/slurm

# 6. configure MySQL
RUN mkdir -p /var/run/mysqld && chown mysql:mysql /var/run/mysqld && \
(mysqld & while ! mysqladmin -s status; do sleep 1; done ) && \
mysql -u root -e "create user 'slurm'@'localhost'" && \
mysql -u root -e "grant all on slurm_acct_db.* TO 'slurm'@'localhost';"

# 7. set up munge
RUN dd if=/dev/zero bs=1 count=1024 of=/etc/munge/munge.key

# 8. Python prereqs
RUN pip install pandas crcmod

# 9. install gcloud
RUN mkdir /gcsdk && \
wget -O gcs.tgz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-272.0.0-linux-x86_64.tar.gz && \
tar xzf gcs.tgz -C /gcsdk && \
/gcsdk/google-cloud-sdk/install.sh --usage-reporting false --path-update true --quiet && \
ln -s /gcsdk/google-cloud-sdk/bin/* /usr/bin

# 10. get cluster utility scripts
ARG cache_invalidate=2
RUN git clone https://github.com/julianhess/cga_pipeline.git /usr/local/share/cga_pipeline

# 11. add current user to container; enable passwordless sudo
ARG UID
ARG USER
RUN adduser -u $UID --gecos "" --disabled-password $USER && adduser $USER sudo
RUN ssed -i '/^%sudo/s/ALL$/NOPASSWD:ALL/' /etc/sudoers

#
# clean up /tmp
RUN rm -rf *

#
# set entrypoint
ENTRYPOINT /usr/local/share/cga_pipeline/src/docker_entrypoint.sh

#
# set Slurm environment
ENV SLURM_CONF "/mnt/nfs/clust_conf/slurm/slurm.conf"
