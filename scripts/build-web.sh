#!/usr/bin/env bash
set -euo pipefail
if ! command -v flutter >/dev/null 2>&1; then
  git clone --depth 1 --branch 3.50.0 https://github.com/flutter/flutter.git /tmp/verve-flutter
  export PATH="/tmp/verve-flutter/bin:$PATH"
fi
flutter config --no-analytics
flutter pub get
flutter build web --release --no-wasm-dry-run
