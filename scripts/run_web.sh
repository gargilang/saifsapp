#!/usr/bin/env bash
# Jalankan app sebagai web (web-server; buka di browser dari IP/port yang ditampilkan).
# Usage: ./scripts/run_web.sh [flutter run flags tambahan]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.env"

flutter run -d web-server \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  "$@"
