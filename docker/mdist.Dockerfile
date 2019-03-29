# Pull base image.
FROM julia:1.1.0

MAINTAINER "Robert Feldt" robert.feldt@gmail.com

## Remain current
RUN apt-get update -qq \
&& apt-get dist-upgrade -y \
&& apt-get upgrade

RUN apt-get install -y build-essential

## Add tar and bzip2 and xz just as a convenience if we need them
## when working with large batches of files to be processed.
RUN apt-get install -y tar bzip2

########################
## Java (for tika)
########################

# Install Java. We only install JRE here, add default-jdk if you need the JDK.
#RUN apt-get update && apt-get install -y default-jre


########################
## poppler-utils for pdftotext
########################

#RUN apt-get install -y poppler-utils


########################
## Copy our files
########################

## Copy the files from this repo to the docker image
COPY . /usr/src/MultiDistances

########################
## Julia packages we need.
########################

# Install julia packages
COPY docker/installpackages.jl /tmp/installpackages.jl
RUN  julia /tmp/installpackages.jl

# By running instantiate it should download and install all packages we need.
# Not sure it compiles things etc though so skip for now...
#RUN  cd /usr/src/MultiDistances; julia -e 'using Pkg; Pkg.instantiate()'


########################
## Set up our commands
########################

## Link our main command so that it is in the path and executable.
RUN ln -s /usr/src/MultiDistances/bin/mdist /usr/bin/mdist \
&&  chmod +x /usr/bin/mdist \
&&  chmod +x /usr/src/MultiDistances/bin/mdist


########################
## Working dir path to access files from outside...
########################
WORKDIR /data


########################
## General stuff
########################

CMD ["/bin/bash"]
