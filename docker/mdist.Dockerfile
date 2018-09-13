# Pull base image.
FROM julia:1.0.0

MAINTAINER "Robert Feldt" robert.feldt@gmail.com

## Remain current
RUN apt-get update -qq \
&& apt-get dist-upgrade -y \
&& apt-get upgrade

########################
## Julia packages we need.
########################

# Install julia packages
COPY docker/install/REQUIRE /tmp/REQUIRE
COPY docker/install/installpackages.jl /tmp/installpackages.jl
RUN  julia /tmp/installpackages.jl /tmp/REQUIRE

# Precompile julia packages
#COPY docker/install/precompile_packages.jl /tmp/precompile_packages.jl
#RUN julia /tmp/precompile_packages.jl


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
