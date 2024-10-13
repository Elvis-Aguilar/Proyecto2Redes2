#!/bin/bash

# Definir la interfaz de red que será gestionada (modificar según tu red)
INTERFACE="enp8s0"  # Cambia esto por la interfaz adecuada (ej: enp8s0 para ethernet)

# Archivo de configuraciones de ancho de banda
BANDWIDTH_FILE="bw.ip"

# Limpiar las configuraciones anteriores de `tc`
echo "Limpiando reglas anteriores de control de tráfico en $INTERFACE..."
tc qdisc del dev $INTERFACE root 2>/dev/null
tc qdisc del dev $INTERFACE ingress 2>/dev/null  # Asegura eliminar la configuración de ingress también

# Aplicar una disciplina de cola raíz (root qdisc)
echo "Aplicando disciplina de cola raíz (HTB)..."
tc qdisc add dev $INTERFACE root handle 1: htb default 30

# Leer el archivo de configuraciones y aplicar las reglas
if [ -f "$BANDWIDTH_FILE" ]; then
    while IFS=, read -r ip up down; do
        if [[ "$ip" =~ ^#.* || -z "$ip" ]]; then
            continue  # Ignorar comentarios y líneas vacías
        fi

        echo "Configurando límite de ancho de banda para IP $ip: Subida ${up} kbps, Bajada ${down} kbps"

        # Crear una clase para esta IP en la cola raíz para controlar la bajada (ingreso)
        tc class add dev $INTERFACE parent 1: classid 1:1 htb rate ${down}kbps

        # Agregar una regla de filtro para esta IP (bajada)
        tc filter add dev $INTERFACE protocol ip parent 1:0 prio 1 u32 match ip dst $ip flowid 1:1

        # Configurar la limitación de subida (egreso) usando netem
        tc qdisc add dev $INTERFACE parent 1:1 handle 10: netem rate ${up}kbps

    done < "$BANDWIDTH_FILE"
else
    echo "Archivo de configuración $BANDWIDTH_FILE no encontrado."
    exit 1
fi

echo "Control de ancho de banda configurado con éxito en $INTERFACE."
