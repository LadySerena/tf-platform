#!/usr/bin/env bash

gcloud compute instances create rpi-4-builder-k8s --project=telvanni-platform --zone=us-central1-a \
--machine-type=e2-standard-2 --network-interface=network-tier=PREMIUM,subnet=subnet-01 --no-restart-on-failure \
--maintenance-policy=TERMINATE --preemptible \
--service-account=tel-sa-pi-image-builder@telvanni-platform.iam.gserviceaccount.com \
--scopes=https://www.googleapis.com/auth/cloud-platform \
--create-disk=auto-delete=yes,boot=yes,device-name=rpi-4-builder-k8s,image=projects/telvanni-platform/global/images/rpi-builder-2021-12-18-4-1-1,mode=rw,size=20,type=projects/telvanni-platform/zones/us-central1-a/diskTypes/pd-balanced \
--no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any