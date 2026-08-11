#!/usr/bin/env fish
# Jalankan app sebagai web (web-server) dari Fish shell.
# Usage: fish scripts/run_web.fish
set SUPABASE_URL "https://novvbppilyiczgrfqble.supabase.co"
set SUPABASE_ANON_KEY "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vdnZicHBpbHlpY3pncmZxYmxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYxMTg5MDYsImV4cCI6MjEwMTY5NDkwNn0.-7kVx2AxM-hPvOf1QoI4JbviA_0ctunUIP_KNim8mU0"

flutter run -d web-server \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  $argv
