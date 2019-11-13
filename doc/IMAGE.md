# Notes on the compute image

All compute nodes (controller + workers) are spun up with an identical 
image — whether they serve as a controller or worker depends on external inputs (provision script).

This image is based on GCE image **Ubuntu 19.10 minimal**.  The following are steps to build our cluster image from this base image.

## Steps to generate image:

0. Set up dev environment

   0.1. Install `build-essential` (C/C++ compilers and headers)
   ```bash
   sudo apt-get install build-essential
   ```

   0.2. The Slurm installer explicitly expects `/usr/bin/env python`
   to be defined; thus we must
   ```bash
   sudo ln -s /usr/bin/python3 /usr/bin/python
   ```

1. Install NFS
   ```bash
   sudo apt-get install nfs-kernel-server nfs-common portmap
   ```
2. Install Slurm dependencies

   2.1. MySQL (MariaDB)
   ```bash
   sudo apt-get install libmariadb-dev mariadb-client
   ```

   2.2. Munge
   ```bash
   sudo apt-get install munge libmunge-dev
   ```

   2.3. Miscellaneous: to support cgroups and readline in the Slurm console
   ```bash
   sudo apt-get install libhwloc-dev cgroup-tools libreadline-dev
   ```
3. Install Slurm
 
   3.1. Download
   ```bash
   wget https://download.schedmd.com/slurm/slurm-19.05.3-2.tar.bz2 && \
   tar xjf slurm-19.05.3-2.tar.bz2
   ```

   3.2. Configure
   ```bash
   cd slurm-19.05.3-2 && \
   ./configure --prefix=/usr/local --sysconfdir=/usr/local/etc --with-mysql_config=/usr/bin --with-hdf5=no
   ```

   3.3. Build and install
   ```bash
   make && sudo make install
   ```
