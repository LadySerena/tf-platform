#!/usr/bin/env bash

set -exo pipefail

session="k8s-cluster"

tmux new-session -d -s "$session" \; split-window -v \; split-window -h 'ssh kat@melchior.internal.serenacodes.com' \; send-keys -t 1 'ssh kat@casper.internal.serenacodes.com' Enter \; send-keys -t 0 'ssh kat@balthasar.internal.serenacodes.com' Enter
tmux a -t k8s-cluster

