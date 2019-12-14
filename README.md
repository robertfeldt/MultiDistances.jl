# MultiDistances.jl

[![Build Status](https://travis-ci.com/robertfeldt/MultiDistances.jl.svg?branch=master)](https://travis-ci.com/robertfeldt/MultiDistances.jl)
[![Codecov](https://codecov.io/gh/robertfeldt/MultiDistances.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/robertfeldt/MultiDistances.jl)

Collect many string and object distances (including compression and set distances) into one Julia package.

Also includes a "binary" command line interface (CLI) for calculating distance (and full distance matrices) between files. Wraps this CLI in a docker file for ease of use.

# Running from docker file

For ease of use there is a docker file with a command line interface to calculate distances between files. Please see the docker hub readme for details: [mdist CLI on docker hub](https://hub.docker.com/r/robertfeldt/mdist/).