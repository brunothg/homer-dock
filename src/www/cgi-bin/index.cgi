#!/bin/bash

# Copyright 2023 brunothg
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0

## Env
SELF_SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
SELF_DIR="$(dirname "$SELF_SCRIPT")"
HTTPD_HOME="${HTTPD_HOME:-"$(realpath "$SELF_DIR/..")"}"
REQUEST_PATH="$(realpath "${HTTPD_HOME}${REQUEST_URI}")"

export REQUEST_PATH


## Http handling
declare -A RESPONSE_HEADERS=( [Status]="200 OK" [Content-Type]="text/plain" )
RESPONSE_BODY=""

send_response() {
  ## Send response
  # Headers
  for key in "${!RESPONSE_HEADERS[@]}"; do printf "%s: %s\r\n" "$key" "${RESPONSE_HEADERS[$key]}"; done
  printf "\r\n"
  # Body
  if [ -n "$RESPONSE_BODY" ]
  then
    echo "$RESPONSE_BODY"
  fi

  exit 0
}


## Request handling
# Test Index redirect
if [ "$REQUEST_PATH" != "$SELF_SCRIPT" ]
then
  for file in "index.html" "index.exec"
  do
    if [ -f "$REQUEST_PATH/$file" ]
    then
      if [ -x "$REQUEST_PATH/$file" ]
      then
        export SCRIPT_NAME="$REQUEST_URI/$file"
        export SCRIPT_FILENAME="$REQUEST_PATH/$file"
        exec "$REQUEST_PATH/$file"
      else
        RESPONSE_HEADERS[Status]="307 Temporary Redirect"
        RESPONSE_HEADERS[Location]="$file"
        send_response
      fi
    fi
  done
fi

# Send default 404
RESPONSE_HEADERS[Status]="404 Not Found"
send_response
