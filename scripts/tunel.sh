#!/usr/bin/env bash
# Abre túneles por Session Manager hacia el master del clúster:
#   8888 JupyterLab · 8080 Spark master · 4040 aplicación en curso · 18080 History Server
# Se deja corriendo mientras se trabaja; Ctrl+C cierra todos los túneles.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -f .env ]; then
  set -a
  . ./.env
  set +a
fi

ID=$(terraform -chdir=infra/procesamiento output -raw master_instance_id)
IP=$(terraform -chdir=infra/procesamiento output -raw master_private_ip)
echo "Master: $ID ($IP)"

# Jupyter escucha en la interfaz local del master; Spark escucha en su IP privada.
abrir() {
  local puerto=$1 destino=$2 nombre=$3
  if ss -ltn "sport = :$puerto" | grep -q LISTEN; then
    echo "  $nombre: el puerto $puerto ya está ocupado en esta máquina, no se abre"
    return
  fi
  if [ "$destino" = local ]; then
    aws ssm start-session --target "$ID" \
      --document-name AWS-StartPortForwardingSession \
      --parameters "portNumber=$puerto,localPortNumber=$puerto" >/dev/null &
  else
    aws ssm start-session --target "$ID" \
      --document-name AWS-StartPortForwardingSessionToRemoteHost \
      --parameters "host=$destino,portNumber=$puerto,localPortNumber=$puerto" >/dev/null &
  fi
  echo "  $nombre: http://localhost:$puerto"
}

trap 'kill $(jobs -p) 2>/dev/null' INT TERM EXIT

echo "Túneles:"
abrir 8888 local "Jupyter       "
abrir 8080 "$IP" "Spark master  "
abrir 4040 "$IP" "Aplicación    "
abrir 18080 "$IP" "History Server"
echo "Ctrl+C para cerrar."
wait
