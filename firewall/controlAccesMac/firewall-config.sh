#!/bin/bash

# Nombre de la tabla y set para las MACs
TABLE="Firewall"
SET="macs"

# Archivo que contiene las MACs permitidas
FILE="acceso.mac"

# Interfaz de red interna
INTERFACE="enp0s25"  # Cambia esto a la interfaz correcta de tu red

# Limpiar las reglas anteriores
nft flush ruleset

# Crear la tabla de firewall
nft add table ip $TABLE

# Crear un set de MACs permitido en la tabla
nft add set ip $TABLE $SET { type ether_addr\; flags interval\; }

# Crear la cadena para el tráfico de entrada (INPUT)
nft add chain ip $TABLE INPUT { type filter hook input priority 0\; }

# Agregar reglas para permitir tráfico solo desde las MACs permitidas
nft add rule ip $TABLE INPUT iif $INTERFACE ether saddr != @macs drop

# Permitir tráfico ICMP (ping) para las MACs permitidas
nft add rule ip $TABLE INPUT iif $INTERFACE ether saddr @macs ip protocol icmp accept

# Agregar reglas para permitir acceso por SSH solo desde la máquina administradora
ADMIN_MAC="00:e0:4c:36:00:89"  # MAC del administrador
nft add rule ip $TABLE INPUT iif $INTERFACE ether saddr $ADMIN_MAC tcp dport 22 accept

# Recargar las MACs permitidas desde el archivo acceso.mac
if [ -s $FILE ]; then
    while IFS= read -r mac; do
        if [[ $mac =~ ^#.* || -z $mac ]]; then
            continue  # Ignorar comentarios y líneas vacías
        fi
        nft add element ip $TABLE $SET { $mac }
    done < $FILE
else
    echo "El archivo de MACs está vacío o no existe"
fi

echo "Firewall configurado exitosamente."
