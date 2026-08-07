#!/usr/bin/env bash
# Build web app ke folder build/web, lalu serve lokal.
# Usage: ./scripts/build_web.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.env"

flutter build web \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

echo "Build selesai. Serve dengan: python3 -m http.server 8080 --directory build/web"
