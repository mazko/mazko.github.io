#!/bin/bash

cd "`dirname "${BASH_SOURCE[0]}"`"

export LC_ALL=C

readonly IMAGE_NAME=mazko-github-pelican

docker image inspect $IMAGE_NAME > /dev/null 2>&1 || ./docker_build.sh

docker run --rm -it -p 8000:8000 -v $PWD:/home/src $IMAGE_NAME sh -c '~/server.sh'