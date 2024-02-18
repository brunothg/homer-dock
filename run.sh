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

##################
# Setup dock cmd #
##################
DOCK_CMD="${DOCK_CMD}"
DOCK_CMD_FALLBACKS=( "$DOCK_CMD" podman docker )
for cmd in "${DOCK_CMD_FALLBACKS[@]}"
do
  if command -v "$cmd" &> /dev/null
  then
    DOCK_CMD="$cmd"
    break
  fi
done
if ! command -v "$DOCK_CMD" &> /dev/null
then
  echo "Set DOCK_CMD accordingly or install any of: ${DOCK_CMD_FALLBACKS[*]}"
  exit 1
fi

#################
# Prepare build #
#################
export PROJECT_DTAG="localhost/homer-dock:run"

######################
# Run docker image #
######################
echo "Run docker image: PROJECT_DTAG=$PROJECT_DTAG"
"$DIR_SCRIPT/build.sh" --no-cache
"$DOCK_CMD" run -it --rm -p 8080:8080 "$PROJECT_DTAG" "$@"
"$DOCK_CMD" rmi "$PROJECT_DTAG"
