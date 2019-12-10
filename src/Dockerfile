FROM ubuntu:19.10

WORKDIR /tmp

COPY gc_conf /etc/gcloud

RUN apt-get update && \
apt-get -y install build-essential vim git python3-pip nfs-kernel-server \
  nfs-common portmap libmariadb-dev mariadb-client mariadb-server \
  munge libmunge-dev libhwloc-dev cgroup-tools libreadline-dev ssed wget && \
ln -s /usr/bin/python3 /usr/bin/python && \
ln -s /usr/bin/pip3 /usr/bin/pip && \
mkdir -p /mnt/nfs && \
wget https://download.schedmd.com/slurm/slurm-19.05.3-2.tar.bz2 && \
tar xjf slurm-19.05.3-2.tar.bz2 && \
cd slurm-19.05.3-2 && \
./configure --prefix=/usr/local --sysconfdir=/usr/local/etc \
  --with-mysql_config=/usr/bin --with-hdf5=no && \
make && make install && \
adduser --gecos "" --disabled-password slurm && \
mkdir -p ~slurm/.config && cp -r /etc/gcloud ~slurm/.config/gcloud && \
chown -R slurm:slurm ~slurm/.config/gcloud && \
mkdir -p /var/spool/slurm && chown slurm:slurm /var/spool/slurm && \
mkdir -p /var/run/mysqld && chown mysql:mysql /var/run/mysqld && mysqld & && \
mysql -u root -e "create user 'slurm'@'localhost'" && \
mysql -u root -e "grant all on slurm_acct_db.* TO 'slurm'@'localhost';" && \
git clone https://github.com/julianhess/cga_pipeline.git /usr/local/share/cga_pipeline && \
pip install pandas canine

