#!/bin/bash

# Definir la interfaz de red que será gestionada (modificar según tu red)
INTERFACE="enp8s0"

# Archivo de configuraciones de ancho de banda
BANDWIDTH_FILE="bw.ip"

# Limpiar las configuraciones anteriores de `tc`
echo "Limpiando reglas anteriores de control de tráfico en $INTERFACE..."
tc class del dev $INTERFACE root 2>/dev/null
tc qdisc del dev $INTERFACE root 2>/dev/null
tc qdisc del dev $INTERFACE ingress 2>/dev/null

# Aplicar una disciplina de cola raíz (root qdisc)
echo "Aplicando disciplina de cola raíz (HTB)..."
tc qdisc add dev $INTERFACE root handle 1: htb default 30

# Leer el archivo de configuraciones y aplicar las reglas
if [ -f "$BANDWIDTH_FILE" ]; then
    while IFS=, read -r ip up down; do
        if [[ "$ip" =~ ^#.* || -z "$ip" ]]; then
            continue  # Ignorar comentarios y líneas vacías
        fi

        # Generar un identificador único basado en el último octeto de la IP
        id=$(echo $ip | awk -F. '{print $NF}')

        echo "Configurando límite de ancho de banda para IP $ip: Subida ${up} kbps, Bajada ${down} kbps"

        # Crear una clase única para esta IP en la cola raíz para controlar la bajada (ingreso)
        tc class add dev $INTERFACE parent 1: classid 1:$id htb rate ${down}kbps

        # Agregar una regla de filtro para esta IP (bajada)
        tc filter add dev $INTERFACE protocol ip parent 1:0 prio 1 u32 match ip dst $ip flowid 1:$id

        # Configurar la limitación de subida (egreso) usando netem, con identificador único
        tc qdisc add dev $INTERFACE parent 1:$id handle $id: netem rate ${up}kbps

    done < "$BANDWIDTH_FILE"
else
    echo "Archivo de configuración $BANDWIDTH_FILE no encontrado."
    exit 1
fi

echo "Control de ancho de banda configurado con éxito en $INTERFACE."
