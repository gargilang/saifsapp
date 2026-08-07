# SandiApp

Aplikasi admin kredit barang (running balance + FIFO). Flutter: Android (offline-first,
drift SQLite + sync) & web (online-only langsung Supabase). Backend: Supabase.

## Perintah
- Test: `flutter test`
- Analisis: `flutter analyze`
- Run Android: `./scripts/run_android.sh` (dart-define diambil dari .env)
- Run web: `./scripts/run_web.sh`
- Build APK: `./scripts/build_apk.sh` · Build web: `./scripts/build_web.sh`
- Codegen drift: `dart run build_runner build --delete-conflicting-outputs`

## Konvensi
- Teks UI Bahasa Indonesia. Uang = int rupiah. ID = UUIDv4 client-side.
- Soft delete (`deleted_at`). TDD untuk logika murni. Commit conventional.
- Spec: docs/superpowers/specs/. Plan: docs/superpowers/plans/.
- Kredensial hanya via .env / --dart-define; jangan commit. Data asli Excel: ref/ (migrasi nanti).
