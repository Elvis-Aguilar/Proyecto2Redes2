#!/bin/bash

# Cambia estos valores seg  n tu red
SSID="NameWifi"
PASSWORD="PasxXXXxx"

# Activa la interfaz
sudo ip link set wlp9s0 up

# Crea el archivo de configuraci  n para wpa_supplicant
echo "network={
    ssid=\"$SSID\"
    psk=\"$PASSWORD\"
}" | sudo tee /etc/wpa_supplicant.conf > /dev/null

# Con  ctate a la red
sudo wpa_supplicant -B -i wlp9s0 -c /etc/wpa_supplicant.conf

# Obt  n una direcci  n IP
sudo dhclient wlp9s0

echo "Conectado a $SSID"