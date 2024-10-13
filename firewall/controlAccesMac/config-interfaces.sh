#!/bin/bash

# Comprobar si se ejecuta como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecute este script como root."
  exit
fi

# Definir el contenido nuevo para /etc/network/interfaces
new_config="auto lo
iface lo inet loopback

auto enp8s0
        iface enp8s0 inet static
        address 10.0.1.1/30
"

# Sobrescribir el archivo con la nueva configuración
echo "$new_config" > /etc/network/interfaces

# Reiniciar el servicio de red
systemctl restart networking.service

# Confirmar que todo ha sido exitoso
if [ $? -eq 0 ]; then
  echo "Configuración de red actualizada y servicio reiniciado exitosamente."
else
  echo "Hubo un problema al reiniciar el servicio de red."
fi
