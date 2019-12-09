FROM ubuntu:19.10

WORKDIR /tmp

RUN sudo cp -r ~/.config/gcloud /etc/gcloud && \
sudo apt-get update && \
sudo apt-get -y install build-essential vim git python3-pip nfs-kernel-server \
  nfs-common portmap libmariadb-dev mariadb-client mariadb-server \
  munge libmunge-dev libhwloc-dev cgroup-tools libreadline-dev ssed && \
sudo ln -s /usr/bin/python3 /usr/bin/python && \
sudo ln -s /usr/bin/pip3 /usr/bin/pip && \
sudo mkdir -p /mnt/nfs && \
wget https://download.schedmd.com/slurm/slurm-19.05.3-2.tar.bz2 && \
tar xjf slurm-19.05.3-2.tar.bz2 && \
cd slurm-19.05.3-2 && \
./configure --prefix=/usr/local --sysconfdir=/usr/local/etc \
  --with-mysql_config=/usr/bin --with-hdf5=no && \
make && sudo make install && \
sudo ssed -R -i '/GRUB_CMDLINE_LINUX_DEFAULT/s/(.*)"(.*)"(.*)/\1"\2 cgroup_enable=memory swapaccount=1"\3/' /etc/default/grub && \
sudo adduser --gecos "" --disabled-password slurm && \
sudo mkdir -p ~slurm/.config && sudo cp -r /etc/gcloud ~slurm/.config/gcloud && \
sudo chown -R slurm:slurm ~slurm/.config/gcloud && \
sudo mkdir -p /var/spool/slurm && sudo chown slurm:slurm /var/spool/slurm && \
sudo systemctl start mariadb && \
sudo mysql -u root -e "create user 'slurm'@'localhost'" && \
sudo mysql -u root -e "grant all on slurm_acct_db.* TO 'slurm'@'localhost';" && \
sudo git clone https://github.com/julianhess/cga_pipeline.git /usr/local/share/cga_pipeline && \
sudo pip install pandas canine

