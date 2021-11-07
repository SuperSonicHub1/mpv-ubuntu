#!/bin/bash

RUNNER=${RUNNER:-podman}
NAME=${NAME:-mpv}
DIR=${DIR:-"$PWD"}
VERSION=${1:-0.34.0}

"$RUNNER" cp "$NAME:/mpv_${VERSION}_amd64.deb" "$DIR"
