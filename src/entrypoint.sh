#!/usr/bin/env bash

##############
# Run config #
##############
START_CMD=()
CHECK_CMD=()
STOP_CMD=()
RUN_USER=""
RUN_PID=""

check_pid() {
  if [ "$(ps -eo pid | grep -w "$RUN_PID" | wc -l)" -gt "0" ]
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


####################
# User/Group setup #
####################
HTTPD_USER="www-data"
HTTPD_USERID="${HTTPD_USERID:-82}"
HTTPD_GROUP="$HTTPD_USER"
HTTPD_GROUPID="${HTTPD_GROUPID:-$HTTPD_USERID}"
HTTPD_HOME="${HTTPD_HOME:-/var/www}"
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



###################
# HTTPD variables #
###################
HTTPD_IP="${HTTPD_IP:-*}"
HTTPD_PORT="${HTTPD_PORT:-8080}"
HTTPD_CONF="${HTTPD_CONF:-/etc/httpd.conf}"
HTTPD_WEBROOT="${HTTPD_WEBROOT:-$HTTPD_HOME}"

##############
# Config run #
##############
case "$1" in
  '' | 'httpd')
  echo "Start httpd server"
    START_CMD=(httpd -f -c "$HTTPD_CONF" -h "$HTTPD_WEBROOT" -p "$(if [ -n "$HTTPD_IP" ] && [ "$HTTPD_IP" != "*" ]; then echo "$HTTPD_IP:"; fi)$HTTPD_PORT")
    STOP_CMD=(kill_pid)
  ;;
  *)
    echo "Unknown command - run as is"
    START_CMD=("$@")
  ;;
esac
run
