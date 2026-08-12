# S&I Finance Solution — Overhaul Brand & Fitur (Design Spec)

Tanggal: 2026-08-12
Status: Disetujui user (mandat penuh, tanpa review gate — "langsung ke implementation plan")

## 1. Ringkasan

Overhaul total SandiApp menjadi produk berbrand **S&I Finance Solution** (S = Sandi,
I = Ika) — tampilan setara aplikasi fintech/bank digital modern plus fitur bisnis yang
tidak bisa dilakukan Excel. Tujuan: kejutan untuk pemilik bisnis; app harus terlihat
bagus, fungsional, dan sangat mudah dipakai.

**Di luar scope (ditegaskan user):**
- Migrasi Excel → session terpisah nanti (data Excel rumit, butuh sesi khusus).
- Client app untuk customer → tetap placeholder seperti spec MVP (§8 spec 2026-08-08).
- Tidak ada perubahan schema database.

## 2. Keputusan yang Dikonfirmasi User

| Pertanyaan | Keputusan |
|---|---|
| Momen wow | Kombinasi: brand + tampilan fintech + fitur yang Excel tidak bisa |
| Timeline | Santai — kualitas maksimal diutamakan |
| Brand | **S&I Finance Solution** (kejutan; tidak bisa tanya pemilik bisnis) |
| Mockup web | Tidak perlu — hasil web mockup beda feel dengan APK; bangun langsung di Flutter |
| Migrasi Excel | Ditunda, session terpisah |
| Pendekatan | B: Showpiece + Business Upgrade |

## 3. Identitas Brand

| Aspek | Desain |
|---|---|
| Nama tampil | **S&I Finance Solution** (splash, login, PDF header) |
| App label | "S&I Finance" (launcher Android, judul tab web) |
| Tagline | *"Kelola Kredit, Tanpa Ribet"* |
| Logo | Monogram **S&I**: rounded square dengan gradient emas, huruf "S&I" charcoal di dalamnya. Digambar via `CustomPainter` (vector, tajam di semua ukuran) sebagai widget `BrandLogo`. PNG untuk launcher icon & native splash di-generate sekali dari painter yang sama (render offscreen → asset), lalu diproses `flutter_launcher_icons` + `flutter_native_splash` |
| Warna | Fondasi charcoal + emas + Inter dari spec 2026-08-11 **dipertahankan**; yang dinaikkan adalah eksekusi: gradient halus, depth, hierarki tipografi lebih berani, motion halus |

Token tambahan di `theme.dart`:
- `brandGoldGradient` = `LinearGradient(#F5B942 → #D89B2B)` (logo, aksen hero)
- `heroGradient` = gradient subtle surface → surfaceVariant (kartu hero dashboard)

## 4. Format Rupiah Kompak

Fungsi murni baru `formatRupiahCompact(int rupiah)` di `lib/core/utils/money.dart`
(format penuh `formatRupiah` tetap dipakai di detail/form):

| Input | Output |
|---|---|
| 87.500.000 | `Rp 87,5 jt` |
| 1.250.000 | `Rp 1,25 jt` (desimal maks 2, trailing zero dibuang) |
| 850.000 | `Rp 850 rb` |
| 5.000.000.000 | `Rp 5 M` |
| 75.000 | `Rp 75.000` (di bawah 100 rb → format penuh) |

Pembulatan: 2 desimal dibulatkan (round-half-up), trailing zero dibuang
(87.590.000 → `Rp 87,59 jt`; 87.500.000 → `Rp 87,5 jt`).
Dipakai untuk angka besar di dashboard & stat cards. TDD.

## 5. Overhaul Visual per Area

### 5.1 Splash & icon
- Native splash statis (via `flutter_native_splash`): logo S&I di atas charcoal.
- Animasi brand (fade + scale-in ~600ms) ada di **logo halaman login** — bukan
  layar splash terpisah (YAGNI: native splash → login sudah membawa brand moment).
- Launcher icon dari PNG logo (foreground emas, background charcoal).

### 5.2 Login
- Full brand moment: logo besar, nama "S&I Finance Solution", tagline, gradient
  background charcoal → surface. Form tetap sederhana (email + password).

### 5.3 Dashboard (rombak terbesar)
1. **Greeting** — "Halo, <nama admin>" + tanggal hari ini.
2. **Hero card piutang** — gradient hero, dekorasi lingkaran samar, label
   "TOTAL PIUTANG AKTIF", angka `formatRupiahCompact` display besar dengan
   animasi angka saat berubah, subtext "dari X customer aktif".
3. **Row 2 stat card** — "Masuk Bulan Ini" (hijau) dan **"Macet >90 hari"**
   (merah: Rp + jumlah customer) — dari logika F1.
4. **Tren 6 bulan** — area chart (`fl_chart` LineChart) pembayaran masuk per bulan.
5. **Aksi Cepat** — 3 tombol pill outline emas (sudah ada, dipoles).
6. **Aktivitas Terakhir** — 8 pembayaran terbaru lintas customer (avatar inisial,
   nama, nominal, tanggal relatif "2 hari lalu").
7. **Hutang Terbesar** — 5 customer, avatar + sisa hutang + **dot warna status
   kolektibilitas** (F1).

### 5.4 Daftar customer
- Search bar tetap; tambah **filter chip**: Semua / Berhutang / Macet / Lunas / Arsip.
- Sort: Nama A–Z / Hutang terbesar / Terakhir bayar.
- List tile: avatar inisial, nama, sisa hutang + dot kolektibilitas, chip LUNAS hijau.

### 5.5 Detail customer
- Header avatar + nama + **badge "Customer Setia"** (≥3 transaksi, F3).
- 3 stat card (Total Belanja / Total Bayar / Sisa Hutang) — sudah ada, dipoles.
- **Section Customer 360°** (F3): customer sejak, jumlah transaksi, rata-rata
  cicilan, kecepatan lunas.
- Tombol aksi baru: **"Ingatkan via WA"** (F2) dan **"Bagikan Kartu Piutang"** (F4).
- Section Barang (status FIFO) & Pembayaran tetap, polish spacing.

### 5.6 Lainnya
- **Micro-interaction halus**: angka hero beranimasi (TweenAnimationBuilder), list
  masuk staggered fade-in ringan, transisi halaman lembut. Pure Flutter, tanpa
  package animasi.
- **Empty state**: ikon besar emas + copy membantu + tombol aksi (per halaman).
- **Spacing grid 8pt** konsisten; section header seragam (labelSmall uppercase,
  onSurfaceVariant).
- Settings: tambah entri **Template Pesan WA** (F2) dan **Kunci PIN** (F7, stretch).

## 6. Fitur Baru

### F1 — Kolektibilitas (Aging Piutang)
Logika murni `lib/core/logic/collectibility.dart`, TDD penuh.

```dart
enum Collectibility { lancar, perhatian, kurangLancar, macet }

// Hanya dipanggil untuk customer dengan sisa hutang > 0.
// Tanggal acuan = pembayaran terakhir; jika belum pernah bayar → tanggal
// pembelian pertama. today disuntik agar deterministik untuk test.
Collectibility collectibilityOf({
  required DateTime? lastPayment,
  required DateTime? firstPurchase,
  required DateTime today,
});
```

| Hari sejak tanggal acuan | Status | Warna |
|---|---|---|
| ≤ 30 | Lancar | hijau tertiary |
| 31–60 | Perhatian | kuning/amber |
| 61–90 | Kurang Lancar | oranye |
| > 90 | Macet | merah error |

Terpakai di: kartu "Macet >90 hari" dashboard, dot status di list customer,
filter chip "Macet".

### F2 — Reminder WhatsApp
- `lib/core/utils/whatsapp.dart` (murni, TDD):
  - `normalizePhoneId(String raw)` → digits only; awalan `0` → `62`; awalan
    `+62`/`62` diterima; hasil null jika tidak valid.
  - `buildWaReminderUri({phone, message})` → `https://wa.me/<phone>?text=<encoded>`.
  - `renderWaTemplate(template, {nama, sisaHutang, bisnis})` — placeholder
    `{nama}`, `{sisa_hutang}`, `{bisnis}`. Nilai `{bisnis}` = konstanta brand
    "S&I Finance Solution" (bukan setting).
- Template default (editable di Settings, `shared_preferences` key `wa_template`):

  > Assalamu'alaikum {nama}, ini pengingat dari {bisnis}. Sisa pembayaran kredit
  > Anda saat ini {sisa_hutang}. Terima kasih atas kerja samanya.

- UI: tombol "Ingatkan via WA" di detail customer & list macet →
  `launchUrl(mode: LaunchMode.externalApplication)`. Jika `no_hp` kosong/tidak
  valid → tombol **disabled** dengan tooltip "Nomor HP belum diisi". Jika
  `launchUrl` gagal/return false → snackbar "Tidak bisa membuka WhatsApp".
- Package: `url_launcher`.

### F3 — Customer 360°
Logika murni `lib/core/logic/customer_stats.dart`, TDD penuh.

```dart
class CustomerStats {
  final int jumlahTransaksi;
  final int totalBelanja;
  final int totalBayar;
  final int? rataRataCicilan;     // null jika belum ada pembayaran
  final int? kecepatanLunasHari;  // rata-rata hari beli→lunas utk barang LUNAS; null jika belum ada
  final DateTime? customerSejak;  // tanggal pembelian pertama
  final bool customerSetia;       // jumlahTransaksi >= 3
}
CustomerStats customerStatsOf(List<Purchase>, List<Payment>, FifoResult, ...);
```

### F4 — Kartu Piutang PDF
- `lib/features/statement/statement_pdf.dart` — build dokumen A4 via package `pdf`:
  header brand (logo PNG + "S&I Finance Solution"), info customer, ringkasan
  (total belanja / bayar / sisa), tabel barang + status FIFO, tabel pembayaran,
  footer tanggal cetak + tagline. Font PDF default (Helvetica) — Inter tidak
  di-embed (YAGNI).
- Perakitan data dipisah: `StatementData buildStatementData(customer, purchases,
  payments, fifo)` — murni & testable; rendering PDF menerima `StatementData`.
- Share via `Printing.sharePdf` (package `printing`) — Android: share sheet
  (langsung ke WA); web: download/print.
- Tombol "Bagikan Kartu Piutang" di detail customer.

### F5 — Dashboard insights
Termasuk di §5.3. Butuh query pembayaran lintas customer → **tambah method
repository** `recentPayments({int limit = 8})` dan agregasi pembayaran per bulan
(6 bulan terakhir) di interface `AppRepository` + kedua backend (drift & Supabase).
Detail signature difinalkan di implementation plan.

### F6 — Filter & sort daftar customer
State lokal halaman; kombinasi filter chip + sort; semua derived dari data yang
sudah ada + F1.

### F7 — Kunci PIN (stretch, opsional)
- Toggle di Settings, **default OFF**. PIN 4 digit, disimpan sebagai hash SHA-256
  (package `crypto`) di `shared_preferences`.
- Jika aktif: lock screen (logo + numpad PIN) tampil saat app start sebelum konten.
- Dikerjakan **terakhir**, hanya jika F1–F6 + visual selesai. Boleh dipotong tanpa
  mengganggu sisanya.

## 7. Arsitektur & Teknis

- **Tanpa perubahan schema drift/Supabase.** Semua fitur = data turunan (derived)
  atau preferensi lokal (`shared_preferences`: `wa_template`, PIN).
- Logika murni baru di `lib/core/logic/` + `lib/core/utils/` → TDD penuh,
  tanpa dependensi Flutter.
- Package baru:
  - runtime: `url_launcher`, `pdf`, `printing`, `crypto` (F7)
  - dev: `flutter_launcher_icons`, `flutter_native_splash`
- Repository: penambahan method baca (F5) di interface + `DriftBackend` +
  `RemoteBackend`. Tidak ada method write baru.
- Brand assets: `assets/brand/` (logo PNG untuk icon/splash/PDF). Widget
  `BrandLogo` (CustomPainter) untuk penggunaan in-app.
- Tidak menyentuh: logika FIFO/running balance, sync engine, auth, arsitektur
  repository, placeholder client app.

## 8. Error Handling

- WA gagal dibuka (tidak ada WA/browser): snackbar "Tidak bisa membuka WhatsApp".
- `no_hp` kosong/tidak valid: tombol WA disabled + penjelasan.
- PDF gagal generate/share: snackbar error, tidak crash.
- PIN salah: indikator goyang + counter; tidak ada lockout (demo app).
- Semua pesan Bahasa Indonesia.

## 9. Testing

- **Unit (TDD):** `collectibilityOf` (semua boundary 30/60/90, belum pernah bayar),
  `customerStatsOf` (termasuk edge: tanpa pembayaran, tanpa barang lunas),
  `formatRupiahCompact` (semua cabang), `normalizePhoneId`/`buildWaReminderUri`/
  `renderWaTemplate`, `buildStatementData`.
- **Widget:** dashboard merender section baru dengan data fake; filter chip
  customer; tombol WA disabled saat no_hp kosong.
- **Regresi:** semua test existing hijau; `flutter analyze` bersih.
- **Manual:** build APK (icon, splash, label benar), share PDF ke WA di device,
  web build tetap jalan.

## 10. Kriteria Sukses

- Kesan pertama (splash → login → dashboard) terasa seperti produk fintech beneran.
- Semua fitur F1–F6 berfungsi di Android & web (WA/PDF menyesuaikan platform).
- Tidak ada regresi fungsional; analyze bersih; test hijau.
- Brand S&I konsisten di icon, splash, login, dashboard, dan PDF.
