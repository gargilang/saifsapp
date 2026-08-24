# Migrasi Data r2 dan Sumber Dana (Design Spec)

Tanggal: 2026-08-24
Status: Desain disetujui di chat, menunggu review spec
Sumber data:

- `ref/DAFTAR KREDIT BARANG r2.xlsx`
- `ref/PREVIEW_MIGRASI.xlsx`
- Supabase production yang saat ini berisi hasil migrasi r1

## 1. Ringkasan

Perubahan ini mempunyai dua tujuan yang dikerjakan sebagai satu cutover:

1. Mengganti data migrasi r1 dengan data r2 yang sudah dirapikan klien dan
   dinormalisasi kembali menjadi preview migrasi yang dapat diaudit.
2. Menambahkan pencatatan kepemilikan piutang berdasarkan sumber dana Sandi dan
   Ika, termasuk pembelian baru, pembayaran nasabah, koreksi, dan alih modal
   ketika Ika membayar kembali modal yang dipinjamkan Sandi.

Data bisnis lama akan dihapus dan diimpor ulang setelah preview final lolos
validasi. Akun Supabase Auth dan tabel `profiles` tidak dihapus.

## 2. Fakta Data dan Keputusan Cutover

Audit pada 2026-08-24 menghasilkan:

| Metrik | Migrasi lama | r2 |
|---|---:|---:|
| Transaksi | 249 | 249 |
| Pembayaran | 1.069 | 1.069 |
| Total harga beli | Rp877.769.000 | Rp877.769.000 |
| Total harga jual | Rp971.417.500 | Rp971.417.500 |
| Total pembayaran | Rp854.692.500 | Rp854.692.500 |
| Total piutang | Rp116.725.000 | Rp116.725.000 |
| Nasabah unik | 58 | 46 |

Supabase masih sama dengan hasil migrasi lama: 58 nasabah aktif, 249 transaksi,
1.069 pembayaran, tanpa transaksi operasional baru. Tidak ada nasabah yang
terhubung ke akun Auth dan tidak ada data anggaran aktif. Terdapat satu row
nasabah soft-delete bernama Suparman yang tidak dibawa ke dataset baru.

Keputusan:

- Buat `PREVIEW_MIGRASI_R2.xlsx` sebagai satu-satunya sumber impor baru.
- Setelah preview disetujui, backup data production lalu hapus data bisnis.
- Pertahankan `auth.users` dan `profiles`.
- Impor ulang nasabah, transaksi, pembayaran, saldo awal sumber dana, dan
  ledger pembuka dalam satu proses terkontrol.
- Perangkat Android yang pernah tersinkron wajib mereset database lokal sebelum
  kembali melakukan sync agar UUID lama tidak muncul kembali.

## 3. Normalisasi Workbook r2

### 3.1 Sheet preview final

`PREVIEW_MIGRASI_R2.xlsx` berisi:

1. `TRANSAKSI`: nomor sumber, tanggal, nasabah final, jenis, item final, harga
   beli, harga jual, total pembayaran, sisa, dan status.
2. `CUSTOMER`: daftar 46 nasabah final beserta nama mentah yang digabung atau
   dipisahkan.
3. `CICILAN`: seluruh 1.069 pembayaran dengan tanggal dan nominal final.
4. `SALDO_SUMBER_DANA`: saldo pembuka Sandi dan Ika serta total kontrol.
5. `VALIDASI`: hasil pemeriksaan otomatis dan daftar cell yang dikoreksi.

Sheet `SALDO_SUMBER_DANA` mempunyai nilai pembuka:

| Sumber | Saldo awal |
|---|---:|
| Sandi | Rp36.100.000 |
| Ika | Rp80.625.000 |
| Total kontrol | Rp116.725.000 |

Saldo awal merupakan pembagian kepemilikan atas piutang aktif pada saat cutover,
bukan saldo kas dan bukan atribusi yang dibuat-buat untuk setiap transaksi lama.

### 3.2 Tanggal

Klien mengetik tanggal dengan maksud format Indonesia `dd/mm/yyyy`. Excel dapat
menyimpan tanggal ambigu sebagai interpretasi US `mm/dd/yyyy`. Normalisasi harus
memakai konteks urutan bisnis, bukan menerima serial Excel secara buta:

- Tanggal order dan cicilan dibaca sebagai maksud `dd/mm/yyyy`.
- Nilai dengan hari dan bulan sama-sama `<= 12` diperiksa terhadap urutan order
  dan cicilan.
- Tanggal pembayaran sebelum order akibat pembalikan hari/bulan dikoreksi ke
  interpretasi Indonesia.
- Tanggal setelah tanggal cutover dikoreksi bila merupakan pembalikan yang
  jelas, termasuk 9 Juni dan 11 Juni yang tersimpan sebagai 6 September dan
  6 November.
- Tanggal yang tetap tidak mungkin setelah normalisasi dimasukkan ke sheet
  `VALIDASI` dan menghentikan impor sampai dikoreksi.
- Importer tidak boleh memakai tanggal fallback seperti 1 Januari untuk cell
  kosong atau tidak valid.

### 3.3 Item dan jenis

Perbaikan item yang telah disetujui:

| No. | Item final |
|---:|---|
| 10 | AC Mobil |
| 46 | Pinjaman |
| 78 | Freezer |
| 89 | Spare Part Mobil |
| 145 | Lain-lain |
| 146 | Lain-lain |
| 245 | Shockbreaker |

Kolom `jenis` tidak tersedia di r2. Nilainya dipertahankan dari preview lama dan
harus termasuk salah satu dari `barang`, `pinjaman`, `investasi`, `jasa/servis`,
atau `modal usaha`.

### 3.4 Validasi wajib sebelum impor

Importer berhenti tanpa menulis ke Supabase apabila salah satu kondisi berikut
tidak terpenuhi:

- Tepat 249 transaksi dan 1.069 pembayaran.
- Nomor transaksi unik dan berurutan 1 sampai 249.
- Tidak ada nama nasabah, item final, jenis, tanggal, atau nominal wajib yang
  kosong.
- Harga dan pembayaran merupakan integer rupiah positif sesuai aturan tabel.
- Tidak ada tanggal hasil fallback atau tahun yang tidak masuk akal.
- Tidak ada pembayaran sebelum order setelah koreksi, kecuali pengecualian yang
  dicatat eksplisit di sheet `VALIDASI`.
- Total harga beli Rp877.769.000.
- Total harga jual Rp971.417.500.
- Total pembayaran Rp854.692.500.
- Total piutang Rp116.725.000.
- Saldo awal Sandi ditambah Ika sama dengan total piutang.

## 4. Makna Sumber Dana

Sumber dana menyatakan pemilik ekonomis dari piutang aktif. Invariant bisnis:

```text
saldo sumber dana Sandi + saldo sumber dana Ika = total piutang aktif
```

Konsekuensinya:

- Pembelian kredit menambah piutang dan saldo sumber dana pemiliknya.
- Pembayaran nasabah mengurangi piutang dan saldo sumber dana pemiliknya dengan
  nominal yang sama.
- Alih modal dari Sandi ke Ika mengurangi saldo Sandi dan menambah saldo Ika
  dengan nominal sama, sehingga total piutang tidak berubah.
- Koreksi saldo wajib memiliki alasan dan pasangan perubahan yang menjaga total
  tetap sama dengan piutang, kecuali koreksi tersebut juga memperbaiki data
  transaksi atau pembayaran pada operasi yang sama.
- Riwayat tidak diubah secara diam-diam. Setiap perubahan disimpan sebagai row
  ledger yang dapat dilihat kembali.

## 5. Model Data

### 5.1 `fund_sources`

```text
fund_sources (
  id uuid primary key,
  nama text not null unique,
  color_key text not null,
  is_active boolean not null default true,
  created_by uuid references profiles,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz null
)
```

Seed awal:

- `Sandi`, `color_key = green`
- `Ika`, `color_key = gold`

Warna adalah metadata presentasi terbatas. Identitas sumber selalu ditampilkan
sebagai teks dan tidak bergantung pada warna saja.

### 5.2 `fund_ledger_entries`

```text
fund_ledger_entries (
  id uuid primary key,
  fund_source_id uuid not null references fund_sources,
  tanggal date not null,
  tipe text not null,
  jumlah_delta bigint not null check (jumlah_delta <> 0),
  reference_type text not null,
  reference_id uuid null,
  transfer_group_id uuid null,
  catatan text null,
  created_by uuid references profiles,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz null
)
```

Nilai `tipe`:

- `saldo_awal`: saldo pembuka saat cutover.
- `transaksi`: penambahan piutang dari transaksi baru.
- `pembayaran`: pengurangan akibat pembayaran nasabah.
- `alih_masuk` dan `alih_keluar`: pasangan alih kepemilikan.
- `penyesuaian`: koreksi dengan alasan wajib.

`reference_type` mengidentifikasi `migration`, `purchase`, `payment`, `transfer`,
atau `adjustment`. Row otomatis dari transaksi/pembayaran menggunakan pasangan
`reference_type + reference_id` yang unik agar penyimpanan ulang bersifat
idempotent dan edit tidak menggandakan saldo.

Saldo sumber dana dihitung dari jumlah seluruh `jumlah_delta` aktif dan tidak
disimpan sebagai angka mutable di `fund_sources`.

### 5.3 Atribusi transaksi dan pembayaran

Transaksi dan pembayaran yang dibuat setelah cutover menyimpan sumber dana yang
dipilih. Versi awal mendukung satu sumber per transaksi/pembayaran. Nominal ledger
transaksi sama dengan `harga_jual`, karena yang dibagi adalah kepemilikan piutang,
bukan biaya pembelian. Nominal ledger pembayaran sama dengan `jumlah` pembayaran.

Data transaksi lama tidak diberi sumber dana secara retroaktif karena klien hanya
memberikan angka agregat. Dua row `saldo_awal` mewakili seluruh piutang lama.
Untuk pembayaran terhadap piutang lama, admin memilih Sandi atau Ika sebagai
sumber yang dikurangi. Untuk transaksi baru, form pembayaran dapat memilih
default dari sumber transaksi yang sedang ditutup oleh FIFO, tetapi pilihan tetap
ditampilkan dan dapat dikoreksi sebelum disimpan.

Penyimpanan transaksi atau pembayaran beserta ledger terkait harus atomik di
Supabase. Pada Android offline, kedua row ditulis dalam satu transaksi Drift dan
disinkronkan secara idempotent.

## 6. Alur Pengguna

### 6.1 Halaman Anggaran

Bagian atas halaman Anggaran menampilkan ringkasan sumber dana sebelum daftar
saldo bulanan:

- Total piutang aktif.
- Saldo Sandi dengan label dan aksen hijau.
- Saldo Ika dengan label dan aksen emas yang memakai warna brand.
- Indikator konsistensi bila jumlah sumber tidak sama dengan total piutang.

Ringkasan tetap ringkas dan dapat dipindai. Warna tidak menjadi satu-satunya
penanda. Tidak ada kartu bersarang.

Aksi pada bagian sumber dana:

- `Alih Modal`: memilih sumber asal, sumber tujuan, nominal, tanggal, dan catatan.
- `Penyesuaian`: mengubah pembagian kepemilikan dengan alasan wajib dan pasangan
  delta yang menjaga total.
- `Riwayat`: melihat saldo awal, transaksi, pembayaran, alih modal, dan koreksi.

Contoh Ika membayar kembali modal Sandi sebesar Rp1.000.000:

```text
Sandi  -Rp1.000.000 (alih_keluar)
Ika    +Rp1.000.000 (alih_masuk)
Total  tidak berubah
```

### 6.2 Form Transaksi

Form tambah transaksi baru menambahkan segmented control `Sumber dana` dengan
pilihan Sandi dan Ika. Pilihan wajib diisi. Nominal atribusi ditampilkan sebagai
harga jual dan tidak perlu diketik ulang pada versi awal.

Form edit menampilkan sumber saat ini. Mengganti sumber membuat pasangan koreksi
ledger secara atomik tanpa menghapus riwayat audit.

Transaksi hasil migrasi ditandai sebagai bagian dari saldo awal dan tidak
menampilkan atribusi per transaksi yang palsu.

### 6.3 Form Pembayaran

Form pembayaran menambahkan segmented control `Mengurangi dana` dengan pilihan
Sandi dan Ika. Untuk transaksi baru, pilihan awal berasal dari sumber transaksi
FIFO yang sedang dibayar. Untuk saldo lama atau kondisi ambigu, admin memilihnya.

Validasi mencegah saldo sumber menjadi negatif dan memastikan delta ledger sama
dengan nominal pembayaran. Bila satu pembayaran perlu mengurangi dua sumber,
admin mencatatnya sebagai dua pembayaran pada versi awal. Dukungan split dalam
satu pembayaran ditunda sampai ada kebutuhan nyata.

## 7. Offline-first dan Sinkronisasi

Drift menambahkan tabel lokal untuk `fund_sources` dan `fund_ledger_entries`, serta
kolom sumber pada model transaksi dan pembayaran yang diperlukan untuk input.
Keduanya mengikuti pola yang sama dengan tabel bisnis lain:

- UUIDv4 dibuat client-side.
- `created_at`, `updated_at`, `deleted_at`, dan `is_dirty` tersedia.
- Push dirty rows sebelum pull.
- Pull dipaginasi dan memakai watermark `updated_at`.
- Soft delete disinkronkan.

Urutan sync menjaga referensi:

1. `fund_sources`
2. `customers`
3. `purchases` dan `payments`
4. `fund_ledger_entries`
5. `budget_entries`

Ledger otomatis memakai ID deterministik atau unique constraint referensi agar
retry sync tidak membuat entry ganda. Konflik alih modal dan penyesuaian mengikuti
LWW per row, tetapi setiap operasi membuat row baru sehingga histori tidak hilang.

## 8. Reset dan Migrasi Production

Urutan cutover:

1. Hentikan sementara input admin dan sync Android.
2. Buat backup JSON/CSV penuh untuk semua tabel bisnis.
3. Generate `PREVIEW_MIGRASI_R2.xlsx` dan jalankan semua validasi.
4. Minta persetujuan angka dan mapping nasabah.
5. Deploy migrasi schema dan versi aplikasi yang memahami sumber dana.
6. Hapus data bisnis dengan urutan dependensi: ledger sumber dana,
   `budget_entries`, `payments`, `purchases`, `customers`, lalu `fund_sources`.
7. Jangan menghapus `auth.users` atau `profiles`.
8. Impor 46 nasabah, 249 transaksi, 1.069 pembayaran, dua sumber dana, dan dua
   ledger saldo awal.
9. Regenerasi data Anggaran otomatis bila diperlukan dari transaksi/pembayaran.
10. Jalankan rekonsiliasi dan baru buka kembali input admin.
11. Reset database lokal pada setiap perangkat Android lama, login, lalu lakukan
    full sync dari server baru.

Script migrasi harus memiliki mode `--dry-run` sebagai default dan memerlukan flag
eksplisit untuk menulis. Reset dan impor berjalan di dalam transaksi database atau
melalui RPC server-side sehingga kegagalan tidak meninggalkan dataset separuh jadi.

## 9. Rekonsiliasi Pasca-migrasi

Cutover dinyatakan berhasil hanya bila:

- 46 nasabah aktif, 249 transaksi, dan 1.069 pembayaran tersedia.
- Total harga beli, harga jual, pembayaran, dan piutang sama dengan nilai kontrol.
- Tidak ada orphan foreign key atau row dengan tanggal/jenis/item wajib kosong.
- Sandi Rp36.100.000 dan Ika Rp80.625.000.
- Total sumber dana Rp116.725.000 sama dengan total piutang aktif.
- Anggaran dan dashboard menampilkan total yang konsisten.
- Web dapat membuat transaksi, pembayaran, alih modal, dan penyesuaian.
- Android dapat melakukan operasi yang sama saat offline lalu sync tanpa duplikasi.
- Edit dan retry sync tidak menggandakan ledger.
- Warna Sandi dan Ika benar pada tema terang dan gelap, dengan label teks tetap
  terbaca dan tidak saling tumpang tindih pada viewport ponsel.

## 10. Pengujian

### Logika murni

- Saldo sumber dari ledger bertanda positif dan negatif.
- Invariant jumlah sumber sama dengan piutang.
- Alih modal menghasilkan dua delta berlawanan dan total nol.
- Penyesuaian ditolak bila tidak seimbang atau tanpa alasan.
- Pembayaran tidak boleh membuat sumber negatif.
- Pemilihan default sumber pembayaran berdasarkan FIFO transaksi baru.

### Repository dan database

- Simpan/edit/hapus transaksi membuat ledger idempotent.
- Simpan/edit/hapus pembayaran membuat ledger idempotent.
- Operasi transaksi dan ledger atomik pada Supabase dan Drift.
- Migrasi Drift mempertahankan data lokal yang masih relevan.
- Sync retry, pagination, soft delete, dan watermark mencakup tabel baru.

### UI

- Ringkasan sumber dana, status konsistensi, riwayat, alih modal, dan penyesuaian.
- Form transaksi dan pembayaran mewajibkan sumber.
- Label serta warna Sandi/Ika benar pada tema terang dan gelap.
- Layout tidak overflow pada ponsel dan web.

### Migrasi data

- Generator preview bersifat deterministik.
- Dry-run tidak menulis Supabase.
- Validasi gagal pada jumlah row, total, tanggal, item, atau jenis yang salah.
- Reseed dapat dihentikan tanpa meninggalkan data parsial.
- Rekonsiliasi production menghasilkan seluruh nilai kontrol di bagian 9.

## 11. Di Luar Scope

- Mengarang sumber dana per transaksi lama.
- Lebih dari dua sumber dana aktif pada cutover pertama.
- Membagi satu transaksi atau pembayaran baru ke dua sumber dalam satu form.
- Akuntansi kas, rekening bank, pembagian laba, bunga pinjaman Sandi ke Ika, atau
  jurnal akuntansi double-entry penuh.
- Mengubah model running balance dan FIFO piutang nasabah.
