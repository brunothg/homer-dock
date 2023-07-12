#!/usr/bin/env bash

# Copyright 2023 brunothg
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0

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
docker build -t "$PROJECT_DTAG" --build-arg ALPINE_VERSION="${ALPINE_VERSION:?}" --build-arg HOMER_VERSION="${HOMER_VERSION:?}" "$@" .
