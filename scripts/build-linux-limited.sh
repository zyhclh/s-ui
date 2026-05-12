#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"

export GOMAXPROCS=${GOMAXPROCS:-2}
export GOFLAGS="${GOFLAGS:--p=2}"

mkdir -p dist

BUILD_TAGS="${BUILD_TAGS:-with_quic,with_grpc,with_utls,with_acme,with_gvisor,with_naive_outbound,with_purego,with_tailscale}"
LDFLAGS="${LDFLAGS:--s -w}"

if [ -f frontend/package.json ]; then
  echo "==> Building frontend"
  cd frontend
  npm ci
  npm run build

  cd "$ROOT_DIR"
  echo "==> Updating embedded frontend files"
  mkdir -p web/html
  rm -fr web/html/*
  cp -R frontend/dist/. web/html/
fi

echo "==> Building backend for linux/amd64"
CGO_ENABLED=1 GOOS=linux GOARCH=amd64 \
  go build -trimpath -ldflags "$LDFLAGS" -tags "$BUILD_TAGS" -o dist/sui main.go

file dist/sui
ldd dist/sui || true
sha256sum dist/sui
