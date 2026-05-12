#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$ROOT_DIR"

export GOMAXPROCS="${GOMAXPROCS:-2}"
export GOFLAGS="${GOFLAGS:--p=2}"

TARGET_OS="${TARGET_OS:-linux}"
TARGET_ARCH="${TARGET_ARCH:-amd64}"
OUTPUT="${OUTPUT:-dist/sui}"
CGO_ENABLED="${CGO_ENABLED:-1}"
DOWNLOAD_CRONET="${DOWNLOAD_CRONET:-1}"

BUILD_TAGS="${BUILD_TAGS:-with_quic,with_grpc,with_utls,with_acme,with_gvisor,with_naive_outbound,badlinkname,tfogo_checklinkname0,with_tailscale}"
LDFLAGS="${LDFLAGS:--w -s -checklinkname=0}"

if [ "$TARGET_OS" = "darwin" ]; then
  LDFLAGS="$LDFLAGS -extldflags \"-Wl,-no_warn_duplicate_libraries\""
fi

echo "==> Building frontend"
cd frontend
if [ -d node_modules ]; then
  npm run build
else
  npm install
  npm run build
fi

cd "$ROOT_DIR"
echo "==> Updating embedded frontend files"
mkdir -p web/html
rm -fr web/html/*
cp -R frontend/dist/. web/html/

mkdir -p "$(dirname "$OUTPUT")"

if [ "$DOWNLOAD_CRONET" = "1" ] && [ "$TARGET_OS" = "linux" ]; then
  CRONET_ARCH="$TARGET_ARCH"
  case "$TARGET_ARCH" in
    amd64|arm64|arm|386|riscv64|loong64|mipsle|mips64le) ;;
    *) echo "warning: no known libcronet download for linux/$TARGET_ARCH; skipping" >&2; CRONET_ARCH="" ;;
  esac

  if [ -n "$CRONET_ARCH" ]; then
    CRONET_URL="https://github.com/SagerNet/cronet-go/releases/latest/download/libcronet-linux-${CRONET_ARCH}.so"
    echo "==> Downloading libcronet.so for naive outbound runtime"
    if command -v curl >/dev/null 2>&1; then
      curl -fL "$CRONET_URL" -o dist/libcronet.so
    else
      wget -O dist/libcronet.so "$CRONET_URL"
    fi
    chmod 755 dist/libcronet.so
  fi
fi

echo "==> Building backend for ${TARGET_OS}/${TARGET_ARCH}"
CGO_ENABLED="$CGO_ENABLED" GOOS="$TARGET_OS" GOARCH="$TARGET_ARCH" \
  go build -trimpath -ldflags "$LDFLAGS" -tags "$BUILD_TAGS" -o "$OUTPUT" main.go

echo "==> Built $OUTPUT"
if [ -f dist/libcronet.so ]; then
  echo "==> Bundled dist/libcronet.so"
fi
