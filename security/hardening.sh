#!/bin/bash
# Módulo 2: Endurecimiento del Sistema
# Debe ejecutarse como root o con sudo.

set -euo pipefail

echo "[*] Configurando firewall UFW..."

# Habilitar UFW con política por defecto: denegar todo el tráfico entrante
ufw default deny incoming
ufw default allow outgoing

# Permitir únicamente SSH (22) y la aplicación web (8080)
ufw allow 22/tcp
ufw allow 8080/tcp

# Habilitar UFW sin pedir confirmación interactiva
ufw --force enable

echo "[*] Firewall configurado. Puertos permitidos: 22/tcp, 8080/tcp."

echo "[*] Endureciendo configuración de SSH en /etc/ssh/sshd_config..."

SSHD_CONFIG="/etc/ssh/sshd_config"

# Deshabilitar acceso directo de root: PermitRootLogin no
if grep -qE "^[#]*\s*PermitRootLogin" "${SSHD_CONFIG}"; then
  sed -i 's/^[#]*\s*PermitRootLogin.*/PermitRootLogin no/' "${SSHD_CONFIG}"
else
  echo "PermitRootLogin no" >> "${SSHD_CONFIG}"
fi

echo "[*] Recargando servicio SSH..."
if command -v systemctl >/dev/null 2>&1; then
  systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
else
  service sshd reload 2>/dev/null || service ssh reload 2>/dev/null || true
fi

echo "[*] Ajustando permisos de archivos sensibles (principio de menor privilegio)..."

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Scripts y docker-compose.yml con permisos restrictivos
chmod 700 "${REPO_ROOT}/maintenance/backup.sh" || true
chmod 700 "${REPO_ROOT}/security/hardening.sh" || true
chmod 700 "${REPO_ROOT}/deploy/setup.sh" || true
chmod 600 "${REPO_ROOT}/deploy/docker-compose.yml" || true

echo "[*] Hardening completado. El sistema está más protegido frente a accesos no autorizados."

