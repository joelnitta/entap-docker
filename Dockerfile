FROM python:3

MAINTAINER Joel Nitta joelnitta@gmail.com

ARG DEBIAN_FRONTEND=noninteractive

################
### apt deps ###
################

RUN apt-get update && \
# Add source for R to sources.list
  echo "deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/" >> /etc/apt/sources.list && \
  apt-get install -y --no-install-recommends \
# cmake for EnTAP, R for RSEM->EnTAP
  cmake \ 
  r-base

#########################
### install miniconda ###
#########################

ENV CONDA_DIR=/miniconda3

# make non-activate conda commands available
ENV PATH=$CONDA_DIR/bin:$PATH

RUN MINICONDA_VERSION=py37_4.9.2 && \
    wget https://repo.anaconda.com/miniconda/Miniconda3-$MINICONDA_VERSION-Linux-x86_64.sh -O ~/miniconda.sh && \
    chmod +x ~/miniconda.sh && \
    ~/miniconda.sh -b -p $CONDA_DIR && \
    rm ~/miniconda.sh

##################
### other apps ###
##################

# make dir for software installs
ENV APPS_HOME=/apps
RUN mkdir $APPS_HOME

### EnTAP ###

# Download EnTAP and build included deps
# https://entap.readthedocs.io/en/latest/Getting_Started/installation.html
RUN APPNAME=EnTAP && \
  VERSION=v0.10.7-beta && \
  mkdir $APPS_HOME/$APPNAME && \
  cd $APPS_HOME/$APPNAME && \
  wget https://gitlab.com/enTAP/EnTAP/-/archive/$VERSION/$APPNAME-$VERSION.tar.gz && \
  tar -xzf $APPNAME-$VERSION.tar.gz && \
  rm $APPNAME-$VERSION.tar.gz && \
  # install diamond
  cd $APPS_HOME/$APPNAME/$APPNAME-$VERSION/libs/diamond-0.9.9 && \
  mkdir bin && \
  cd bin && \
  cmake .. && \
  # install RSEM
  cd $APPS_HOME/$APPNAME/$APPNAME-$VERSION/libs/RSEM-1.3.0 && \
  make && \
  make ebseq && \
  make install && \
  cd $APPS_HOME/$APPNAME/$APPNAME-$VERSION/ && \
  cmake CMakeLists.txt && \
  make

### InterProScan ###

RUN APPNAME=interproscan && \
    VERSION=5.48-83.0 && \
    mkdir $APPS_HOME/$APPNAME && \
    cd $APPS_HOME/$APPNAME && \
# Download
    wget ftp://ftp.ebi.ac.uk/pub/software/unix/iprscan/5/$VERSION/$APPNAME-$VERSION-64-bit.tar.gz && \
    tar -pxzf $APPNAME-$VERSION-*-bit.tar.gz && \
    rm $APPNAME-$VERSION-*-bit.tar.gz && \
    cd $APPS_HOME/$APPNAME/$APPNAME-$VERSION && \
# Run setup script
    python3 initial_setup.py && \
# Build conda environment including java11 for InterProScan && \
    conda update --name base --channel defaults conda && \
    conda create -c conda-forge -n openjdk openjdk=11.* && \
    conda clean --all --yes && \
# Make shell script to run interproscan.sh in conda environment ###
# so that java11 is availabale
    TOOLNAME=interproscan.sh && \
    echo '#!/bin/bash' >> /usr/local/bin/$TOOLNAME && \
    echo "source $CONDA_DIR/etc/profile.d/conda.sh" >> /usr/local/bin/$TOOLNAME && \
    echo "conda activate openjdk" >> /usr/local/bin/$TOOLNAME  && \
    echo "$APPS_HOME/$APPNAME/$APPNAME-$VERSION/$TOOLNAME \"\$@\"" >> /usr/local/bin/$TOOLNAME  && \
    chmod 755 /usr/local/bin/$TOOLNAME

