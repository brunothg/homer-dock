#!/usr/bin/env bash

####################
# System variables #
####################

SELF_SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
DIR_SCRIPT="$(dirname "$SELF_SCRIPT")"
PWD_SCRIPT="$(pwd)"
echo "Running '$SELF_SCRIPT' in '$PWD_SCRIPT'"

#####################
# Load dependencies #
#####################

source "$DIR_SCRIPT/project.conf"

#################
# Prepare build #
#################

PROJECT_DTAG="$PROJECT_DTAG"
if [ -z "$PROJECT_DTAG" ]
then
  PROJECT_DTAG="localhost/${PROJECT_NAME:?}:${PROJECT_VERSION:?}"
fi

######################
# Build docker image #
######################
docker build -t "$PROJECT_DTAG" --build-arg ALPINE_VERSION="${ALPINE_VERSION:?}" --build-arg HOMER_VERSION="${HOMER_VERSION:?}" .
