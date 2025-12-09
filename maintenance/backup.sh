#!/bin/bash
# Módulo 3: Estrategia de Respaldo
# Debe ejecutarse como root o con sudo.

set -euo pipefail

SRC_DIR="/opt/webapp/html"
TMP_DIR="/tmp"
LOCAL_BACKUP_DIR="/var/backups/webapp"

# Configuración de destino remoto (ajustar según entorno real)
REMOTE_USER="backupuser"
REMOTE_HOST="localhost"
REMOTE_DIR="/home/backupuser/backups"

echo "[*] Verificando directorio de origen: ${SRC_DIR}"
if [ ! -d "${SRC_DIR}" ]; then
  echo "Error: el directorio ${SRC_DIR} no existe. ¿Ejecutaste setup.sh?" >&2
  exit 1
fi

echo "[*] Creando directorio local de backups: ${LOCAL_BACKUP_DIR}"
mkdir -p "${LOCAL_BACKUP_DIR}"

TIMESTAMP="$(date +%F_%H%M)"
BACKUP_FILENAME="backup_web_${TIMESTAMP}.tar.gz"
BACKUP_TMP_PATH="${TMP_DIR}/${BACKUP_FILENAME}"

echo "[*] Empaquetando y comprimiendo contenido de ${SRC_DIR}..."
tar -czf "${BACKUP_TMP_PATH}" -C "${SRC_DIR}" .

echo "[*] Sincronizando backup al directorio local mediante rsync..."
rsync -av "${BACKUP_TMP_PATH}" "${LOCAL_BACKUP_DIR}/"

echo "[*] Intentando transferencia segura (scp) al host remoto..."
# Crear directorio remoto (no falla si ya existe)
ssh "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p '${REMOTE_DIR}'" || true

scp "${BACKUP_TMP_PATH}" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/" || true
SCP_EXIT=$?

if [ "${SCP_EXIT}" -eq 0 ]; then
  echo "[*] Copia remota realizada correctamente (scp exit code 0)."
else
  echo "[!] Advertencia: la copia remota falló con código ${SCP_EXIT}. Revise conectividad/credenciales." >&2
fi

echo "[*] Respaldo completado. Archivo local:"
echo "    - ${LOCAL_BACKUP_DIR}/${BACKUP_FILENAME}"

