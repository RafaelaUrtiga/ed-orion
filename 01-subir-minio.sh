#!/bin/bash
# Etapa inicial (substituida pelo docker-compose.yml, que ja sobe o MinIO).
# Mantido para registrar como o projeto comecou.

source .env

docker rm -f minio 2>/dev/null
docker run -d --name minio \
  -p 9000:9000 \
  -p 9001:9001 \
  -v minio-data:/data \
  -e "MINIO_ROOT_USER=${MINIO_KEY}" \
  -e "MINIO_ROOT_PASSWORD=${MINIO_SECRET}" \
  minio/minio server /data --console-address ":9001"
echo "MinIO iniciado. Painel: http://localhost:9001"
