FROM python:3

MAINTAINER Joel Nitta joelnitta@gmail.com

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update

#########################
### install miniconda ###
#########################

ENV MINICONDA_VERSION=py37_4.9.2
ENV CONDA_DIR=/miniconda3

RUN wget https://repo.anaconda.com/miniconda/Miniconda3-$MINICONDA_VERSION-Linux-x86_64.sh -O ~/miniconda.sh && \
    chmod +x ~/miniconda.sh && \
    ~/miniconda.sh -b -p $CONDA_DIR && \
    rm ~/miniconda.sh

# make non-activate conda commands available
ENV PATH=$CONDA_DIR/bin:$PATH

# make conda activate command available from /bin/bash --login shells
RUN echo ". $CONDA_DIR/etc/profile.d/conda.sh" >> ~/.profile

# make conda activate command available from /bin/bash --interative shells
RUN conda init bash

# make dir for software installs
ENV APPS_HOME=/apps
RUN mkdir $APPS_HOME

### InterProScan ###

ENV APPNAME=interproscan
ENV VERSION=5.48-83.0
RUN mkdir $APPS_HOME/$APPNAME
WORKDIR $APPS_HOME/$APPNAME

RUN wget ftp://ftp.ebi.ac.uk/pub/software/unix/iprscan/5/$VERSION/$APPNAME-$VERSION-64-bit.tar.gz && \
    tar -pxzf $APPNAME-$VERSION-*-bit.tar.gz && \
    cd $APPNAME-$VERSION && \
    python3 initial_setup.py

# Build conda environment including java11 for InterProScan
RUN conda update --name base --channel defaults conda && \
    conda create -c conda-forge -n openjdk openjdk=11.* && \
    conda clean --all --yes

# Make shell script to run interproscan.sh in conda environment ###
# so that java11 is availabale

ENV TOOLNAME=interproscan.sh
RUN echo '#!/bin/bash' >> /usr/local/bin/$TOOLNAME && \
  echo "source $CONDA_DIR/etc/profile.d/conda.sh" >> /usr/local/bin/$TOOLNAME && \
  echo "conda activate openjdk" >> /usr/local/bin/$TOOLNAME  && \
  echo "$APPS_HOME/$APPNAME/$APPNAME-$VERSION/$TOOLNAME \"\$@\"" >> /usr/local/bin/$TOOLNAME  && \
  chmod 755 /usr/local/bin/$TOOLNAME
