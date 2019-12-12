FROM ubuntu:19.10

WORKDIR /tmp

#
# copy in gcloud config from host's build directory
COPY gc_conf /etc/gcloud

#
# install Slurm/MySQL/NFS/cluster scripts

# 1. prereqs from apt
RUN apt-get update && \
apt-get -y install build-essential vim git python3-pip nfs-kernel-server \
  nfs-common portmap libmariadb-dev mariadb-client mariadb-server \
  munge libmunge-dev libhwloc-dev cgroup-tools libreadline-dev ssed wget

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

# 4. make Slurm directories
RUN adduser --gecos "" --disabled-password slurm && \
mkdir -p ~slurm/.config && cp -r /etc/gcloud ~slurm/.config/gcloud && \
chown -R slurm:slurm ~slurm/.config/gcloud && \
mkdir -p /var/spool/slurm && chown slurm:slurm /var/spool/slurm

# 5. configure MySQL
RUN mkdir -p /var/run/mysqld && chown mysql:mysql /var/run/mysqld && \
(mysqld & while ! mysqladmin -s status; do sleep 1; done ) && \
mysql -u root -e "create user 'slurm'@'localhost'" && \
mysql -u root -e "grant all on slurm_acct_db.* TO 'slurm'@'localhost';"

# 6. get cluster utility scripts
RUN git clone https://github.com/julianhess/cga_pipeline.git /usr/local/share/cga_pipeline

# 7. Python prereqs
RUN pip install pandas canine

#
# install gcloud 
RUN wget -O gcs.tgz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-272.0.0-linux-x86_64.tar.gz && \
tar xzf gcs.tgz -C /root && \
/root/google-cloud-sdk/install.sh --usage-reporting false --path-update true --quiet

#
# clean up /tmp
RUN rm -rf *
