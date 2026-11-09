#!/bin/bash
# ------------------------------------------------------------------
# backup_full.sh - TP Integrador Computacion Aplicada
# Ubicacion: /opt/scripts/backup_full.sh
#
# Genera un backup comprimido (.tar.gz) de un directorio ORIGEN
# y lo guarda en un directorio DESTINO.
# Nombre del archivo: <nombre_origen>_bkp_<YYYYMMDD>.tar.gz
#   Ej: /var/log  ->  log_bkp_20240302.tar.gz
# ------------------------------------------------------------------

mostrar_ayuda() {
    echo "Uso: $0 <origen> <destino>"
    echo ""
    echo "Genera un backup comprimido del directorio <origen> y lo guarda en <destino>."
    echo "El archivo se llama <nombre_origen>_bkp_<YYYYMMDD>.tar.gz"
    echo ""
    echo "Argumentos:"
    echo "  origen    Directorio que se quiere backupear (ej: /var/log)"
    echo "  destino   Directorio donde se guarda el backup (ej: /backup_dir)"
    echo ""
    echo "Opciones:"
    echo "  -help     Muestra esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 /var/log /backup_dir"
    echo "  $0 /www_dir /backup_dir"
}

# Opcion de ayuda
if [ "$1" = "-help" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    mostrar_ayuda
    exit 0
fi

# Validar cantidad de argumentos
if [ $# -ne 2 ]; then
    echo "ERROR: se necesitan 2 argumentos (origen y destino)."
    echo ""
    mostrar_ayuda
    exit 1
fi

ORIGEN="${1%/}"
DESTINO="${2%/}"

# Validar que el origen exista y sea un directorio legible
if [ ! -d "$ORIGEN" ] || [ ! -r "$ORIGEN" ]; then
    echo "ERROR: el origen '$ORIGEN' no existe o no se puede leer."
    exit 2
fi

# Validar que el sistema de archivos del origen este montado/disponible
if ! findmnt -T "$ORIGEN" > /dev/null 2>&1; then
    echo "ERROR: el sistema de archivos del origen '$ORIGEN' no esta disponible."
    exit 2
fi

# Validar que el destino exista y se pueda escribir
if [ ! -d "$DESTINO" ] || [ ! -w "$DESTINO" ]; then
    echo "ERROR: el destino '$DESTINO' no existe o no se puede escribir."
    exit 3
fi

# Validar que el destino sea un punto de montaje (la particion de backup)
if ! mountpoint -q "$DESTINO"; then
    echo "ERROR: el destino '$DESTINO' no es un sistema de archivos montado."
    echo "       Verifique que la particion este montada (mount -a)."
    exit 3
fi

FECHA=$(date +%Y%m%d)
NOMBRE=$(basename "$ORIGEN")
ARCHIVO="$DESTINO/${NOMBRE}_bkp_${FECHA}.tar.gz"

echo "Backup de '$ORIGEN' en '$ARCHIVO'..."
if tar -czf "$ARCHIVO" -C "$(dirname "$ORIGEN")" "$NOMBRE"; then
    echo "Backup finalizado correctamente."
    exit 0
else
    echo "ERROR: fallo la generacion del backup."
    exit 4
fi
