FROM ubuntu:19.10
MAINTAINER Daniel Pereira <daniel@garajau.com.br>

# Install the proxmox repo
RUN echo "deb http://download.proxmox.com/debian/pve buster pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list
ADD resources/proxmox-ve-release-6.x.gpg /etc/apt/trusted.gpg.d/proxmox-ve-release-6.x.gpg

# Install build dependencies
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y git nano screen patch fakeroot build-essential \
    devscripts libncurses5 libncurses5-dev libssl-dev bc flex bison libelf-dev \
    libaudit-dev libgtk2.0-dev libperl-dev libslang2-dev asciidoc xmlto \
    gnupg2 rsync lintian debhelper libdw-dev libnuma-dev sphinx-common \
    asciidoc-base automake cpio dh-python file gcc kmod libiberty-dev \
    libpve-common-perl libtool perl-modules python-minimal sed tar zlib1g-dev \
    lz4 awscli apt-utils && \
    apt-get clean && apt-get autoremove

# Create directory to compile the kernel
RUN install --directory -m 0755 /src && install --directory -m 0755 /patches

# Add binaries
ADD bin /usr/local/bin/
RUN chmod 0755 /usr/local/bin/*

# Add the patches
ADD patches /patches

# Make sure /src is a mountable volume
VOLUME /src
WORKDIR /src

# By default, run the whole build pipeline
CMD ["/bin/bash", "-c", "build-and-publish"]
