**FORTE Dockerfile**

This repository contains docker images for the FORTE framework.

**Installation**

1. Install [Docker][1].

2. Download docker image: `docker pull robertfeldt/forte`

**Usage**

    docker run -it robertfeldt/forte forte

to see the commands available. More information and help by running either of the commands below.

To print the README:

    docker run -it robertfeldt/forte forte readme

To print help about available commands:

    docker run -it robertfeldt/forte forte -h

More detailed help about a forte command (here for the "analyse" command):

    docker run -it robertfeldt/forte forte analyse -h

To find information about how to map input files into the docker file:

    docker run -it robertfeldt/forte forte helpdocker

Example of how to run FORTE for common use cases:

    docker run -it robertfeldt/forte forte examples

Complex but realistic actual use example which performs analysis and then starts web server:
    docker run -it -p 42426:42426 -v /Users/feldt/dev/forte/test/data:/data robertfeldt/forte:latest forte analyse myinputfile.csv --featuremap myfeaturemap.csv -n -r --web

Same but serving the web pages on a different port:
    docker run -it -p 42426:42426 -v /Users/feldt/dev/forte/test/data:/data robertfeldt/forte:latest forte analyse myinputfile.csv --featuremap myfeaturemap.csv -n -r --web --port=42567

  [1]: https://www.docker.com/