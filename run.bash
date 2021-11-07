#!/bin/bash

RUNNER=${RUNNER:-podman}
NAME=${NAME:-mpv}

"$RUNNER" run -it --name "$NAME" --replace mpv-ubuntu
