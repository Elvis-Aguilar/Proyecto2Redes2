#!/bin/bash

# Definir las variables
TABLE="Firewall"
INTERFACE_ETH="enp8s0"  # La interfaz Ethernet conectada a la red interna (intranet)
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

# *** Reglas para permitir tráfico entre red interna y externa ***

# Permitir tráfico de salida (FORWARD) de las MACs permitidas de la red interna (enp8s0) hacia la red externa (wlp9s0)
nft add rule ip $TABLE forward iif $INTERFACE_ETH oif $INTERFACE_WIFI ether saddr @macs accept

# Permitir tráfico de entrada (FORWARD) de la red externa (wlp9s0) hacia la red interna (enp8s0), solo para las MACs permitidas
nft add rule ip $TABLE forward iif $INTERFACE_WIFI oif $INTERFACE_ETH ether saddr @macs accept

# Bloquear todo el tráfico de MACs no permitidas en FORWARD
nft add rule ip $TABLE forward ether saddr != @macs drop

# *** Reglas de NAT para permitir salida a internet ***

# Configuración de NAT (enmascaramiento) para salir a internet
nft add table ip nat
nft add chain ip nat postrouting { type nat hook postrouting priority 100\; }
nft add rule ip nat postrouting oif "$INTERFACE_WIFI" masquerade

echo "Reglas del firewall configuradas con éxito."
