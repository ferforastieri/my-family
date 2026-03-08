#!/bin/bash
set -e

SERVER_HOST="${SERVER_HOST:-SEU_IP_OU_HOST}"
SERVER_USER="${SERVER_USER:-SEU_USUARIO}"
SERVER_PATH="${SERVER_PATH:-/caminho/no/servidor/lovepage}"
SSH_KEY="${SSH_KEY:-~/.ssh/sua_chave}"
SUDO_PASSWORD="${SUDO_PASSWORD:-}"

COMPOSE_BIN="/caminho/para/docker-compose"
COMPOSE_FILE="$SERVER_PATH/docker-compose.yml"
PROJECT_NAME="lovepage"

echo "🚀 Deploy Nossa Família (LovePage)"
echo "📁 Preparando arquivos..."

TEMP_DIR="/tmp/lovepage-deploy"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

cp -r backend/ "$TEMP_DIR/"
cp -r web/ "$TEMP_DIR/"
cp -r nginx/ "$TEMP_DIR/"
cp docker-compose.yml "$TEMP_DIR/"
cp Dockerfile.front "$TEMP_DIR/"
cp Dockerfile.backend "$TEMP_DIR/"

find "$TEMP_DIR" -name "node_modules" -type d -exec rm -rf {} + 2>/dev/null || true
find "$TEMP_DIR" -name ".git" -type d -exec rm -rf {} + 2>/dev/null || true
find "$TEMP_DIR" -name "dist" -type d -exec rm -rf {} + 2>/dev/null || true

echo "📤 Enviando para servidor..."
rsync -av --progress -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $SSH_KEY" "$TEMP_DIR/" "$SERVER_USER@$SERVER_HOST:$SERVER_PATH/"

echo "🚀 Iniciando no servidor..."
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" "$SERVER_USER@$SERVER_HOST" << EOF
set -e
cd $SERVER_PATH

SUDO_PASS="$SUDO_PASSWORD"
run_sudo() { echo "\$SUDO_PASS" | sudo -S "\$@"; }
run_docker() {
  if docker ps >/dev/null 2>&1; then docker "\$@"; else run_sudo docker "\$@"; fi
}
run_compose() {
  if COMPOSE_PROJECT_NAME=$PROJECT_NAME $COMPOSE_BIN -f $COMPOSE_FILE ps >/dev/null 2>&1; then
    COMPOSE_PROJECT_NAME=$PROJECT_NAME $COMPOSE_BIN -f $COMPOSE_FILE "\$@"
  else
    run_sudo env COMPOSE_PROJECT_NAME=$PROJECT_NAME $COMPOSE_BIN -f $COMPOSE_FILE "\$@"
  fi
}

mkdir -p /DATA/.docker/buildx 2>/dev/null || run_sudo mkdir -p /DATA/.docker/buildx || true
chown -R \$USER:\$USER /DATA/.docker 2>/dev/null || run_sudo chown -R \$USER:\$USER /DATA/.docker || true

export VITE_API_URL="http://$SERVER_HOST:3459/api"
run_docker rm -f lovepage-front lovepage-backend 2>/dev/null || true
# Não usar "compose down" para não afetar o Atacte no mesmo servidor
run_compose up -d --build

sleep 10
run_compose ps
run_compose logs --tail=20

echo "✅ Deploy concluído!"
EOF

rm -rf "$TEMP_DIR"
echo "🎉 Concluído. Front: http://$SERVER_HOST:3458  API: http://$SERVER_HOST:3459"
