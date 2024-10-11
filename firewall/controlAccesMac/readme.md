# Configuraciones generales para el firewall

## configuraciones para permitir enrutamiento del firewall

- habilitar el reenvio

editar sysctl.confi 

```
sudo nano /etc/sysctl.conf

```

habilitar la opcion descomentando net.ipv4.ip_forward=1

Guardar y aplicar cambios

```
sudo sysctl -p

```
-  Configurar el NAT (Enmascaramiento) con iptables

si no se tiene instalado iptables 

```
sudo apt update
sudo apt install iptables

```

1. Habilitar el NAT (Enmascaramiento) -> cambiar interfaces segun caso wlp9s0 -> red externa, enp8s0 -> red interna

```
sudo iptables -t nat -A POSTROUTING -o wlp9s0 -j MASQUERADE

```

2. Permitir el tráfico entre las interfaces

Permitir el tráfico desde la máquina administradora hacia la red del router:

```
sudo iptables -A FORWARD -i enp8s0 -o wlp9s0 -j ACCEPT

```

Permitir el tráfico de retorno desde el router hacia la máquina administradora (solo para las conexiones establecidas o relacionadas):

```
sudo iptables -A FORWARD -i wlp9s0 -o enp8s0 -m state --state RELATED,ESTABLISHED -j ACCEPT

```


- hacer que los scripts sean ejecutables

```
chmod +x refresh_macs.sh

```
