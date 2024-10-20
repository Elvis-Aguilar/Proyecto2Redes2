#!/bin/bash

# Definir las variables
TABLE="Firewall"
INTERFACE_ETH="enp8s0"          # Interfaz interna (red interna 192.168.10.0/24)
INTERFACE_WIFI="enx006f00011ab3" # Interfaz externa (red externa 10.0.1.0/30)
ADMIN_MAC="52:54:00:45:74:11"   # MAC de la máquina administradora
FILE_MAC="acceso.mac"           # Archivo de MACs permitidas

# Limpiar las reglas anteriores
nft flush ruleset

# Habilitar el enrutamiento IP en el sistema
sysctl -w net.ipv4.ip_forward=1

# Crear la tabla de firewall
nft add table ip $TABLE

# Crear un set para las MACs permitidas en la tabla Firewall
nft add set ip $TABLE macs { type ether_addr\; }

# Crear cadenas para INPUT, FORWARD, OUTPUT
nft add chain ip $TABLE input { type filter hook input priority 0\; policy drop\; }
nft add chain ip $TABLE forward { type filter hook forward priority 0\; policy drop\; }
nft add chain ip $TABLE output { type filter hook output priority 0\; policy accept\; }

# Crear tabla NAT para enmascarar tráfico saliente
nft add table ip nat

# Crear la cadena para NAT en postrouting
nft add chain ip nat postrouting { type nat hook postrouting priority srcnat\; }

# Permitir siempre SSH desde la MAC de la máquina administradora
nft add rule ip $TABLE input iif $INTERFACE_ETH ether saddr $ADMIN_MAC tcp dport 22 accept

# Permitir tráfico entre la red interna (enp8s0) y la red externa (enx006f00011ab3) solo para MACs permitidas
nft add rule ip $TABLE forward iif $INTERFACE_ETH oif $INTERFACE_WIFI ether saddr @macs accept
nft add rule ip $TABLE forward iif $INTERFACE_WIFI oif $INTERFACE_ETH ether saddr @macs accept

# Permitir todo el tráfico hacia y desde la red interna para las MACs permitidas
nft add rule ip $TABLE forward iif $INTERFACE_ETH ether saddr @macs accept

# Permitir conexiones establecidas y relacionadas para permitir el tráfico de retorno
nft add rule ip $TABLE forward ct state established,related accept

# Bloquear todo el tráfico de MACs no permitidas
nft add rule ip $TABLE forward ether saddr != @macs drop

# Cargar las MACs permitidas desde el archivo acceso.mac y obtener las IPs
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
            echo "MAC $mac tiene la IP $ip, se permite el tráfico hacia la red externa."
        else
            echo "No se encontró una IP en la tabla ARP para la MAC $mac"
        fi
    done < $FILE_MAC
else
    echo "El archivo de MACs está vacío o no existe"
fi

# Regla de NAT para enmascarar el tráfico saliente de cualquier máquina permitida
nft add rule ip nat postrouting oif "$INTERFACE_WIFI" masquerade

echo "Reglas del firewall configuradas con éxito."
