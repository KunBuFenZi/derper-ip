#!/bin/sh
set -e

DERP_HOST=${DERP_HOST:-derp.example.com}
DERP_PORT=${DERP_PORT:-36666}
CERTDIR=${CERTDIR:-/ssl}

if [ ! -f "$CERTDIR/$DERP_HOST.crt" ] || [ ! -f "$CERTDIR/$DERP_HOST.key" ]; then
  echo "[entrypoint] 生成自签证书: $DERP_HOST"
  mkdir -p "$CERTDIR"
  openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
    -keyout "$CERTDIR/$DERP_HOST.key" \
    -out "$CERTDIR/$DERP_HOST.crt" \
    -subj "/CN=$DERP_HOST" \
    -addext "subjectAltName=DNS:$DERP_HOST" >/dev/null 2>&1
fi

echo "[entrypoint] 启动 derper: host=$DERP_HOST port=$DERP_PORT certdir=$CERTDIR"
exec ./derper -hostname "$DERP_HOST" -a ":$DERP_PORT" -certmode manual -certdir "$CERTDIR"
