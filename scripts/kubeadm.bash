#!/usr/bin/env bash

set -exo pipefail

sudo kubeadm init --pod-network-cidr 10.0.128.0/17 --service-cidr 10.1.0.0/17 --skip-phases=addon/kube-proxy
mkdir -p "$HOME/.kube"
sudo cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u)":"$(id -g)" "$HOME/.kube/config"

helm repo add cilium https://helm.cilium.io/

helm install cilium cilium/cilium --version 1.11.1 \
    --namespace kube-system \
    --set kubeProxyReplacement=strict \
    --set tunnel=geneve \
    --set ipam.operator.clusterPoolIPv4PodCIDRList={10.0.128.0/17} \
    --set k8sServiceHost=10.0.0.19 \
    --set k8sServicePort=6443 \
    --set hubble.relay.enabled=true \
    --set hubble.ui.enabled=true

helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/

helm upgrade --namespace kube-system --install metrics-server metrics-server/metrics-server \
    --set replicas=2 \
    --set args=\{"--kubelet-insecure-tls"\}

git clone https://github.com/prometheus-operator/kube-prometheus.git

cd kube-prometheus

kubectl create -f manifests/setup
until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done
kubectl create -f manifests/

helm upgrade cilium cilium/cilium --version 1.11.1 \
   --namespace kube-system \
   --reuse-values \
   --set hubble.metrics.serviceMonitor.enabled=true \
   --set hubble.metrics.enabled="{dns,drop,tcp,flow,icmp,http}"
