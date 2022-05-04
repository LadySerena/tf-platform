#!/usr/bin/env bash

set -ex

sudo mkdir -p /etc/systemd/resolved.conf.d

cat <<'EOF' | sudo tee /etc/systemd/resolved.conf.d/dns.conf
[DHCPV4]
UseDNS=false
[DHCPV6]
UseDNS=false
[Resolve]

EOF
