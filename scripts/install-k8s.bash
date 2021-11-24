#!/usr/bin/env bash

# need to update world downloader thing to grab latest image
# add tracing to world downloader
# setup goreleaser for it?
# setup github actions for repo
# decompress image
# download image and mount it via `losetup -Pf ./arch-linux-arm-2021-11-23-1637701283.img`
# do config via nspawn
# upload it to the bucket
set -eo pipefail

echo "installing k8s on top of base image"
