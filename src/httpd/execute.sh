#!/usr/bin/env bash
exec "$(realpath "$1")" "${@:2}"
