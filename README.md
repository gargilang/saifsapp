# S&I Finance Solution

Aplikasi admin catatan kredit/piutang barang & jasa. Flutter: Android (offline-first, drift SQLite + sync) & web (online-only langsung Supabase). Backend: Supabase.

**Live:** https://saifs.vercel.app

## Fitur

- Manajemen nasabah (dulu: customer)
- Transaksi kredit/pinjaman/investasi/jasa/modal usaha dengan cicilan
- Pembayaran cicilan per nasabah
- Dashboard piutang aktif, tren bulanan, top hutang
- Kartu piutang PDF per nasabah
- Anggaran belanja bulanan
- Kelola admin (tambah/hapus akun admin)
- Template pesan WhatsApp
- Kunci PIN opsional
- Mode gelap

## Perintah

| Perintah | Keterangan |
|---|---|
| `flutter test` | Jalankan test |
| `flutter analyze` | Analisis static |
| `bash scripts/run_android.sh` | Run Android (dart-define dari .env) |
| `bash scripts/run_web.sh` | Run web lokal |
| `bash scripts/build_apk.sh` | Build APK release |
| `bash scripts/build_web.sh` | Build web release |
| `dart run build_runner build --delete-conflicting-outputs` | Codegen drift |
| `npx supabase db push` | Push migration SQL ke Supabase cloud |
| `npx supabase functions deploy <nama>` | Deploy Edge Function ke Supabase |
| `uv run --with openpyxl,requests scripts/migrate_data.py` | Migrasi data dari Excel ke Supabase |

## Struktur

```
lib/
  core/           # utils tanggal, uang, PIN lock, WA template
  data/
    local/        # drift SQLite (Android offline-first)
    remote/       # Supabase REST (web online-only)
    sync/         # sync engine (push dirty rows → pull delta)
    models/       # Customer, Purchase, Payment, BudgetEntry
    repositories/ # Backend interface + implementasi
  features/
    dashboard/    # Beranda
    customers/    # Nasabah
    purchases/    # Transaksi
    payments/     # Pembayaran
    budget/       # Anggaran
    reports/      # Laporan
    statement/    # Kartu piutang PDF
    settings/     # Pengaturan + Kelola Admin
supabase/
  migrations/     # SQL migration (0001–0004)
  functions/      # Edge Functions (admin-users)
ref/              # Data asli Excel (tidak di-deploy)
scripts/          # Build & run scripts
```

## Deploy

- **Web:** push ke `master` → Vercel auto-deploy dari `build/web` (sudah di-commit sebagai static release)
- **Supabase migration:** `npx supabase db push`
- **Edge Function:** `npx supabase functions deploy admin-users`
- **APK:** `bash scripts/build_apk.sh` → output di `build/app/outputs/flutter-apk/`

## Kredensial

Hanya via `.env` (tidak di-commit). Lihat `.env` untuk nilai aktual.

## Migrasi Data

Data asli dari `ref/DAFTAR KREDIT BARANG r1.xlsx` sudah dimigrasi:
- 58 nasabah, 249 transaksi, 1069 pembayaran
- Script: `scripts/migrate_data.py`
