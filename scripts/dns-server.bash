#!/usr/bin/env bash

set -ex

sudo apt-get update
sudo apt-get install nginx bind9 dnsutils

cat <<'EOF' | sudo tee /etc/bind/db.internal.serenacodes.com
;
; BIND data file for internal.serenacodes.com. homelab
;
$ORIGIN internal.serenacodes.com.
$TTL    604800
@       IN      SOA     dns.internal.serenacodes.com. internal.serenacodes.com. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      dns.internal.serenacodes.com.
dns      IN      A       10.0.0.11

; internal stuff
balthasar IN A 10.0.0.18
casper IN A 10.0.0.19
melchior IN A 10.0.0.20
kat@dns:~$ cat /etc/bind/db.0.0.10.in-addr.arpa
; reverse zone file
$ORIGIN 0.0.10.in-addr.arpa.
$TTL 604800
@       IN      SOA     dns.internal.serenacodes.com. internal.serenacodes.com. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      dns.internal.serenacodes.com.
11      IN      PTR     dns.internal.serenacodes.com.

; internal stuff

18 IN PTR balthasar
19 IN PTR casper
20 IN PTR melchior
EOF

cat <<'EOF' | sudo tee /etc/bind/db.0.0.10.in-addr.arpa
; reverse zone file
$ORIGIN 0.0.10.in-addr.arpa.
$TTL 604800
@       IN      SOA     dns.internal.serenacodes.com. internal.serenacodes.com. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      dns.internal.serenacodes.com.
11      IN      PTR     dns.internal.serenacodes.com.

; internal stuff

18 IN PTR balthasar
19 IN PTR casper
20 IN PTR melchior
EOF

cat <<'EOF' | sudo tee /etc/bind/named.conf.local
//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";

zone "internal.serenacodes.com" {
type master;
notify no;
file "/etc/bind/db.internal.serenacodes.com";
};

zone "0.0.10.in-addr.arpa" {
type master;
notify no;
file "/etc/bind/db.0.0.10.in-addr.arpa";
};
EOF

cat <<'EOF' | sudo tee /etc/nginx/nginx.conf
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
        worker_connections 768;
        # multi_accept on;
}

stream {
  upstream controlplane {
    server 10.0.0.18:6443; # balthasar.internal.serenacodes.com
    server 10.0.0.19:6443; # casper.internal.serenacodes.com
    server 10.0.0.20:6443; # melchior.internal.serenacodes.com
    # this block is configuring the ha k8s cluster control plane
  }

  server {
    listen 6443;
    proxy_pass controlplane;
  }

}
EOF

