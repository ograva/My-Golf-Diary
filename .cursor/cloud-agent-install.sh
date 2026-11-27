#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

[ ! -d '/agent/repos/My-Golf-Diary' ] || cd '/agent/repos/My-Golf-Diary' || exit $?

sudo apt-get update -qq
sudo apt-get install -y -qq \
  ca-certificates \
  curl \
  git \
  unzip \
  xz-utils \
  zip \
  libsqlite3-0 \
  libsqlite3-dev \
  clang \
  cmake \
  ninja-build \
  pkg-config \
  libgtk-3-dev \
  liblzma-dev \
  libstdc++-12-dev \
  libstdc++-14-dev

NODE_VERSION=22.23.4
if ! /usr/local/bin/node -v 2>/dev/null | grep -qx "v${NODE_VERSION}"; then
  node_tmp="$(mktemp -d)"
  curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
    -o "$node_tmp/node-v${NODE_VERSION}-linux-x64.tar.xz"
  curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt" \
    -o "$node_tmp/SHASUMS256.txt"
  (
    cd "$node_tmp"
    grep " node-v${NODE_VERSION}-linux-x64.tar.xz$" SHASUMS256.txt | sha256sum -c -
  )
  sudo tar -xJf "$node_tmp/node-v${NODE_VERSION}-linux-x64.tar.xz" -C /usr/local --strip-components=1 --no-same-owner
  rm -rf "$node_tmp"
fi

FLUTTER_VERSION=3.47.0
flutter_meets_version() {
  [ -x /opt/flutter/bin/flutter ] \
    && /opt/flutter/bin/flutter --version 2>/dev/null | grep -q "Flutter $FLUTTER_VERSION"
}

if ! flutter_meets_version; then
  curl -fsSL \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    -o /tmp/flutter.tar.xz
  sudo rm -rf /opt/flutter
  sudo mkdir -p /opt
  sudo tar -xf /tmp/flutter.tar.xz -C /opt
  rm -f /tmp/flutter.tar.xz
fi

sudo chown -R "$(id -u):$(id -g)" /opt/flutter
sudo ln -sfn /opt/flutter/bin/flutter /usr/local/bin/flutter
sudo ln -sfn /opt/flutter/bin/dart /usr/local/bin/dart

flutter config --no-analytics --enable-linux-desktop >/dev/null
flutter precache --linux
(
  cd golf_diary_app
  flutter pub get
)
