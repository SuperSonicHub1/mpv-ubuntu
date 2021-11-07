#!/bin/bash

RUNNER=${RUNNER:-podman}
VERSION=${1:-v0.34.0}

"$RUNNER" build -t mpv-ubuntu --build-arg VERSION="$VERSION"  .
