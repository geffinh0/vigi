#!/usr/bin/env bash
# Build do VIGI Família no Render (o ambiente do Render não traz o Flutter).
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.38.5}"
FLUTTER_HOME="${HOME}/flutter-${FLUTTER_VERSION}"

if [ ! -x "${FLUTTER_HOME}/bin/flutter" ]; then
  echo ">> Baixando Flutter ${FLUTTER_VERSION}..."
  mkdir -p "${FLUTTER_HOME}"
  curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    | tar -xJ -C "${FLUTTER_HOME}" --strip-components=1 \
    || { rm -rf "${FLUTTER_HOME}"; git clone --depth 1 -b "${FLUTTER_VERSION}" https://github.com/flutter/flutter.git "${FLUTTER_HOME}"; }
fi

export PATH="${FLUTTER_HOME}/bin:${PATH}"
git config --global --add safe.directory "${FLUTTER_HOME}" || true

flutter config --no-analytics >/dev/null
flutter --version
flutter pub get
flutter build web -t lib/main_family.dart --release

echo ">> Painel gerado em build/web"
