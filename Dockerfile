FROM ubuntu:16.04
RUN apt-get update && apt-get -y dist-upgrade && apt-get install -y curl wget build-essential gcc git \
     make python2.7 squashfs-tools libblas-dev liblapack-dev
RUN git clone https://github.com/c9/core.git /c9 && \
    cd /c9 && \
    scripts/install-sdk.sh


# "$C9_DIR/node/bin/:$C9_DIR/node_modules/.bin:$PATH"

## Set a default user. Available via runtime flag `--user docker` 
## Add user to 'staff' group, granting them write privileges to /usr/local/lib/R/site.library
## User should also have & own a home directory (for rstudio or linked volumes to work properly). 
RUN useradd -u 1000 docker \
	&& mkdir /home/docker \
	&& chown docker:docker /home/docker \
	&& addgroup docker staff

RUN apt-get install -y --no-install-recommends \
		ed \
		less \
		locales \
		vim-tiny \
		wget \
		ca-certificates \
		fonts-texgyre 

## Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
	&& locale-gen en_US.utf8 \
	&& /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

## Use Debian unstable via pinning -- new style via APT::Default-Release
#RUN echo "deb http://http.debian.net/debian sid main" > /etc/apt/sources.list.d/debian-unstable.list \
#	&& echo 'APT::Default-Release "testing";' > /etc/apt/apt.conf.d/default

ENV R_BASE_VERSION 3.3.3

## Now install R and littler, and create a link for littler in /usr/local/bin
## Also set a default CRAN repo, and make sure littler knows about it too
ADD ubuntukey.pub /tmp
RUN apt-get update 
RUN apt-get install -y software-properties-common python-software-properties apt-transport-https
RUN apt-key add /tmp/ubuntukey.pub
RUN add-apt-repository 'deb [arch=amd64,i386] https://cran.rstudio.com/bin/linux/ubuntu xenial/'

RUN apt-get update && apt-get install -y \
		littler \
                r-cran-littler \
		r-base=${R_BASE_VERSION}* \
		r-base-dev=${R_BASE_VERSION}* \
		r-recommended=${R_BASE_VERSION}* \
        && echo 'options(repos = c(CRAN = "https://cran.rstudio.com/"), download.file.method = "libcurl")' >> /etc/R/Rprofile.site \
        && echo 'source("/etc/R/Rprofile.site")' >> /etc/littler.r \
	&& ln -s /usr/share/doc/littler/examples/install.r /usr/local/bin/install.r \
	&& ln -s /usr/share/doc/littler/examples/install2.r /usr/local/bin/install2.r \
	&& ln -s /usr/share/doc/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
	&& ln -s /usr/share/doc/littler/examples/testInstalled.r /usr/local/bin/testInstalled.r \
	&& install.r docopt \
	&& rm -rf /tmp/downloaded_packages/ /tmp/*.rds \

ENV SLURM_VER=16.05.11

RUN apt-get install -y munge curl gcc make bzip2 supervisor python python-dev \
    libmunge-dev libmunge2 lua5.2 lua5.2-dev libopenmpi-dev openmpi-bin \
    gfortran vim python-mpi4py python-numpy python-psutil psmisc \
    software-properties-common python-software-properties iputils-ping \
    openssh-server openssh-client default-jdk

ENV SLURM_VER=16.05.11
#RUN apt-get install -y slurm-wlm munge
# Download, compile and install SLURM
RUN curl -fsL https://download.schedmd.com/slurm/slurm-16.05.11.tar.bz2 | tar xfj - -C /opt/ && \
    cd /opt/slurm-${SLURM_VER}/ && \
    ./configure && make && make install

RUN chown root /var/log/munge
RUN mkdir /var/run/munge
RUN chown root /var/lib/munge
RUN chown root /etc/munge/munge.key
RUN chmod 600 /etc/munge/munge.key
RUN chown root /etc/munge

# Add singularity
RUN apt-get -y install build-essential curl git man vim autoconf libtool default-jdk
RUN apt-get -y install python
RUN git clone https://github.com/singularityware/singularity.git
RUN cd singularity && git fetch origin pull/1106/head:PR1106 && git checkout PR1106 && ./autogen.sh && ./configure --prefix=/usr/local && make && make install
#
# Add nextflow
RUN cd / && cd /usr/local/bin && curl -fsSL get.nextflow.io | bash
RUN chmod +rw /usr/local/bin/nextflow

RUN install2.r rslurm
RUN chmod -R o+rw /c9
USER docker
RUN cd /home/docker && /c9/scripts/install-sdk.sh
USER root
RUN mkdir /templates
RUN cp -r /home/docker/.c9 /templates
ADD userconf.sh /userconf.sh
RUN chmod +x /userconf.sh
RUN mkdir /var/run/sshd
RUN useradd slurm
RUN rm -rf /var/lib/apt/lists/*
CMD "/userconf.sh"
