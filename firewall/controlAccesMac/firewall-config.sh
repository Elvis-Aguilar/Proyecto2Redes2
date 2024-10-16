#!/bin/bash

# Definir las variables
TABLE="Firewall"
INTERFACE_ETH="enp8s0"  # La interfaz Ethernet a la intranet
INTERFACE_WIFI="wlp9s0"  # La interfaz Wi-Fi conectada a la red externa (internet)
ADMIN_MAC="52:54:00:45:74:11" # MAC de la máquina administradora
FILE="acceso.mac"

# Limpiar las reglas anteriores
nft flush ruleset

# Crear la tabla de firewall
nft add table ip $TABLE

# Crear un set para las MACs permitidas
nft add set ip $TABLE macs { type ether_addr\; }

# Crear una cadena para el tráfico de entrada (INPUT)
nft add chain ip $TABLE input { type filter hook input priority 0\; policy drop\; }

# Crear una cadena para el reenvío (FORWARD)
nft add chain ip $TABLE forward { type filter hook forward priority 0\; policy drop\; }

# Crear una cadena para el tráfico de salida (OUTPUT) por si es necesario
nft add chain ip $TABLE output { type filter hook output priority 0\; policy accept\; }

# Permitir siempre SSH desde la MAC de la máquina administradora
nft add rule ip $TABLE input iif $INTERFACE_ETH ether saddr $ADMIN_MAC tcp dport 22 accept

# Cargar las MACs permitidas desde el archivo acceso.mac
if [ -s $FILE ]; then
    while IFS= read -r mac; do
        if [[ $mac =~ ^#.* || -z $mac ]]; then
            continue  # Ignorar comentarios y líneas vacías
        fi
        nft add element ip $TABLE macs { $mac }
    done < $FILE
else
    echo "El archivo de MACs está vacío o no existe"
fi

# Permitir todo el tráfico IP (TCP, UDP, ICMP, etc.) solo para las MACs permitidas
nft add rule ip $TABLE input iif $INTERFACE_ETH ether saddr @macs accept

# Permitir todo el tráfico entre la red interna y externa solo para las MACs permitidas (FORWARD)
# Tráfico de enp8s0 (red interna) hacia wlp9s0 (red externa, internet)
nft add rule ip $TABLE forward iif $INTERFACE_ETH oif $INTERFACE_WIFI ether saddr @macs accept

# Tráfico de wlp9s0 (red externa) hacia enp8s0 (red interna)
nft add rule ip $TABLE forward iif $INTERFACE_WIFI oif $INTERFACE_ETH ether saddr @macs accept

# Configuración de NAT (enmascaramiento) solo para las MACs permitidas
nft add table ip nat
nft add chain ip nat postrouting { type nat hook postrouting priority 100\; }
nft add rule ip nat postrouting oif "$INTERFACE_WIFI" ip saddr @macs masquerade

# Regla para bloquear todo lo que no esté en la lista de MACs permitidas (input y forward)
nft add rule ip $TABLE input iif $INTERFACE_ETH ether saddr != @macs drop
nft add rule ip $TABLE forward iif $INTERFACE_ETH ether saddr != @macs drop
nft add rule ip $TABLE forward iif $INTERFACE_WIFI ether saddr != @macs drop

echo "Reglas del firewall configuradas con éxito."
