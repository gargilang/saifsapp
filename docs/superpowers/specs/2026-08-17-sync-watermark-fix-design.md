# Fix Sync Watermark + Full Resync

Tanggal: 2026-08-17

## Masalah

Data yang diinput lewat web (Vercel) tidak muncul di APK Android meski app terhubung
ke Supabase (login valid, sync `completed` tanpa error).

### Root cause (terbukti eksperimental)

`SyncEngine._pull` menyimpan watermark `last_pull_<table>` dari `DateTime.now()` klien
saat sync dimulai, bukan dari `updated_at` server baris yang benar-benar ditarik.

```dart
final since = await state.lastPull(table);
final started = DateTime.now().toUtc();          // BUG: jam klien
final rows = await remote.fetchSince(table, since);
await apply(rows);
await state.setLastPull(table, started);          // simpan jam klien
```

Filter pull = `updated_at > since`. Karena watermark maju ke `now()` tiap sync, baris
server yang `updated_at`-nya lebih kecil dari watermark (mis. ditulis dari web di antara
dua sync Android) terlewat **permanen**.

Bukti: purchase "AC Gree" (`updated_at 2026-08-17T02:41Z`) tidak tertarik karena
watermark Android = `2026-08-17T04:22Z`. Setelah watermark direset ke null,
`Fetched 251 rows` dan "AC Gree" masuk ke DB lokal.

Soft-delete propagation & konflik multi-admin sudah diperiksa: aman untuk 3 admin
(soft-delete update `updated_at` sehingga ikut ter-pull; konflik LWW acceptable karena
push-dulu-baru-pull). Tidak di-scope sekarang (YAGNI).

## Solusi

### A. Watermark = max(updated_at) baris yang ditarik

`_pull` menyimpan watermark dari `updated_at` server maksimum di antara baris hasil pull,
bukan jam klien. Jika tidak ada baris, watermark tidak dimajukan. Kebal clock skew dan
gap waktu antar-sync.

Untuk mencegah baris tepat di batas hilang, filter tetap `>` (strict) dan watermark
disimpan tepat = max(updated_at). Baris dengan `updated_at == watermark` akan ter-skip di
pull berikutnya (sudah tersimpan lokal, jadi aman). Kalau ada baris baru dengan
`updated_at` sama persis (tabrakan milidetik) — sangat jarang; full resync jadi jaring
pengaman.

### B. Full resync (jaring pengaman)

`SyncEngine.resyncAll()`: kosongkan semua watermark `last_pull_*` lalu `syncAll()`.
Diekspos ke UI via tombol "Sinkronkan Ulang Penuh" di Pengaturan.

`SyncStateStore.clearAll(tables)`: hapus key `last_pull_<table>`.

## Test (TDD)

1. Pull menarik baris yang `updated_at` < now klien tapi > watermark lama (regresi bug).
2. Watermark tersimpan = max(updated_at) baris yang ditarik (bukan now).
3. Pull tanpa baris tidak memajukan watermark.
4. `resyncAll` menarik ulang semua baris meski watermark sudah maju.
5. `SyncStateStore.clearAll` menghapus watermark.

## Di luar scope

- Conflict resolution per-field multi-admin (LWW timestamp granular).
- Perubahan RLS / auth.
