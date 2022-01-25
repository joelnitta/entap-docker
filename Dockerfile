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
# cmake for EnTAP, R gfortran libblas-dev for RSEM->EnTAP
  cmake \ 
  r-base \
  gfortran \
  libblas-dev

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

### Diamond ###
RUN APPNAME=diamond && \
    VERSION=v2.0.7 && \
    mkdir $APPS_HOME/$APPNAME && \
    cd $APPS_HOME/$APPNAME && \
    wget https://github.com/bbuchfink/$APPNAME/releases/download/$VERSION/$APPNAME-linux64.tar.gz && \
    tar -xzf $APPNAME-linux64.tar.gz && \
    rm $APPNAME-linux64.tar.gz 

ENV PATH=/apps/diamond/:$PATH

### TransDecoder ###
# use v5.3.0 as specified in EnTAP docs 
RUN APPNAME=TransDecoder && \
    VERSION=v5.3.0 && \
    mkdir $APPS_HOME/$APPNAME && \
    cd $APPS_HOME/$APPNAME && \
    wget https://github.com/$APPNAME/$APPNAME/archive/$APPNAME-$VERSION.tar.gz && \
    tar -xzf $APPNAME-$VERSION.tar.gz && \
    rm $APPNAME-$VERSION.tar.gz && \
# need to install a missing perl module
    cpan App::cpanminus && \
    cpanm URI::Escape

ENV PATH=/apps/TransDecoder/TransDecoder-TransDecoder-v5.3.0/:$PATH

### RSem ###
# v1.3.3 is bundled with EnTAP v.0.10.8-beta but lacks make file
# need to manually run install.packages("blockmodeling") or will get error
# https://github.com/deweylab/RSEM/issues/162
# 
RUN APPNAME=RSEM && \
    VERSION=1.3.3 && \
    mkdir $APPS_HOME/$APPNAME && \
    cd $APPS_HOME/$APPNAME && \
    wget https://github.com/deweylab/$APPNAME/archive/refs/tags/v$VERSION.tar.gz && \
    tar -xzf v$VERSION.tar.gz && \
    rm v$VERSION.tar.gz && \
    cd $APPNAME-$VERSION && \
    Rscript -e 'install.packages("blockmodeling")' \
    make && \
    make ebseq && \
    make install

### EnTAP ###

# Download EnTAP and build included deps
# https://entap.readthedocs.io/en/latest/Getting_Started/installation.html
RUN APPNAME=EnTAP && \
  VERSION=v0.10.8-beta && \
  mkdir $APPS_HOME/$APPNAME && \
  cd $APPS_HOME/$APPNAME && \
  wget https://gitlab.com/enTAP/EnTAP/-/archive/$VERSION/$APPNAME-$VERSION.tar.gz && \
  tar -xzf $APPNAME-$VERSION.tar.gz && \
  rm $APPNAME-$VERSION.tar.gz && \
  cd $APPS_HOME/$APPNAME/$APPNAME-$VERSION/ && \
  cmake CMakeLists.txt && \
  make

ENV PATH=/apps/EnTAP/EnTAP-v0.10.8-beta/:$PATH
