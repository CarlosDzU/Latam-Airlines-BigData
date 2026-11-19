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
echo "Master: $ID"

for puerto in 8888 8080 4040 18080; do
  aws ssm start-session --target "$ID" \
    --document-name AWS-StartPortForwardingSession \
    --parameters "portNumber=$puerto,localPortNumber=$puerto" >/dev/null &
done
trap 'kill $(jobs -p) 2>/dev/null' INT TERM EXIT

echo "Túneles abiertos:"
echo "  Jupyter         http://localhost:8888"
echo "  Spark master    http://localhost:8080"
echo "  Aplicación      http://localhost:4040"
echo "  History Server  http://localhost:18080"
echo "Ctrl+C para cerrar."
wait
