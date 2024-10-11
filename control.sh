#!/bin/bash
#control maestro del administrador para automatizar el control de firewall, proxy


# Variables
FIREWALL_IP="10.0.1.1"
PROXY_IP="10.0.2.1"
USER="user"  

# Función para levantar el firewall
levantar_firewall() {
    echo "Levantando firewall..."
    ssh $USER@$FIREWALL_IP "sudo /home/usuario/firewall-config.sh"
}

# Editar el archivo de acceso.mac
edit_acceso_mac() {
    echo "Editando el archivo acceso.mac"
    ssh $USER@$FIREWALL_IP "sudo nano /home/usuario/acceso.mac"
}

# Función para levantar el proxy
levantar_proxy() {
    echo "Levantando proxy..."
    ssh $USER@$PROXY_IP "sudo /home/usuario/proxy.sh"
}

# Función para controlar Hamachi
control_hamachi() {
    echo "Controlando Hamachi en el Proxy..."
    ssh $USER@$PROXY_IP "sudo /home/usuario/hamachi.sh"
}

# Menú de opciones
echo "Seleccione la operación a realizar:"
echo "1) Levantar Firewall"
echo "2) Editar archivo acceso.mac"
echo "3) Levantar Proxy"
echo "4) Controlar Hamachi"
echo "5) Salir"

read -p "Opción: " opcion

case $opcion in
    1) levantar_firewall ;;
    2) edit_acceso_mac ;;
    3) levantar_proxy ;;
    4) control_hamachi ;;
    5) exit 0 ;;
    *) echo "Opción no válida" ;;
esac
