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

export PROJECT_DTAG="localhost/homer-dock:run"
"$DIR_SCRIPT/build.sh" --no-cache
docker run -it --rm -p 8080:8080 "$PROJECT_DTAG" "$@"
docker rmi "$PROJECT_DTAG"
