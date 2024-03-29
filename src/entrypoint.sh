#!/usr/bin/env bash

# Copyright 2023 brunothg
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0

##############
# Run config #
##############
START_CMD=()
CHECK_CMD=()
STOP_CMD=()
RUN_USER=""
RUN_PID=""

check_pid() {
  if [ "$(ps -eo pid | grep -wc "$RUN_PID")" -gt "0" ]
  then
    echo "1"
  else
    echo "0"
  fi
}

kill_pid() {
  kill -SIGTERM "$RUN_PID"
}

run_exec() {
  echo "Exec -> ${START_CMD[*]@Q} -> as $RUN_USER"
  exec su -s /bin/bash -c "${START_CMD[*]@Q}" "$RUN_USER"
}

run_start_stop() {
  local running="1"
  trap 'running="0"' SIGINT SIGTERM SIGHUP

  echo "Start -> ${START_CMD[*]@Q} -> as $RUN_USER"
  su -s /bin/bash -c "${START_CMD[*]@Q}" "$RUN_USER" &
  RUN_PID="$!"

  if [ "${#CHECK_CMD[@]}" -eq "0" ]
  then
    CHECK_CMD=(check_pid)
  fi

  while [ "$running" -eq "1" ]
  do
    sleep 5
    if [ "$("${CHECK_CMD[@]}")" -ne "1" ]
    then
      running="0"
    fi
  done

  echo "Stop -> ${STOP_CMD[*]@Q}"
  "${STOP_CMD[@]}"
}

run() {
  if [ "${#STOP_CMD[@]}" -eq "0" ]
  then
    run_exec
  else
    run_start_stop
  fi
}


#####################
# Homer environment #
#####################
HOMER_WEB_CONFIG="${HOMER_WEB_CONFIG:-1}"

if [ "$HOMER_WEB_CONFIG" -eq "0" ]
then
  rm -rf "$HTTPD_HOME/config"
fi


#####################
# HTTPD environment #
#####################
export HTTPD_IP="${HTTPD_IP:-*}"
export HTTPD_PORT="${HTTPD_PORT:-8080}"
export HTTPD_CONF="${HTTPD_CONF:-/etc/httpd.conf}"
export HTTPD_WEBROOT="${HTTPD_WEBROOT:-/}"
export CGI_REDIRECT_STATUS="${CGI_REDIRECT_STATUS:-1}"

if [ -n "$HTTPD_WEBROOT" ] && [ "$HTTPD_WEBROOT" != "/" ]
then
  echo "Change webroot to '$HTTPD_WEBROOT'"
  tmp_dir="$(mktemp -d)"
  cp -a "$HTTPD_HOME/." "$tmp_dir" && rm -rf "${HTTPD_HOME:?}"/*
  mkdir -p "${HTTPD_HOME}${HTTPD_WEBROOT}"
  cp -a "$tmp_dir/." "${HTTPD_HOME}${HTTPD_WEBROOT}" && rm -rf "$tmp_dir"

  cgi_bin="${HTTPD_HOME}${HTTPD_WEBROOT}/cgi-bin"
  if [ -d "$cgi_bin" ]
  then
    mv -f "$cgi_bin" "$HTTPD_HOME"
  fi
fi


####################
# User/Group setup #
####################
export HTTPD_USER="www-data"
export HTTPD_USERID="${HTTPD_USERID:-82}"
export HTTPD_GROUP="$HTTPD_USER"
export HTTPD_GROUPID="${HTTPD_GROUPID:-$HTTPD_USERID}"
RUN_USER="$HTTPD_USER"

if [ -n "$(grep "$HTTPD_USER" "/etc/passwd" | cut -d ':' -f3)" ]
then
  deluser "$HTTPD_USER"
fi
if [ -n "$(grep "$HTTPD_GROUP" "/etc/group" | cut -d ':' -f3)" ]
then
  delgroup "$HTTPD_GROUP"
fi

addgroup --system --gid "$HTTPD_GROUPID" "$HTTPD_GROUP"
mkdir -p "$HTTPD_HOME"
adduser --system --home "$HTTPD_HOME" --uid "$HTTPD_USERID" --ingroup "$HTTPD_GROUP" "$HTTPD_USER"
chown -R "$HTTPD_USER:$HTTPD_GROUP" "$HTTPD_HOME"


##############
# Config run #
##############
case "$1" in
  '' | 'httpd')
    echo "Start httpd server"
    echo "Open localhost:$HTTPD_PORT${HTTPD_WEBROOT:-/}"
    START_CMD=(httpd -f -c "$HTTPD_CONF" -h "$HTTPD_HOME" -p "$(if [ -n "$HTTPD_IP" ] && [ "$HTTPD_IP" != "*" ]; then echo "$HTTPD_IP:"; fi)$HTTPD_PORT")
    STOP_CMD=(kill_pid)
  ;;
  *)
    echo "Unknown command - run as is"
    START_CMD=("$@")
  ;;
esac
run
