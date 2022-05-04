#!/usr/bin/env bash

set -exo pipefail

sudo kubeadm init --pod-network-cidr 10.0.128.0/17 --service-cidr 10.1.0.0/17 --skip-phases=addon/kube-proxy --control-plane-endpoint kubernetes-control.internal.serenacodes.com:6443 --upload-certs
mkdir -p "$HOME/.kube"
sudo cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u)":"$(id -g)" "$HOME/.kube/config"

helm repo add cilium https://helm.cilium.io/

helm install cilium cilium/cilium --version 1.11.1 \
    --namespace kube-system \
    --set kubeProxyReplacement=strict \
    --set tunnel=geneve \
    --set ipam.operator.clusterPoolIPv4PodCIDRList={10.0.128.0/17} \
    --set k8sServiceHost=kubernetes-control.internal.serenacodes.com \
    --set k8sServicePort=6443 \
    --set hubble.relay.enabled=true \
    --set hubble.ui.enabled=true \
    --set hubble.metrics.enabled="{dns,drop,tcp,flow,icmp,http}"

# use ~1 to be / see http://jsonpatch.com/#json-pointer
kubectl patch clusterrole edit --type=json -p '[{"op": "add", "path": "/metadata/labels/rbac.serenacodes.com~1aggregate-to-cluster-admin", "value":"true"}]'
