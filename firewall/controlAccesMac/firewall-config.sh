#!/bin/bash

# Definir las variables
TABLE="Firewall"
INTERFACE_ETH="enp8s0"  # La interfaz conectada la intranet
INTERFACE_WIFI="wlp9s0"  # La interfaz Wi-Fi conectada al proxy
ADMIN_MAC="00:e0:4c:36:00:89"  # MAC  máquina administradora
# Archivo que contiene las MACs permitidas
FILE="acceso.mac"

# Limpiar las reglas anteriores
nft flush ruleset

# Crear la tabla de firewall
nft add table ip $TABLE

# Crear un set para las MACs
nft add set ip $TABLE macs { type ether_addr; flags interval; }

# Crear una cadena para el tráfico de entrada (INPUT)
nft add chain ip $TABLE input { type filter hook input priority 0; }

# Crear una cadena para el reenvío (FORWARD)
nft add chain ip $TABLE forward { type filter hook forward priority 0; }

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

# Permitir tráfico ICMP (ping) solo para las MACs permitidas
nft add rule ip $TABLE input iif $INTERFACE_ETH ether saddr @macs ip protocol icmp accept

# Bloquear el tráfico ICMP para todas las demás MACs
nft add rule ip $TABLE input iif $INTERFACE_ETH ether saddr != @macs drop

# Configuración de NAT (Enmascaramiento)
nft add table ip nat
nft add chain ip nat postrouting { type nat hook postrouting priority 100; }
nft add rule ip nat postrouting oif "$INTERFACE_WIFI" masquerade

# Regla para bloquear todo lo que no esté en la lista de MACs permitidas
nft add rule ip $TABLE input iif $INTERFACE_ETH ether saddr != @macs drop

echo "Reglas del firewall configuradas con éxito."
