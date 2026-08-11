#!/usr/bin/env bash
# Jalankan app di Android (emulator atau device).
# Usage dari bash/zsh: ./scripts/run_android.sh [flutter run flags tambahan]
# Usage dari fish: bash scripts/run_android.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.env"

flutter run \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  "$@"
