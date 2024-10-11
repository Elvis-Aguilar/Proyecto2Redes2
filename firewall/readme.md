# Guia de configuracion para Firewall (General-Inicial)

todas estas configuraciones (generales) son para el firewall, control de acceso a macs y control de ancho de banda...


## Configuraciones Iniciales

estas configuraciones son especificamente en la maquia (debian) para activar enrutamiento, ips estaticas e interfaces...



- actulizar paqueteria 

```
sudo apt-get update

```

- instalacion de nftables (ya lo tiene intalado debian), verificacion

```
sudo apt-get install nftables

```

si esta intalado le mostrara la version.


- instalacion de openssh-server, para ser accedido por ssh con el cliente... (maquina administradora)

```
sudo apt-get install openssh-server

```

configuracion de ssh server, iniciar instancia, activar y estado

```
sudo systemctl status ssh
sudo systemctl start ssh
sudo systemctl enable ssh

```

Editar el archivo /etc/ssh/sshd_config, para habilitar conexion mediante password

```
sudo nano /etc/ssh/sshd_config

```
Si deseas que el servidor permita solo autenticación por contraseña (y no por claves públicas), asegúrate de que la línea siguiente esté habilitada.

PasswordAuthentication yes
Pubkey... no

reiniciar instanci

```
sudo systemctl restart ssh

```

### Habilitar enrutamiento de la maquina

- habilitar el enrutamiento en el archivo /etc/sysctl.config

```
sudo nano /etc/sysctl.config

```

descomentar linea de ipv4 forward = 1

reiniciar

```
sudo sysctl -p

```


### Editar el archivo de interfaces de red

- comando para editar el archivo /etc/network/interfaces

```
sudo nano /etc/network/interfaces

```

- configuraciones para ips estaticas de la red Intranet(interna) y la externa que comunicara con el proxy

------------------------------------
auto lo
iface lo inet loopback

#configuracion de interfaz conectada con la intranet
auto enp0s25 # cambiar interfaz conectada a la intranet
iface enp0s25 inet static
address 192.168.1.1 #cambiar por ip asignada en el disenio de la intranet
netmask 255.255.255.0   #mascara de red, alternativa /24 en la linea de arriba

#configuracion de interfaz con la red externa (proxy)
auto enx00e04c360079    # cambiar por interfaz conectada con el proxy
iface enx00e04c360079 inet static
address 10.0.2.1        # ip de sub red con el proxy y firewall
netmask 255.255.255.252

----------------------------------

- guardar cambios -> contrl + o -> contrl + x

- reinicar servicio networking

```
sudo systemctl restart networking.service

```


