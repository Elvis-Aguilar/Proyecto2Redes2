#!/bin/bash

#cambiar wlp9s0 y enp8s0 por las actuales, externa e interna respectivamente
iptables -t nat -A POSTROUTING -o wlp9s0 -j MASQUERADE
iptables -A FORWARD -i enp8s0 -o wlp9s0 -j ACCEPT
iptables -A FORWARD -i wlp9s0 -o enp8s0 -m state --state RELATED,ESTABLISHED -j ACCEPT
