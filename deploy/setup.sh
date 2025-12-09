#!/bin/bash
# Módulo 1: Aprovisionamiento de Infraestructura
# Debe ejecutarse como root o con sudo.

set -euo pipefail

DOCKER_COMPOSE_URL="https://gist.githubusercontent.com/DarkestAbed/0c1cee748bb9e3b22f89efe1933bf125/raw/5801164c0a6e4df7d8ced00122c76895997127a2/docker-compose.yml"
WEBAPP_DIR="/opt/webapp/html"
ALUMNO_NOMBRE="Anthony Ward"

echo "[*] Actualizando índices de paquetes e instalando dependencias básicas..."

if command -v apt-get >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y git curl ufw docker.io docker-compose-plugin
elif command -v dnf >/dev/null 2>&1; then
  dnf install -y git curl ufw docker docker-compose
elif command -v yum >/dev/null 2>&1; then
  yum install -y git curl ufw docker docker-compose
else
  echo "Error: No se detectó un gestor de paquetes compatible (apt, dnf, yum)." >&2
  exit 1
fi

echo "[*] Habilitando y arrancando el servicio de Docker (si aplica)..."
if command -v systemctl >/dev/null 2>&1; then
  systemctl enable docker || true
  systemctl start docker || true
fi

echo "[*] Creando estructura de directorios en ${WEBAPP_DIR}..."
mkdir -p "${WEBAPP_DIR}"

echo "[*] Descargando docker-compose.yml oficial al directorio deploy..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

curl -fsSL "${DOCKER_COMPOSE_URL}" -o docker-compose.yml

echo "[*] Generando archivo index.html..."
cat > "${WEBAPP_DIR}/index.html" <<EOF
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Servidor Seguro</title>
</head>
<body>
  <h1>Servidor Seguro Propiedad de Anthony Ward - Acceso Restringido</h1>
</body>
</html>
EOF

echo "[*] Creando usuario de sistema 'sysadmin' (si no existe) y agregándolo al grupo docker..."
if id sysadmin >/dev/null 2>&1; then
  echo "   - El usuario 'sysadmin' ya existe, se reutiliza."
else
  useradd -m -s /bin/bash sysadmin
  echo "   - Usuario 'sysadmin' creado."
fi

# Asegurar que el grupo docker existe
if ! getent group docker >/dev/null 2>&1; then
  groupadd docker
fi

usermod -aG docker sysadmin

echo "[*] Aprovisionamiento completado. El sistema está listo para desplegar contenedores."



