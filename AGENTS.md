# S&I Finance Solution

Aplikasi admin catatan kredit/piutang (running balance + FIFO). Flutter: Android (offline-first,
drift SQLite + sync) & web (online-only langsung Supabase). Backend: Supabase.
Live: https://saifs.vercel.app

## Perintah
- Test: `flutter test`
- Analisis: `flutter analyze`
- Run Android: `bash scripts/run_android.sh` (dart-define dari .env)
- Run web: `bash scripts/run_web.sh`
- Build APK: `bash scripts/build_apk.sh` · Build web: `bash scripts/build_web.sh`
- Codegen drift: `dart run build_runner build --delete-conflicting-outputs`
- Push migration SQL: `npx supabase db push`
- Deploy Edge Function: `npx supabase functions deploy <nama>`
- Migrasi data Excel: `uv run --with openpyxl,requests scripts/migrate_data.py`

## Deploy Web (Vercel)
- `build/web` di-commit sebagai static release (sudah di `.gitignore` exception)
- Push ke `master` → Vercel auto-deploy
- URL: https://saifs.vercel.app
- Setelah ubah kode Flutter: build ulang (`bash scripts/build_web.sh`), lalu commit + push `build/web`

## Konvensi
- Teks UI Bahasa Indonesia. Uang = int rupiah. ID = UUIDv4 client-side.
- Terminologi UI: Nasabah (bukan Customer), Transaksi (bukan Purchase), Pembayaran (bukan Payment)
- Kolom `jenis` di purchases: barang | pinjaman | investasi | jasa/servis | modal usaha
- Soft delete (`deleted_at`). TDD untuk logika murni. Commit conventional.
- Spec: docs/superpowers/specs/. Plan: docs/superpowers/plans/.
- Kredensial hanya via .env / --dart-define; jangan commit. Data asli Excel: ref/ (sudah dimigrasi).
