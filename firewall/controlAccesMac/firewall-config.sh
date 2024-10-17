#!/bin/bash

# Definir las variables
TABLE="Firewall"
INTERFACE_ETH="enp8s0"
INTERFACE_WIFI="wlp9s0"
ADMIN_MAC="52:54:00:45:74:11"
FILE_MAC="acceso.mac"

# Limpiar las reglas anteriores
nft flush ruleset

# *** Habilitar el enrutamiento IP en el sistema ***
sysctl -w net.ipv4.ip_forward=1

# Crear la tabla de firewall
nft add table ip $TABLE

# Crear un set para las MACs permitidas en la tabla Firewall
nft add set ip $TABLE macs { type ether_addr\; }

# Crear una cadena para el tráfico de entrada (INPUT)
nft add chain ip $TABLE input { type filter hook input priority 0\; policy drop\; }

# Crear una cadena para el reenvío (FORWARD)
nft add chain ip $TABLE forward { type filter hook forward priority 0\; policy drop\; }

# Crear una cadena para el tráfico de salida (OUTPUT)
nft add chain ip $TABLE output { type filter hook output priority 0\; policy accept\; }

# Permitir siempre SSH desde la MAC de la máquina administradora
nft add rule ip $TABLE input iif $INTERFACE_ETH ether saddr $ADMIN_MAC tcp dport 22 accept

# *** Reglas para permitir tráfico entre red interna y externa ***

# Permitir tráfico de salida (FORWARD) de las MACs permitidas de la red interna (enp8s0) hacia la red externa (wlp9s0)
nft add rule ip $TABLE forward iif $INTERFACE_ETH oif $INTERFACE_WIFI ether saddr @macs accept

# Permitir tráfico de entrada (FORWARD) de la red externa (wlp9s0) hacia la red interna (enp8s0), solo para las MACs permitidas
nft add rule ip $TABLE forward iif $INTERFACE_WIFI oif $INTERFACE_ETH ether saddr @macs accept

# *** Reglas generales de reenvío entre las interfaces ***
nft add rule ip $TABLE forward iif $INTERFACE_ETH oif $INTERFACE_WIFI accept
nft add rule ip $TABLE forward iif $INTERFACE_WIFI oif $INTERFACE_ETH accept

# Bloquear todo el tráfico de MACs no permitidas en FORWARD
nft add rule ip $TABLE forward ether saddr != @macs drop

# *** Reglas de NAT para permitir salida a internet solo a las IPs permitidas ***

# Crear tabla NAT (enmascaramiento)
nft add table ip nat

# Crear un set para las IPs permitidas en la tabla NAT
nft add set ip nat ips { type ipv4_addr\; }

# Crear la cadena para NAT en postrouting
nft add chain ip nat postrouting { type nat hook postrouting priority 100 \; }

# Cargar las MACs permitidas desde el archivo acceso.mac y asociarles las IPs
if [ -s $FILE_MAC ]; then
    while IFS= read -r mac; do
        if [[ $mac =~ ^#.* || -z $mac ]]; then
            continue  # Ignorar comentarios y líneas vacías
        fi
        # Agregar la MAC permitida al conjunto de MACs
        nft add element ip $TABLE macs { $mac }

        # Obtener la IP correspondiente a la MAC desde la tabla ARP
        ip=$(ip neigh show | grep "$mac" | awk '{print $1}')
        if [[ -n $ip ]]; then
            nft add element ip nat ips { $ip }
            echo "MAC $mac tiene la IP $ip, agregada al conjunto ips"
        else
            echo "No se encontró una IP en la tabla ARP para la MAC $mac"
        fi
    done < $FILE_MAC
else
    echo "El archivo de MACs está vacío o no existe"
fi

# Regla de NAT solo para las IPs permitidas
nft add rule ip nat postrouting oif "$INTERFACE_WIFI" ip saddr @ips masquerade

echo "Reglas del firewall configuradas con éxito."
