#!/usr/bin/env bash

gcloud compute instances create rpi-4-builder-k8s --project=telvanni-platform --zone=us-central1-a --machine-type=e2-standard-2 \
--network-interface=network-tier=PREMIUM,subnet=subnet-01 \
--no-restart-on-failure \
--maintenance-policy=TERMINATE --preemptible \
--service-account=tel-sa-pi-image-builder@telvanni-platform.iam.gserviceaccount.com \
--scopes=https://www.googleapis.com/auth/cloud-platform \
--image-project=telvanni-platform \
--image-family=rbi-builder \
--no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any \
--metadata-from-file=startup-script=./scripts/pi4-image.bash
