#!/bin/bash

cd "`dirname "${BASH_SOURCE[0]}"`"

export LC_ALL=C

readonly IMAGE_NAME=mazko-github-pelican

docker image inspect $IMAGE_NAME > /dev/null 2>&1 || ./docker_build.sh

docker run --rm -it -v $PWD:/home/src $IMAGE_NAME sh -c '~/deploy.sh'