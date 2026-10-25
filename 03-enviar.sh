#!/bin/bash
# Etapa inicial (substituida pelo 04-coletar-repo.sh, que envia todos os PDFs).
# Envia um arquivo ao MinIO pela API S3, com a requisicao assinada (HMAC-SHA1).
# Uso: file=livros.html bash 03-enviar.sh

source .env

arquivo="$file"
bucket="${MINIO_BUCKET}"
objeto="${file#./}"
host="${MINIO_HOST}"
recurso="/${bucket}/${objeto}"
tipo="application/octet-stream"
data=$(date -R)
assinar="PUT\n\n${tipo}\n${data}\n${recurso}"
assinatura=$(echo -en "${assinar}" | openssl sha1 -hmac "${MINIO_SECRET}" -binary | base64)
curl -X PUT -T "${arquivo}" \
  -H "Host: ${host}" \
  -H "Date: ${data}" \
  -H "Content-Type: ${tipo}" \
  -H "Authorization: AWS ${MINIO_KEY}:${assinatura}" \
  "http://${host}${recurso}"
echo "Envio concluido. Confira em http://localhost:9001 (bucket ${bucket})."
