Simple command line interface to calculate distances between files. Include a large number of distance functions, both classical ones (Levenshtein, Q-Grams etc) and compression based ones (NCD based on different compressors).

This is a command line interface to the [MultiDistances.jl][2] julia library.

## Installation

1. Install [Docker][1].

2. Download docker image: `docker pull robertfeldt/mdist`

## Usage

    docker run -it robertfeldt/mdist mdist

to see the commands available. More information and help by running either of the commands below.

### To print help about available commands

    docker run -it robertfeldt/mdist mdist -h

### To list all available distance functions

    docker run -it robertfeldt/mdist mdist distfuncs

### Calculate distance between two files

Here we use the ncd-bzip2 distance function:

    docker run -it -v "$PWD":/data robertfeldt/mdist mdist --distance ncd-bzip2 dist file1 file2

### Calculate distance matrix for a set of files

Here between all files in the directory some/dir using the Levenshtein distance:

    docker run -it -v "$PWD":/data robertfeldt/mdist mdist -d levenshtein distances some/dir

This will output a file distances.csv which contains the full distance matrix.

Note that some/dir must be mapped into the docker container so since we map "$PWD" into /data (in the docker container) some/dir must be available below "$PWD". If you want to calc distances of files in an absolute path /my/abs/path/dir-with-my-files do:

    docker run -it -v "/my/abs/path":/data robertfeldt/mdist mdist distances dir-with-my-files

### Find most similar and distant files to a file

Find the ten most similar and distant files to a file qfile when comparing it to the files in some/dir:

    docker run -it -v "$PWD":/data robertfeldt/mdist mdist --distance ncd-xz query qfile some/dir -n 10

Find the four most similar and distant files to a file qfile when comparing it to all files that recursively can be found under dir and that has a file extension of txt or md:

    docker run -it -v "$PWD":/data robertfeldt/mdist mdist --distance ncd-xz -r --file-extensions "txt,md" query qfile dir -n 4

### View license

View license information:

    docker run -it -v "$PWD":/data robertfeldt/mdist mdist license

Please cite our papers if you use mdist in your research. Or mail us to tell us you found it useful. This way we are more likely to update and evolve this tool. All feedback appreciated!

### View version

If you find problems please include the version information when mailing us. You can find it by:

    docker run -it -v "$PWD":/data robertfeldt/mdist mdist version

Of course, it would be best if you use the latest version of mdist before reporting a bug. Just do a:

    docker pull robertfeldt/mdist:latest

to ensure you are up-to-date. Thanks!

  [1]: https://www.docker.com/
  [2]: https://github.com/robertfeldt/MultiDistances.jl