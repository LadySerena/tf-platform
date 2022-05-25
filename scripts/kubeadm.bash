#!/usr/bin/env bash

set -exo pipefail

sudo kubeadm init --pod-network-cidr 10.0.128.0/17 --service-cidr 10.1.0.0/17 --skip-phases=addon/kube-proxy --control-plane-endpoint kubernetes-control.internal.serenacodes.com:6443 --upload-certs
mkdir -p "$HOME/.kube"
sudo cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u)":"$(id -g)" "$HOME/.kube/config"

# use ~1 to be / see http://jsonpatch.com/#json-pointer
kubectl patch clusterrole edit --type=json -p '[{"op": "add", "path": "/metadata/labels/rbac.serenacodes.com~1aggregate-to-cluster-admin", "value":"true"}]'
