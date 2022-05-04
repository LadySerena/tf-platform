sudo kubeadm join kubernetes-control.internal.serenacodes.com:6443 \
  --control-plane \
  --certificate-key <foo> \
  --discovery-token-ca-cert-hash <bar> \
  --token <baz>
