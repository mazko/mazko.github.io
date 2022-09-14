#!/bin/bash

cd "`dirname "${BASH_SOURCE[0]}"`"

export LC_ALL=C

readonly IMAGE_NAME=mazko-github-pelican

docker build --build-arg UID=$(id -u) --no-cache -t $IMAGE_NAME .