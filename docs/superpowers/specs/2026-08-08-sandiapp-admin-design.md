# SandiApp — Aplikasi Admin Kredit Barang (Design Spec)

Tanggal: 2026-08-08
Status: Disetujui user (mandat penuh, tanpa review gate)
Sumber data asli: `ref/DAFTAR KREDIT BARANG r1.xlsx` (migrasi dilakukan belakangan, setelah app stabil)

## 1. Ringkasan

Aplikasi admin untuk bisnis jual barang secara kredit dengan model **hutang berjalan
(running balance)**, menggantikan pencatatan Excel. Satu codebase **Flutter** dengan
dua target:

- **Android (APK)** — offline-first penuh; semua baca/tulis ke SQLite lokal, sync ke
  Supabase di background. Dipakai di lapangan dengan sinyal jelek.
- **Web (mobile web)** — online-only, langsung ke Supabase. Untuk admin yang tidak
  memakai Android. Trade-off ini disetujui user.

Backend: **Supabase** (Postgres + Auth). Tidak ada target iOS, sekarang maupun nanti.

## 2. Keputusan yang Dikonfirmasi User

| Pertanyaan | Keputusan |
|---|---|
| Struktur app | Prioritas aplikasi **admin** dulu; client app (untuk customer) fase berikutnya |
| Native Kotlin vs Flutter | **Flutter** — satu codebase untuk Android + web |
| Model hutang | **Running balance + FIFO** (bukan cicilan per barang) |
| Offline | **Android offline-first**, web online-only |
| Migrasi Excel | Nanti, setelah app jalan bagus. **Semua** data Excel akan dimigrasikan. Schema harus siap |
| Scope tambahan MVP | Laporan keuntungan, Anggaran belanja bulanan, Multi-admin dengan login |
| Lainnya | Tambahkan fitur user-friendly menurut penilaian terbaik; sediakan placeholder untuk client app masa depan |

Handoff AI sebelumnya (Kotlin dual-app, persona istri/ibu-ibu) **bukan** sumber
kebenaran dan tidak diikuti.

## 3. Model Bisnis: Running Balance + FIFO

- **Total hutang customer** = SUM(harga_jual semua pembelian aktif)
- **Total bayar** = SUM(semua pembayaran aktif)
- **Sisa hutang** = total hutang − total bayar
- Pembayaran **tidak** diikat ke barang tertentu; nominal bebas, tanggal bebas.
- **Status per barang (derived, dihitung, tidak disimpan):** pembayaran dialokasikan
  secara FIFO ke barang tertua dulu. Per barang:
  - `LUNAS` — ter-cover penuh oleh alokasi
  - `SEBAGIAN` — ter-cover sebagian (tampilkan sisa per item)
  - `BELUM` — belum ter-cover sama sekali
- Contoh: beli 5.000.000 + 300.000 + 1.200.000 (total 6.500.000). Sudah bayar
  5.300.000 → barang 1 LUNAS, barang 2 LUNAS, barang 3 BELUM (sisa 1.200.000).

## 4. Arsitektur

### 4.1 Tech stack

| Komponen | Pilihan | Alasan |
|---|---|---|
| Framework | Flutter 3.44.2 / Dart 3.12.2 (sudah terinstall) | 1 codebase → Android + web |
| State management | Riverpod (`flutter_riverpod`) | Compile-safe, testable, reactive |
| DB lokal (Android) | **drift** (SQLite) | Type-safe DAO, reactive streams, cocok untuk offline-first |
| Backend | `supabase_flutter` (Auth + PostgREST) | Sudah diminta user |
| Routing | `go_router` | Standar, mendukung deep link web |
| Konektivitas | `connectivity_plus` | Trigger sync saat online kembali |
| Background sync (Android) | `workmanager` | Sync periodik saat ada jaringan |
| Grafik laporan | `fl_chart` | Bar chart keuntungan |
| Format | `intl` | Rupiah & tanggal id-ID |
| ID | UUIDv4 dibuat di client | Insert offline aman tanpa server |

### 4.2 Struktur kode (feature-first + repository pattern)

```
lib/
  main.dart                 # bootstrap: pilih backend (kIsWeb), init Supabase & drift
  app.dart                  # MaterialApp, router, theme
  core/                     # theme, router, utils (currency, date), constants
  data/
    local/                  # drift database, DAO (Android only)
    remote/                 # Supabase API wrappers
    sync/                   # sync engine (push/pull), connectivity listener
    repositories/           # interface + 2 implementasi (lihat 4.3)
  features/
    auth/                   # login
    dashboard/
    customers/              # list + detail
    purchases/              # tambah/edit barang kredit
    payments/               # tambah/edit pembayaran
    reports/                # laporan keuntungan
    budget/                 # anggaran belanja bulanan
    settings/               # profil, status sync, logout
  widgets/                  # design system: MoneyInputField, EmptyState,
                          # ConfirmDialog, SyncStatusBadge, OfflineBanner
```

### 4.3 Dua backend, satu interface repository

Setiap repository (`CustomerRepository`, `PurchaseRepository`, `PaymentRepository`,
`BudgetRepository`) punya dua implementasi, dipilih saat bootstrap via `kIsWeb`:

- **`DriftRepository` (Android):** semua read dari drift (single source of truth
  lokal). Semua write → drift dengan flag sync, lalu trigger sync (debounced).
  UI reactive via drift streams → Riverpod.
- **`SupabaseRepository` (web):** read/write langsung Supabase. Tanpa drift,
  tanpa sync engine. Status sync selalu "online".

Interface repository identik, jadi UI/feature code tidak tahu bedanya.

### 4.4 Alur data

- **Android:** UI ↔ Riverpod ↔ DriftRepository ↔ drift (SQLite) ⇄ SyncEngine ⇄ Supabase
- **Web:** UI ↔ Riverpod ↔ SupabaseRepository ↔ Supabase

## 5. Model Data (Supabase Postgres)

Semua tabel bisnis (`customers`, `purchases`, `payments`, `budget_entries`):
`id uuid pk` (UUIDv4 client-side), `created_at timestamptz`,
`updated_at timestamptz`, `deleted_at timestamptz null` (soft delete, wajib untuk
sync), `created_by uuid references profiles`.

```sql
-- profiles: 1:1 dengan auth.users; row dibuat otomatis via trigger AFTER INSERT
-- pada auth.users (display_name default dari email, bisa diedit). Tanpa created_by.
profiles (
  id uuid pk references auth.users,
  display_name text not null,
  role text not null default 'admin',       -- 'admin' aktif; 'customer' DICADANGKAN untuk client app
  created_at timestamptz
)

customers (
  id, nama text not null, no_hp text null, alamat text null, catatan text null,
  is_archived boolean not null default false,
  auth_user_id uuid null,                   -- PLACEHOLDER client app: link ke akun customer
  created_by, created_at, updated_at, deleted_at
)

purchases (
  id, customer_id uuid not null references customers,
  nama_barang text not null,
  harga_jual bigint not null,               -- rupiah, integer
  harga_beli bigint null,                   -- null = tidak dihitung di laporan keuntungan
  tanggal_beli date not null,
  catatan text null,
  created_by, created_at, updated_at, deleted_at
)

payments (
  id, customer_id uuid not null references customers,
  jumlah bigint not null,
  tanggal_bayar date not null,
  metode text not null default 'tunai',     -- 'tunai' | 'transfer' | 'lainnya'
  catatan text null,
  sumber text not null default 'admin',     -- PLACEHOLDER client app: 'client'
  status_verifikasi text not null default 'verified',  -- PLACEHOLDER: 'pending'|'verified'|'rejected'
  bukti_foto_url text null,                 -- PLACEHOLDER client app: Supabase Storage
  created_by, created_at, updated_at, deleted_at
)

budget_entries (                            -- anggaran belanja bulanan (Sheet3)
  id, tanggal date not null,
  nama_transaksi text not null,
  tipe text not null,                       -- 'pemasukan' | 'pengeluaran'
  jumlah bigint not null,
  catatan text null,
  created_by, created_at, updated_at, deleted_at
)
```

Aturan turunan:

- **Saldo anggaran** tidak disimpan — dihitung running berurut `(tanggal, created_at)`.
- **Keuntungan** = `harga_jual − harga_beli` per purchase, direkap per periode
  berdasarkan `tanggal_beli` (konsisten dengan Sheet2 Excel; booked saat beli,
  bukan saat lunas). Purchase dengan `harga_beli null` dikecualikan dari rekap.
- Semua query mengabaikan `deleted_at is not null`.
- `updated_at` diset client saat write lokal, dan diset trigger Postgres saat
  write langsung ke server (dari web). Wajib untuk last-write-wins.

## 6. Sync Engine (Android, offline-first)

Model: **row-level dirty flags + last-write-wins**, bukan outbox terpisah.

- Setiap row lokal punya `is_dirty` (perlu push) dan `synced_at`.
- **Push:** semua row `is_dirty` di-upsert ke Supabase (termasuk soft delete →
  kirim `deleted_at`). Sukses → clear flag.
- **Pull:** per tabel, `select * where updated_at > last_pulled_at` → upsert ke
  lokal. Urutan selalu **push dulu, baru pull**, sehingga konflik jarang: jika row
  yang sama berubah di dua tempat, penulis terakhir menang (LWW by `updated_at`).
  Diketahui & diterima sebagai trade-off MVP (jumlah admin kecil).
- **Trigger sync:** saat app start, saat konektivitas pulih (`connectivity_plus`),
  setelah write lokal (debounce 5 detik), pull-to-refresh manual, dan periodik
  via `workmanager` (~15 menit, hanya saat online).
- **Indikator UI:** badge status sync (tersinkron / N pending / offline) +
  offline banner. Angka pending = jumlah row `is_dirty`.
- Web: sync engine tidak aktif; `SupabaseRepository` langsung remote.

## 7. Fitur MVP

### 7.1 Auth (multi-admin)
- Login email + password (Supabase Auth). Satu workspace bisnis bersama: semua
  admin melihat & mengedit data yang sama.
- Pembuatan akun admin baru via dashboard Supabase (tidak ada manajemen user
  in-app di MVP — YAGNI).
- Atribusi `created_by` pada setiap record.

### 7.2 Dashboard
- Ringkasan: total piutang berjalan, pembayaran masuk bulan ini, jumlah customer
  dengan hutang aktif.
- Daftar 5 customer dengan sisa hutang terbesar (shortcut ke detail).
- Shortcut aksi: tambah pembayaran, tambah customer, tambah barang.

### 7.3 Customers
- List dengan search nama, sort (nama / sisa hutang terbesar), badge sisa hutang
  per customer, filter arsip.
- Detail customer: ringkasan (total belanja, total bayar, **sisa hutang** besar
  dan jelas), daftar barang dengan status FIFO (LUNAS/SEBAGIAN/BELUM + sisa per
  item), riwayat pembayaran (tanggal, nominal, metode).
- Aksi: tambah barang, tambah pembayaran, edit, arsipkan.

### 7.4 Purchases & Payments
- Form tambah/edit: `MoneyInputField` dengan format Rupiah otomatis, date picker
  default hari ini, validasi Bahasa Indonesia.
- Payment: nominal bebas (tidak diikat barang), pilihan nominal cepat
  (50rb/100rb/200rb/500rb), metode tunai/transfer/lainnya.
- Hapus = soft delete dengan dialog konfirmasi + snackbar.

### 7.5 Laporan keuntungan
- Rekap per bulan & per tahun: total penjualan, total modal, keuntungan,
  jumlah barang. Bar chart `fl_chart` + tabel. Purchase tanpa `harga_beli`
  ditandai/dikecualikan.

### 7.6 Anggaran belanja bulanan
- List entri per bulan dengan **saldo berjalan** dihitung on-the-fly.
- Tambah pemasukan/pengeluaran. Edit/hapus (soft delete).

### 7.7 Settings
- Profil admin, tema (light/dark mengikuti sistem), status sync (terakhir sync,
  jumlah pending, tombol "Sync sekarang"), logout.

### 7.8 Fitur user-friendly lintas modul
- Format Rupiah otomatis di semua input & tampilan uang.
- Empty state yang membantu (teks + tombol aksi) di semua list.
- Pull-to-refresh di list utama.
- Konfirmasi untuk aksi destruktif.
- Loading & error state konsisten; pesan error Bahasa Indonesia.

## 8. Placeholder untuk Client App (Fase Berikutnya)

Disiapkan di schema/arsitektur, **tidak** dibangun UI-nya di MVP:

1. `profiles.role = 'customer'` — nilai dicadangkan.
2. `customers.auth_user_id` — link akun customer ke record customer.
3. `payments.sumber`, `payments.status_verifikasi`, `payments.bukti_foto_url` —
   alur "customer upload bukti → admin verifikasi" tinggal mengaktifkan nilai
   `pending`/`client`.
4. RLS: policy customer ditulis sebagai **SQL ter-comment** di file migrasi
   (customer hanya bisa SELECT data miliknya, INSERT payment miliknya).
5. Storage bucket `bukti-bayar` dibuat di migrasi (private), belum dipakai UI.
6. Notifikasi realtime/push (Edge Function + FCM) — didokumentasikan sebagai
   pekerjaan fase client, tidak diimplementasikan.

## 9. Keamanan (RLS)

- RLS **aktif** di semua tabel.
- MVP: policy tunggal per tabel — admin (terbukti via `profiles.role = 'admin'`
  milik `auth.uid()`) boleh `select/insert/update/delete` semua row.
- Policy customer untuk masa depan ada sebagai SQL ter-comment (lihat §8.4).
- Tidak ada data sensitif di client selain milik workspace sendiri; kredensial
  Supabase (URL + anon key) lewat `--dart-define`, tidak di-commit.

## 10. Error Handling

- Offline: semua write Android tetap sukses lokal; UI menunjukkan badge pending.
  Tidak ada error ke user hanya karena offline.
- Kegagalan sync (network/server): retry dengan backoff pada trigger berikutnya;
  error tercatat di status sync, tidak memblokir pemakaian.
- Konflik RLS/auth (token kedaluwarsa): refresh session otomatis
  (`supabase_flutter`); jika gagal → kembali ke login.
- Validasi form di client (nominal > 0, tanggal tidak kosong, dst).
- Web tanpa koneksi: tampilkan pesan offline yang jelas (web memang online-only).

## 11. Testing

- **Unit test (prioritas, TDD):** kalkulasi running balance & status FIFO per
  barang, saldo anggaran berjalan, rekap keuntungan, mapping sync
  (dirty/push/pull, LWW).
- **Widget test:** form pembayaran (format Rupiah & validasi), list customer.
- **Manual test:** alur offline di AVD (airplane mode → input → online → sync),
  build web via `web-server`.

## 12. Kesiapan Migrasi Excel (bukan scope MVP)

Schema sudah menampung migrasi penuh nanti:

- Setiap baris Sheet1 → 1 `customer` (dedup by nama) + 1 `purchase`
  (`harga_beli`, `harga_jual`, `tanggal_beli`).
- Setiap pasangan kolom cicilan → 1 `payment` (`tanggal_bayar`, `jumlah`).
- Tanggal Excel tidak konsisten (string `30/12/2020`, datetime, bahkan tanggal
  mustahil seperti cicilan sebelum tanggal beli) → importer menormalisasi &
  melaporkan anomali, tidak diam-diam mengubah.
- Sheet2 tidak diimpor (derived dari data). Sheet3 → `budget_entries`.

## 13. Tahapan

1. **MVP admin app** (spec ini): auth, customers, purchases, payments, FIFO,
   dashboard, laporan keuntungan, anggaran belanja, offline sync Android, web
   online.
2. **Migrasi Excel** setelah app stabil.
3. **Client app** (customer): login customer, transparansi hutang, upload bukti
   bayar, verifikasi admin, notifikasi — memakai placeholder di §8.
