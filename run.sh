#!/usr/bin/env bash

####################
# System variables #
####################

SELF_SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
DIR_SCRIPT="$(dirname "$SELF_SCRIPT")"
PWD_SCRIPT="$(pwd)"
echo "Running '$SELF_SCRIPT' in '$PWD_SCRIPT'"

export PROJECT_DTAG="localhost/homer-dock:run"
"$DIR_SCRIPT/build.sh"
docker run -it --rm -p 8080:8080 "$PROJECT_DTAG" "$@"
docker rmi "$PROJECT_DTAG"
