#!/bin/bash
#este script es para habilitar el enrutamiento entre interfaces y redirigir el trafico

nft flush ruleset
nft add table ip nat
nft add chain ip nat postrouting { type nat hook postrouting priority 100 \; }
nft add rule ip nat postrouting oif "wlp9s0" masquerade
#filters
nft add table ip filter
nft add chain ip filter forward { type filter hook forward priority 0 \; }
nft add rule ip filter forward iif "enp8s0" oif "wlp9s0" accept
nft add rule ip filter forward iif "wlp9s0" oif "enp8s0" accept
