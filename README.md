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
| `uv run --with openpyxl,requests python scripts/reseed_data.py` | Dry-run lokal target migrasi r2 |

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
  migrations/     # SQL migration backend
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

## Migrasi Data r2

Dataset r2 yang sudah dinormalisasi mempunyai kontrol berikut:

- 46 nasabah, 249 transaksi, dan 1.069 pembayaran
- harga beli Rp877.769.000 dan harga jual Rp971.417.500
- pembayaran Rp854.692.500 dan piutang berjalan Rp116.725.000
- saldo awal Sandi Rp36.100.000 dan Ika Rp80.625.000

Generate ulang preview formula-free, lalu verifikasi hasilnya:

```bash
uv run --with openpyxl python scripts/prepare_migration_r2.py
uv run --with openpyxl python scripts/prepare_migration_r2.py --verify-only
```

Dry-run lokal adalah mode default. Perintah ini hanya membangun payload dan mencetak
nilai kontrol, tanpa membuat koneksi atau perubahan ke Supabase:

```bash
uv run --with openpyxl,requests python scripts/reseed_data.py \
  --preview ref/PREVIEW_MIGRASI_R2.xlsx
```

Setelah migration SQL `0005` dan `0006` sudah diterapkan, pemeriksaan remote berikut
hanya membaca seluruh tabel bisnis secara paginated. Sebelum cutover, hasil remote
memang masih dapat berbeda dari target preview.

```bash
uv run --with openpyxl,requests python scripts/reseed_data.py \
  --preview ref/PREVIEW_MIGRASI_R2.xlsx --remote-check
```

Apply production harus mendapat persetujuan eksplisit. Script mewajibkan frasa persis,
membuat backup seluruh row termasuk soft-delete ke `backups/reseed-<UTC timestamp>/`,
baru memanggil satu RPC transaksional dan menjalankan rekonsiliasi ulang:

```bash
uv run --with openpyxl,requests python scripts/reseed_data.py \
  --preview ref/PREVIEW_MIGRASI_R2.xlsx \
  --apply --confirm-reset RESET-BUSINESS-DATA
```

RPC hanya mengosongkan dan mengisi ulang `fund_ledger_entries`, `budget_entries`,
`payments`, `purchases`, `customers`, dan `fund_sources`. Data Supabase Auth serta
`profiles` tidak pernah dihapus. Kredensial wajib berasal dari `.env` atau environment
variable `SUPABASE_URL` dan `SUPABASE_SERVICE_ROLE_KEY`.

Setelah reseed berhasil, perangkat Android yang pernah melakukan sync harus direset
dalam urutan ini: hapus data aplikasi atau reinstall, login kembali, lalu jalankan full
sync. Jangan membuka aplikasi Android lama di antara reseed dan reset karena database
offline-nya masih memuat dataset sebelum cutover.
