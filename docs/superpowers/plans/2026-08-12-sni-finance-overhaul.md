# S&I Finance Solution — Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Overhaul SandiApp menjadi produk berbrand "S&I Finance Solution" — visual
setara fintech modern + fitur bisnis (kolektibilitas, reminder WA, customer 360°,
kartu piutang PDF) yang tidak bisa dilakukan Excel. Tanpa migrasi data, tanpa
perubahan schema, tanpa menyentuh client-app placeholder.

**Architecture:** Semua fitur baru berupa logika murni (`lib/core/logic/`,
`lib/core/utils/`) dikonsumsi oleh `AppRepository` (satu-satunya pintu data untuk
UI), lalu ditampilkan lewat widget baru/ubahan. Tidak ada perubahan `Backend`
interface — `Backend` sudah membaca seluruh data aktif per tabel, semua agregasi
baru dihitung di `AppRepository` (pola yang sudah dipakai `dashboardStats`).

**Tech Stack:** Flutter/Dart existing (Riverpod, go_router, fl_chart, drift,
supabase_flutter) + paket baru: `url_launcher`, `pdf`, `printing`, `crypto` (Task 14);
dev-only: `flutter_launcher_icons`, `flutter_native_splash`.

## Global Constraints

- Teks UI Bahasa Indonesia. Uang = `int` rupiah (integer, tanpa desimal).
- **Tidak ada perubahan schema drift/Supabase.** Semua fitur baru = data turunan
  atau preferensi lokal (`shared_preferences`).
- Logika murni baru di `lib/core/logic/` & `lib/core/utils/` — **TDD penuh**
  (test ditulis & gagal dulu, sebelum implementasi).
- Setiap task: `flutter analyze` bersih & **semua test lulus** (existing + baru)
  sebelum commit.
- Commit conventional (`feat:`, `fix:`, `style:`, `test:`, `docs:`), dalam Bahasa
  Indonesia mengikuti gaya commit log project.
- Tidak menyentuh: logika FIFO/running balance (`fifo.dart`), sync engine, arsitektur
  repository, model data Supabase, placeholder client app, `budget`/`reports` pages
  (sudah didesain di spec 2026-08-11).
- Brand: `kBrandName` = "S&I Finance Solution", `kBrandShortName` = "S&I Finance",
  `kBrandTagline` = "Kelola Kredit, Tanpa Ribet".
- Referensi desain: `docs/superpowers/specs/2026-08-12-sni-finance-overhaul-design.md`.

## Pre-flight (sebelum Task 1)

Working tree punya perubahan **belum di-commit** di `lib/features/dashboard/dashboard_page.dart`
(hasil `dart format` / editor). Task 8 akan menulis ulang file ini secara total,
jadi bersihkan dulu riwayatnya agar diff Task 8 bersih:

```bash
git diff lib/features/dashboard/dashboard_page.dart   # review — pastikan hanya format
git add lib/features/dashboard/dashboard_page.dart
git commit -m "style: rapikan format dashboard_page.dart"
```

Jika ternyata ada perubahan logika (bukan cuma format), commit dengan pesan yang
sesuai isinya, lalu lanjut ke Task 1.

---

### Task 1: Util tampilan — formatRupiahCompact & relativeDay

**Files:**
- Modify: `lib/core/utils/money.dart`
- Modify: `lib/core/utils/dates.dart`
- Test: `test/core/utils/money_compact_test.dart` (baru)
- Test: `test/core/utils/dates_test.dart` (baru)

**Interfaces:**
- Produces: `String formatRupiahCompact(int value)`, `String relativeDay(DateTime d, DateTime today)`

- [ ] **Step 1: Tulis test gagal — formatRupiahCompact**

`test/core/utils/money_compact_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/core/utils/money.dart';

void main() {
  group('formatRupiahCompact', () {
    test('di bawah 100 rb -> format penuh', () {
      expect(formatRupiahCompact(0), 'Rp 0');
      expect(formatRupiahCompact(75000), 'Rp 75.000');
      expect(formatRupiahCompact(99999), 'Rp 99.999');
    });

    test('rentang ratusan ribu -> rb', () {
      expect(formatRupiahCompact(100000), 'Rp 100 rb');
      expect(formatRupiahCompact(850000), 'Rp 850 rb');
    });

    test('rentang jutaan -> jt, maks 2 desimal, trailing zero dibuang', () {
      expect(formatRupiahCompact(1000000), 'Rp 1 jt');
      expect(formatRupiahCompact(1250000), 'Rp 1,25 jt');
      expect(formatRupiahCompact(87500000), 'Rp 87,5 jt');
      expect(formatRupiahCompact(87590000), 'Rp 87,59 jt');
    });

    test('rentang miliar -> M', () {
      expect(formatRupiahCompact(5000000000), 'Rp 5 M');
      expect(formatRupiahCompact(1250000000), 'Rp 1,25 M');
    });

    test('negatif tetap terformat dengan tanda minus di depan', () {
      expect(formatRupiahCompact(-1250000), '-Rp 1,25 jt');
    });
  });
}
```

- [ ] **Step 2: Jalankan test, pastikan gagal**

Run: `flutter test test/core/utils/money_compact_test.dart`
Expected: FAIL — `formatRupiahCompact` tidak terdefinisi.

- [ ] **Step 3: Implementasi**

Tambahkan ke `lib/core/utils/money.dart` (setelah `parseRupiah`):
```dart
/// 87500000 -> 'Rp 87,5 jt' · 850000 -> 'Rp 850 rb' · 5000000000 -> 'Rp 5 M'.
/// Di bawah 100 rb -> format penuh [formatRupiah]. Maks 2 desimal, trailing zero dibuang.
String formatRupiahCompact(int value) {
  final sign = value < 0 ? '-' : '';
  final abs = value.abs();
  String trim(double v) {
    var s = v.toStringAsFixed(2);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '');
      if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    }
    return s.replaceAll('.', ',');
  }
  if (abs >= 1000000000) return '${sign}Rp ${trim(abs / 1000000000)} M';
  if (abs >= 1000000) return '${sign}Rp ${trim(abs / 1000000)} jt';
  if (abs >= 100000) return '${sign}Rp ${trim(abs / 1000)} rb';
  return formatRupiah(value);
}
```

- [ ] **Step 4: Jalankan test, pastikan lulus**

Run: `flutter test test/core/utils/money_compact_test.dart`
Expected: PASS (semua)

- [ ] **Step 5: Tulis test gagal — relativeDay**

`test/core/utils/dates_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sandiapp/core/utils/dates.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  final today = DateTime(2026, 8, 12);

  group('relativeDay', () {
    test('hari ini', () => expect(relativeDay(DateTime(2026, 8, 12), today), 'Hari ini'));
    test('kemarin', () => expect(relativeDay(DateTime(2026, 8, 11), today), 'Kemarin'));
    test('beberapa hari lalu (< 7 hari)',
        () => expect(relativeDay(DateTime(2026, 8, 7), today), '5 hari lalu'));
    test('>= 7 hari -> tanggal penuh',
        () => expect(relativeDay(DateTime(2026, 8, 5), today), '5 Agu 2026'));
    test('tanggal masa depan -> Hari ini (fallback aman)',
        () => expect(relativeDay(DateTime(2026, 8, 20), today), 'Hari ini'));
  });
}
```

- [ ] **Step 6: Jalankan test, pastikan gagal**

Run: `flutter test test/core/utils/dates_test.dart`
Expected: FAIL — `relativeDay` tidak terdefinisi.

- [ ] **Step 7: Implementasi**

Tambahkan ke `lib/core/utils/dates.dart` (setelah `tampilTanggal`):
```dart
/// 'Hari ini' / 'Kemarin' / 'N hari lalu' (< 7 hari) / fallback [tampilTanggal].
String relativeDay(DateTime d, DateTime today) {
  final days = DateTime(today.year, today.month, today.day)
      .difference(DateTime(d.year, d.month, d.day))
      .inDays;
  if (days <= 0) return 'Hari ini';
  if (days == 1) return 'Kemarin';
  if (days < 7) return '$days hari lalu';
  return tampilTanggal(d);
}
```

- [ ] **Step 8: Jalankan semua test util, pastikan lulus**

Run: `flutter test test/core/utils/`
Expected: PASS (semua)

- [ ] **Step 9: Commit**

```bash
git add lib/core/utils/money.dart lib/core/utils/dates.dart \
        test/core/utils/money_compact_test.dart test/core/utils/dates_test.dart
git commit -m "feat(utils): formatRupiahCompact + relativeDay"
```

---

### Task 2: Logika kolektibilitas (aging piutang)

**Files:**
- Create: `lib/core/logic/collectibility.dart`
- Test: `test/core/logic/collectibility_test.dart`

**Interfaces:**
- Produces: `enum Collectibility { lancar, perhatian, kurangLancar, macet }`,
  `Collectibility collectibilityOf({required DateTime? lastPayment, required DateTime? firstPurchase, required DateTime today})`,
  `String collectibilityLabel(Collectibility c)`
- Consumed oleh: Task 5 (repository), Task 8/9/10 (UI)

- [ ] **Step 1: Tulis test gagal**

`test/core/logic/collectibility_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/core/logic/collectibility.dart';

void main() {
  final today = DateTime(2026, 8, 12);

  group('collectibilityOf — berdasar lastPayment', () {
    test('tepat 30 hari -> lancar', () => expect(
        collectibilityOf(lastPayment: DateTime(2026, 7, 13), firstPurchase: null, today: today),
        Collectibility.lancar));
    test('31 hari -> perhatian', () => expect(
        collectibilityOf(lastPayment: DateTime(2026, 7, 12), firstPurchase: null, today: today),
        Collectibility.perhatian));
    test('60 hari -> perhatian', () => expect(
        collectibilityOf(lastPayment: DateTime(2026, 6, 13), firstPurchase: null, today: today),
        Collectibility.perhatian));
    test('61 hari -> kurang lancar', () => expect(
        collectibilityOf(lastPayment: DateTime(2026, 6, 12), firstPurchase: null, today: today),
        Collectibility.kurangLancar));
    test('90 hari -> kurang lancar', () => expect(
        collectibilityOf(lastPayment: DateTime(2026, 5, 14), firstPurchase: null, today: today),
        Collectibility.kurangLancar));
    test('91 hari -> macet', () => expect(
        collectibilityOf(lastPayment: DateTime(2026, 5, 13), firstPurchase: null, today: today),
        Collectibility.macet));
  });

  test('belum pernah bayar -> pakai firstPurchase', () {
    expect(
        collectibilityOf(lastPayment: null, firstPurchase: DateTime(2026, 5, 1), today: today),
        Collectibility.macet); // > 90 hari sejak beli, belum bayar
    expect(
        collectibilityOf(lastPayment: null, firstPurchase: DateTime(2026, 8, 1), today: today),
        Collectibility.lancar);
  });

  test('tanpa jejak tanggal sama sekali -> macet (anomali)', () {
    expect(collectibilityOf(lastPayment: null, firstPurchase: null, today: today),
        Collectibility.macet);
  });

  test('collectibilityLabel', () {
    expect(collectibilityLabel(Collectibility.lancar), 'Lancar');
    expect(collectibilityLabel(Collectibility.perhatian), 'Dalam Perhatian');
    expect(collectibilityLabel(Collectibility.kurangLancar), 'Kurang Lancar');
    expect(collectibilityLabel(Collectibility.macet), 'Macet');
  });
}
```

- [ ] **Step 2: Jalankan test, pastikan gagal**

Run: `flutter test test/core/logic/collectibility_test.dart`
Expected: FAIL — file `lib/core/logic/collectibility.dart` belum ada.

- [ ] **Step 3: Implementasi**

`lib/core/logic/collectibility.dart`:
```dart
/// Status kolektibilitas piutang (aging), dihitung dari hari sejak transaksi
/// terakhir. Hanya relevan untuk customer dengan sisa hutang > 0.
enum Collectibility { lancar, perhatian, kurangLancar, macet }

/// Tanggal acuan = pembayaran terakhir; jika belum pernah bayar -> pembelian
/// pertama. [today] disuntik supaya deterministik untuk test.
Collectibility collectibilityOf({
  required DateTime? lastPayment,
  required DateTime? firstPurchase,
  required DateTime today,
}) {
  final ref = lastPayment ?? firstPurchase;
  if (ref == null) return Collectibility.macet; // anomali: berhutang tanpa jejak tanggal
  final days = DateTime(today.year, today.month, today.day)
      .difference(DateTime(ref.year, ref.month, ref.day))
      .inDays;
  if (days <= 30) return Collectibility.lancar;
  if (days <= 60) return Collectibility.perhatian;
  if (days <= 90) return Collectibility.kurangLancar;
  return Collectibility.macet;
}

String collectibilityLabel(Collectibility c) => switch (c) {
      Collectibility.lancar => 'Lancar',
      Collectibility.perhatian => 'Dalam Perhatian',
      Collectibility.kurangLancar => 'Kurang Lancar',
      Collectibility.macet => 'Macet',
    };
```

- [ ] **Step 4: Jalankan test, pastikan lulus**

Run: `flutter test test/core/logic/collectibility_test.dart`
Expected: PASS (semua)

- [ ] **Step 5: Commit**

```bash
git add lib/core/logic/collectibility.dart test/core/logic/collectibility_test.dart
git commit -m "feat(logic): kolektibilitas (aging piutang)"
```

---

### Task 3: Logika customer stats (Customer 360°)

**Files:**
- Create: `lib/core/logic/customer_stats.dart`
- Test: `test/core/logic/customer_stats_test.dart`

**Interfaces:**
- Consumes: `Purchase` (`lib/data/models/purchase.dart`), `Payment` (`lib/data/models/payment.dart`)
- Produces: `class CustomerStats { jumlahTransaksi, totalBelanja, totalBayar, rataRataCicilan (int?), kecepatanLunasHari (int?), customerSejak (DateTime?), customerSetia (bool) }`,
  `CustomerStats customerStatsOf(List<Purchase> purchases, List<Payment> payments)`
- Consumed oleh: Task 5 (`CustomerDetailData.stats`)

- [ ] **Step 1: Tulis test gagal**

`test/core/logic/customer_stats_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/core/logic/customer_stats.dart';
import 'package:sandiapp/data/models/payment.dart';
import 'package:sandiapp/data/models/purchase.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1);
  Purchase p(String id, int harga, DateTime beli) => Purchase(
      id: id, customerId: 'c1', namaBarang: id, hargaJual: harga,
      tanggalBeli: beli, createdAt: t0, updatedAt: t0);
  Payment pm(String id, int jumlah, DateTime tgl, {String status = 'verified'}) => Payment(
      id: id, customerId: 'c1', jumlah: jumlah, tanggalBayar: tgl,
      statusVerifikasi: status, createdAt: t0, updatedAt: t0);

  test('tanpa data -> semua null/0, tidak setia', () {
    final s = customerStatsOf([], []);
    expect(s.jumlahTransaksi, 0);
    expect(s.totalBelanja, 0);
    expect(s.totalBayar, 0);
    expect(s.rataRataCicilan, isNull);
    expect(s.kecepatanLunasHari, isNull);
    expect(s.customerSejak, isNull);
    expect(s.customerSetia, isFalse);
  });

  test('>= 3 transaksi -> customerSetia true', () {
    final s = customerStatsOf(
        [p('p1', 100, DateTime(2026, 1, 1)), p('p2', 100, DateTime(2026, 2, 1)),
         p('p3', 100, DateTime(2026, 3, 1))], []);
    expect(s.customerSetia, isTrue);
    expect(s.customerSejak, DateTime(2026, 1, 1));
  });

  test('rataRataCicilan hanya dari payment verified', () {
    final s = customerStatsOf([p('p1', 1000000, DateTime(2026, 1, 1))], [
      pm('m1', 500000, DateTime(2026, 1, 10)),
      pm('m2', 300000, DateTime(2026, 1, 20)),
      pm('m3', 999999, DateTime(2026, 1, 25), status: 'pending'), // diabaikan
    ]);
    expect(s.totalBayar, 800000);
    expect(s.rataRataCicilan, 400000); // (500000+300000)/2
  });

  test('kecepatanLunasHari: rata-rata hari beli -> lunas per barang (FIFO)', () {
    final s = customerStatsOf(
      [p('p1', 1000000, DateTime(2026, 1, 1)), p('p2', 500000, DateTime(2026, 2, 1))],
      [
        pm('m1', 600000, DateTime(2026, 1, 11)),
        pm('m2', 400000, DateTime(2026, 1, 21)), // p1 lunas di 21 Jan -> 20 hari
        pm('m3', 500000, DateTime(2026, 2, 11)), // p2 lunas di 11 Feb -> 10 hari
      ],
    );
    expect(s.kecepatanLunasHari, 15); // (20+10)/2
  });

  test('barang belum lunas -> tidak dihitung ke kecepatanLunasHari', () {
    final s = customerStatsOf(
      [p('p1', 1000000, DateTime(2026, 1, 1)), p('p2', 500000, DateTime(2026, 2, 1))],
      [pm('m1', 1000000, DateTime(2026, 1, 11))], // hanya p1 lunas
    );
    expect(s.kecepatanLunasHari, 10);
  });
}
```

- [ ] **Step 2: Jalankan test, pastikan gagal**

Run: `flutter test test/core/logic/customer_stats_test.dart`
Expected: FAIL — file belum ada.

- [ ] **Step 3: Implementasi**

`lib/core/logic/customer_stats.dart`:
```dart
import '../../data/models/payment.dart';
import '../../data/models/purchase.dart';

class CustomerStats {
  final int jumlahTransaksi;
  final int totalBelanja;
  final int totalBayar;
  final int? rataRataCicilan;
  final int? kecepatanLunasHari;
  final DateTime? customerSejak;
  final bool customerSetia;
  const CustomerStats({
    required this.jumlahTransaksi,
    required this.totalBelanja,
    required this.totalBayar,
    required this.rataRataCicilan,
    required this.kecepatanLunasHari,
    required this.customerSejak,
    required this.customerSetia,
  });
}

/// Statistik "Customer 360" — murni dari purchases + payments satu customer.
CustomerStats customerStatsOf(List<Purchase> purchases, List<Payment> payments) {
  final verified = payments.where((p) => p.statusVerifikasi == 'verified').toList();
  final totalBayar = verified.fold<int>(0, (s, p) => s + p.jumlah);
  final totalBelanja = purchases.fold<int>(0, (s, p) => s + p.hargaJual);

  DateTime? sejak;
  for (final p in purchases) {
    if (sejak == null || p.tanggalBeli.isBefore(sejak)) sejak = p.tanggalBeli;
  }

  // Kecepatan lunas: untuk tiap barang (urut FIFO), hitung hari dari
  // tanggalBeli sampai kumulatif pembayaran mencapai kumulatif harga barang
  // tersebut. Hanya barang yang benar-benar lunas dihitung.
  int? kecepatan;
  if (purchases.isNotEmpty && verified.isNotEmpty) {
    final sortedP = [...purchases]..sort((a, b) {
        final c = a.tanggalBeli.compareTo(b.tanggalBeli);
        return c != 0 ? c : a.createdAt.compareTo(b.createdAt);
      });
    final sortedM = [...verified]..sort((a, b) => a.tanggalBayar.compareTo(b.tanggalBayar));

    final daysList = <int>[];
    var cumHarga = 0;
    var cumBayar = 0;
    var mi = 0;
    for (final p in sortedP) {
      cumHarga += p.hargaJual;
      while (mi < sortedM.length && cumBayar < cumHarga) {
        cumBayar += sortedM[mi].jumlah;
        mi++;
      }
      if (cumBayar >= cumHarga) {
        daysList.add(sortedM[mi - 1].tanggalBayar.difference(p.tanggalBeli).inDays);
      } else {
        break; // barang ini & sesudahnya belum lunas
      }
    }
    if (daysList.isNotEmpty) {
      kecepatan = (daysList.reduce((a, b) => a + b) / daysList.length).round();
    }
  }

  return CustomerStats(
    jumlahTransaksi: purchases.length,
    totalBelanja: totalBelanja,
    totalBayar: totalBayar,
    rataRataCicilan: verified.isEmpty ? null : (totalBayar / verified.length).round(),
    kecepatanLunasHari: kecepatan,
    customerSejak: sejak,
    customerSetia: purchases.length >= 3,
  );
}
```

- [ ] **Step 4: Jalankan test, pastikan lulus**

Run: `flutter test test/core/logic/customer_stats_test.dart`
Expected: PASS (semua)

- [ ] **Step 5: Commit**

```bash
git add lib/core/logic/customer_stats.dart test/core/logic/customer_stats_test.dart
git commit -m "feat(logic): customerStatsOf — statistik Customer 360"
```

---

### Task 4: Brand constants + WhatsApp utils + template provider

**Files:**
- Create: `lib/core/brand.dart`
- Create: `lib/core/utils/whatsapp.dart`
- Create: `lib/core/wa_template.dart`
- Test: `test/core/utils/whatsapp_test.dart`
- Test: `test/core/wa_template_test.dart`
- Modify: `pubspec.yaml` (tambah `url_launcher`)

**Interfaces:**
- Produces: `kBrandName`, `kBrandShortName`, `kBrandTagline`, `kDefaultWaTemplate`,
  `String? normalizePhoneId(String? raw)`, `Uri buildWaReminderUri({required String phone, required String message})`,
  `String renderWaTemplate(String template, {required String nama, required int sisaHutang})`,
  `waTemplateProvider` (`NotifierProvider<WaTemplateNotifier, String>`)
- Consumed oleh: Task 10 (tombol WA), Task 11 (editor Settings)

- [ ] **Step 1: Tambah dependency**

```bash
flutter pub add url_launcher
```

- [ ] **Step 2: Tulis test gagal — brand & whatsapp utils**

`test/core/utils/whatsapp_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/core/utils/whatsapp.dart';

void main() {
  group('normalizePhoneId', () {
    test('null/empty -> null', () {
      expect(normalizePhoneId(null), isNull);
      expect(normalizePhoneId(''), isNull);
      expect(normalizePhoneId('abc'), isNull);
    });
    test('awalan 0 -> diganti 62', () {
      expect(normalizePhoneId('0812-3456-7890'), '6281234567890');
    });
    test('awalan 8 tanpa 0 -> ditambah 62', () {
      expect(normalizePhoneId('81234567890'), '6281234567890');
    });
    test('sudah 62 atau +62 -> dirapikan', () {
      expect(normalizePhoneId('+62 812 3456 7890'), '6281234567890');
      expect(normalizePhoneId('6281234567890'), '6281234567890');
    });
    test('terlalu pendek -> null', () {
      expect(normalizePhoneId('0812'), isNull);
    });
  });

  test('buildWaReminderUri', () {
    final uri = buildWaReminderUri(phone: '6281234567890', message: 'Halo Dunia');
    expect(uri.toString(), 'https://wa.me/6281234567890?text=Halo%20Dunia');
  });

  test('renderWaTemplate mengganti semua placeholder', () {
    final msg = renderWaTemplate(
      "Halo {nama}, sisa {sisa_hutang} untuk {bisnis}.",
      nama: 'WIWIK',
      sisaHutang: 750000,
    );
    expect(msg, 'Halo WIWIK, sisa Rp 750.000 untuk S&I Finance Solution.');
  });
}
```

- [ ] **Step 3: Jalankan test, pastikan gagal**

Run: `flutter test test/core/utils/whatsapp_test.dart`
Expected: FAIL — file belum ada.

- [ ] **Step 4: Implementasi brand.dart & whatsapp.dart**

`lib/core/brand.dart`:
```dart
const kBrandName = 'S&I Finance Solution';
const kBrandShortName = 'S&I Finance';
const kBrandTagline = 'Kelola Kredit, Tanpa Ribet';
```

`lib/core/utils/whatsapp.dart`:
```dart
import '../brand.dart';
import 'money.dart';

const kDefaultWaTemplate =
    "Assalamu'alaikum {nama}, ini pengingat dari {bisnis}. "
    'Sisa pembayaran kredit Anda saat ini {sisa_hutang}. '
    'Terima kasih atas kerja samanya.';

/// Rapikan nomor HP Indonesia jadi format wa.me (62xxxxxxxxxx). null jika
/// tidak valid (kosong atau terlalu pendek/panjang).
String? normalizePhoneId(String? raw) {
  if (raw == null) return null;
  var d = raw.replaceAll(RegExp(r'\D'), '');
  if (d.isEmpty) return null;
  if (d.startsWith('0')) {
    d = '62${d.substring(1)}';
  } else if (d.startsWith('8')) {
    d = '62$d';
  }
  if (!d.startsWith('62')) return null;
  if (d.length < 10 || d.length > 15) return null;
  return d;
}

Uri buildWaReminderUri({required String phone, required String message}) =>
    Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');

/// Placeholder: {nama}, {sisa_hutang}, {bisnis}. {bisnis} selalu diisi [kBrandName].
String renderWaTemplate(String template, {required String nama, required int sisaHutang}) =>
    template
        .replaceAll('{nama}', nama)
        .replaceAll('{sisa_hutang}', formatRupiah(sisaHutang))
        .replaceAll('{bisnis}', kBrandName);
```

- [ ] **Step 5: Jalankan test, pastikan lulus**

Run: `flutter test test/core/utils/whatsapp_test.dart`
Expected: PASS (semua)

- [ ] **Step 6: Tulis test gagal — wa_template provider**

`test/core/wa_template_test.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandiapp/core/utils/whatsapp.dart';
import 'package:sandiapp/core/wa_template.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('default template, bisa diubah & dipersist', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(waTemplateProvider), kDefaultWaTemplate);

    await container.read(waTemplateProvider.notifier).setTemplate('Halo {nama}!');
    expect(container.read(waTemplateProvider), 'Halo {nama}!');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('wa_template'), 'Halo {nama}!');
  });

  test('reset mengembalikan ke default', () async {
    SharedPreferences.setMockInitialValues({'wa_template': 'Custom'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(waTemplateProvider), 'Custom');
    await container.read(waTemplateProvider.notifier).reset();
    expect(container.read(waTemplateProvider), kDefaultWaTemplate);
  });
}
```

- [ ] **Step 7: Jalankan test, pastikan gagal**

Run: `flutter test test/core/wa_template_test.dart`
Expected: FAIL — file `lib/core/wa_template.dart` belum ada.

- [ ] **Step 8: Implementasi**

`lib/core/wa_template.dart` (pola sama seperti `theme_mode.dart`):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'utils/whatsapp.dart';

class WaTemplateNotifier extends Notifier<String> {
  static const _key = 'wa_template';

  @override
  String build() {
    SharedPreferences.getInstance().then((p) {
      final v = p.getString(_key);
      if (v != null && v.trim().isNotEmpty) state = v;
    });
    return kDefaultWaTemplate;
  }

  Future<void> setTemplate(String v) async {
    state = v;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, v);
  }

  Future<void> reset() => setTemplate(kDefaultWaTemplate);
}

final waTemplateProvider = NotifierProvider<WaTemplateNotifier, String>(WaTemplateNotifier.new);
```

- [ ] **Step 9: Jalankan test, pastikan lulus**

Run: `flutter test test/core/wa_template_test.dart`
Expected: PASS (semua)

- [ ] **Step 10: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/brand.dart lib/core/utils/whatsapp.dart \
        lib/core/wa_template.dart test/core/utils/whatsapp_test.dart test/core/wa_template_test.dart
git commit -m "feat(utils): konstanta brand S&I + util WhatsApp reminder"
```

---

### Task 5: Repository — kolektibilitas, filter/sort, stats, dashboard extras

**Files:**
- Modify: `lib/data/models/customer.dart`
- Modify: `lib/data/repositories/app_repository.dart`
- Modify: `lib/app_providers.dart` (perbaikan minimal supaya tetap compile)
- Modify: `lib/features/customers/customers_page.dart` (perbaikan minimal call-site — UI penuh di Task 9)
- Modify: `test/data/repositories/app_repository_test.dart`

**Interfaces:**
- Consumes: `Collectibility`, `collectibilityOf` (Task 2), `CustomerStats`, `customerStatsOf` (Task 3)
- Produces: `enum CustomerFilter { semua, berhutang, macet, lunas, arsip }`,
  `enum CustomerSort { nama, hutang, terakhirBayar }`,
  `class MonthlyTotal { year, month, total }`,
  `class PaymentActivityItem { payment, customerName }`,
  `CustomerWithBalance` + field baru `lastPaymentAt (DateTime?)`, `collectibility (Collectibility?)`,
  `AppRepository.customers({String query, CustomerFilter filter, CustomerSort sort, DateTime? today})`
  (breaking change — `includeArchived`/`sortByHutang` **dihapus**),
  `DashboardStats` + field baru `macetTotal, macetCount, trend (List<MonthlyTotal>), aktivitas (List<PaymentActivityItem>)`,
  `CustomerDetailData` + field baru `stats (CustomerStats)`
- Consumed oleh: Task 8 (dashboard), Task 9 (customers page), Task 10 (customer detail)

- [ ] **Step 1: Tulis test gagal untuk perilaku baru**

Edit `test/data/repositories/app_repository_test.dart`. Ganti baris
`final sorted = await repo.customers(sortByHutang: true);` (di test
`'customers: saldo dihitung, search, sortByHutang'`) menjadi:
```dart
    final sorted = await repo.customers(sort: CustomerSort.hutang);
```
dan ganti nama test itu jadi `'customers: saldo dihitung, search, sort'`.

Tambahkan import di bagian atas file:
```dart
import 'package:sandiapp/core/logic/collectibility.dart';
```

Tambahkan test baru di akhir `main()` (sebelum kurung kurawal penutup):
```dart
  test('customers: kolektibilitas + filter macet/berhutang/lunas + sort terakhirBayar',
      () async {
    final t = DateTime(2026, 8, 12);
    final all = await repo.customers(today: t);
    final wiwik = all.singleWhere((e) => e.customer.id == 'c1');
    expect(wiwik.lastPaymentAt, DateTime(2026, 8, 5));
    expect(wiwik.collectibility, Collectibility.lancar); // 7 hari

    final anas = all.singleWhere((e) => e.customer.id == 'c3');
    expect(anas.collectibility, isNull); // tanpa pembelian -> tanpa hutang

    backend.customers.add(c('c4', 'BUDI'));
    backend.purchases.add(p('p9', 'c4', 1000000, DateTime(2026, 1, 1)));
    backend.payments.add(pm('m9', 'c4', 100000, DateTime(2026, 3, 1))); // 164 hari lalu

    final macet = await repo.customers(filter: CustomerFilter.macet, today: t);
    expect(macet.map((e) => e.customer.id), ['c4']);

    final berhutang = await repo.customers(filter: CustomerFilter.berhutang, today: t);
    expect(berhutang.map((e) => e.customer.id), containsAll(['c1', 'c2', 'c4']));

    final byLast = await repo.customers(sort: CustomerSort.terakhirBayar, today: t);
    expect(byLast.first.customer.id, 'c2'); // lastPaymentAt 8/6, paling baru
  });

  test('customerDetail: stats terisi dari customerStatsOf', () async {
    final d = await repo.customerDetail('c1');
    expect(d.stats.jumlahTransaksi, 2);
    expect(d.stats.totalBayar, 2500000);
  });

  test('dashboardStats: macet, tren 6 bulan, aktivitas terbaru', () async {
    final s = await repo.dashboardStats(now: DateTime(2026, 8, 12));
    expect(s.macetCount, 0); // m1/m2 baru 6-7 hari lalu
    expect(s.trend.length, 6);
    expect(s.trend.last.year, 2026);
    expect(s.trend.last.month, 8);
    expect(s.trend.last.total, 3500000);
    expect(s.trend.first.month, 3); // 5 bulan sebelum Agustus
    expect(s.aktivitas.first.payment.id, 'm2'); // 8/6, paling baru
    expect(s.aktivitas.first.customerName, 'IKA');
  });
```

- [ ] **Step 2: Jalankan test, pastikan gagal**

Run: `flutter test test/data/repositories/app_repository_test.dart`
Expected: FAIL — `CustomerFilter`/`CustomerSort`/`lastPaymentAt`/`collectibility`/`stats`/
`macetCount`/`trend`/`aktivitas` belum ada.

- [ ] **Step 3: Implementasi — model**

Edit `lib/data/models/customer.dart`. Tambahkan import di atas:
```dart
import '../../core/logic/collectibility.dart';
```
Ganti class `CustomerWithBalance` menjadi:
```dart
class CustomerWithBalance {
  final Customer customer;
  final int totalHutang, totalBayar;
  final DateTime? lastPaymentAt;         // pembayaran verified terakhir
  final Collectibility? collectibility;  // null jika sisa <= 0 (lunas/tanpa hutang)
  const CustomerWithBalance({
    required this.customer,
    required this.totalHutang,
    required this.totalBayar,
    this.lastPaymentAt,
    this.collectibility,
  });
  int get sisa => totalHutang - totalBayar;
}
```

- [ ] **Step 4: Implementasi — repository**

Edit `lib/data/repositories/app_repository.dart`. Tambahkan import:
```dart
import '../../core/logic/collectibility.dart';
import '../../core/logic/customer_stats.dart';
```

Tambahkan sebelum class `CustomerDetailData`:
```dart
enum CustomerFilter { semua, berhutang, macet, lunas, arsip }
enum CustomerSort { nama, hutang, terakhirBayar }

class MonthlyTotal {
  final int year, month, total;
  const MonthlyTotal({required this.year, required this.month, required this.total});
}

class PaymentActivityItem {
  final Payment payment;
  final String customerName;
  const PaymentActivityItem({required this.payment, required this.customerName});
}
```

Ubah `CustomerDetailData` — tambah field `stats`:
```dart
class CustomerDetailData {
  final Customer customer;
  final List<PurchaseStatus> items; // urut FIFO (tertua dulu)
  final List<Payment> payments; // urut terbaru dulu
  final Balance balance;
  final CustomerStats stats;
  const CustomerDetailData({
    required this.customer,
    required this.items,
    required this.payments,
    required this.balance,
    required this.stats,
  });
}
```

Ubah `DashboardStats` — tambah field baru:
```dart
class DashboardStats {
  final int totalPiutang, bayarBulanIni, customerBerhutang;
  final int macetTotal, macetCount;
  final List<CustomerWithBalance> topHutang; // maks 5, sisa > 0
  final List<MonthlyTotal> trend;            // 6 bulan terakhir, urut lama -> baru
  final List<PaymentActivityItem> aktivitas; // maks 8, terbaru dulu
  const DashboardStats({
    required this.totalPiutang,
    required this.bayarBulanIni,
    required this.customerBerhutang,
    required this.macetTotal,
    required this.macetCount,
    required this.topHutang,
    required this.trend,
    required this.aktivitas,
  });
}
```

Ganti method `customers()` menjadi:
```dart
  Future<List<CustomerWithBalance>> customers({
    String query = '',
    CustomerFilter filter = CustomerFilter.semua,
    CustomerSort sort = CustomerSort.nama,
    DateTime? today,
  }) async {
    final t = today ?? DateTime.now();
    final cs = await backend.readCustomers();
    final ps = await backend.readPurchases();
    final pm = await backend.readPayments();
    final rows = [
      for (final c in cs)
        () {
          final myP = ps.where((p) => p.customerId == c.id).toList();
          final myM = pm
              .where((p) => p.customerId == c.id && p.statusVerifikasi == 'verified')
              .toList();
          final b = balanceOf(myP, myM);
          final lastPay = myM.isEmpty
              ? null
              : myM.map((e) => e.tanggalBayar).reduce((a, b) => a.isAfter(b) ? a : b);
          final firstBuy = myP.isEmpty
              ? null
              : myP.map((e) => e.tanggalBeli).reduce((a, b) => a.isBefore(b) ? a : b);
          return CustomerWithBalance(
            customer: c,
            totalHutang: b.totalHutang,
            totalBayar: b.totalBayar,
            lastPaymentAt: lastPay,
            collectibility: b.sisa > 0
                ? collectibilityOf(lastPayment: lastPay, firstPurchase: firstBuy, today: t)
                : null,
          );
        }(),
    ];

    final q = query.trim().toLowerCase();
    Iterable<CustomerWithBalance> filtered =
        q.isEmpty ? rows : rows.where((r) => r.customer.nama.toLowerCase().contains(q));
    filtered = switch (filter) {
      CustomerFilter.arsip => filtered.where((r) => r.customer.isArchived),
      CustomerFilter.berhutang => filtered.where((r) => !r.customer.isArchived && r.sisa > 0),
      CustomerFilter.macet => filtered.where(
          (r) => !r.customer.isArchived && r.collectibility == Collectibility.macet),
      CustomerFilter.lunas => filtered.where(
          (r) => !r.customer.isArchived && r.totalHutang > 0 && r.sisa <= 0),
      CustomerFilter.semua => filtered.where((r) => !r.customer.isArchived),
    };

    final list = filtered.toList();
    list.sort((a, b) => switch (sort) {
          CustomerSort.hutang => b.sisa.compareTo(a.sisa),
          CustomerSort.terakhirBayar =>
            (b.lastPaymentAt ?? DateTime(1900)).compareTo(a.lastPaymentAt ?? DateTime(1900)),
          CustomerSort.nama =>
            a.customer.nama.toLowerCase().compareTo(b.customer.nama.toLowerCase()),
        });
    return list;
  }
```

Ganti method `customerDetail()`:
```dart
  Future<CustomerDetailData> customerDetail(String customerId) async {
    final cs = await backend.readCustomers();
    final ps = await backend.readPurchases();
    final pm = await backend.readPayments();
    final customer = cs.singleWhere((c) => c.id == customerId);
    final myPurchases = ps.where((p) => p.customerId == customerId).toList();
    final myPayments = pm.where((p) => p.customerId == customerId).toList()
      ..sort((a, b) => b.tanggalBayar.compareTo(a.tanggalBayar));
    final balance = balanceOf(myPurchases, myPayments);
    return CustomerDetailData(
      customer: customer,
      items: allocateFifo(myPurchases, balance.totalBayar),
      payments: myPayments,
      balance: balance,
      stats: customerStatsOf(myPurchases, myPayments),
    );
  }
```

Ganti method `dashboardStats()`:
```dart
  Future<DashboardStats> dashboardStats({DateTime? now}) async {
    final n = now ?? DateTime.now();
    final balances = await customers(today: n);
    final berhutang = balances.where((b) => b.sisa > 0).toList()
      ..sort((a, b) => b.sisa.compareTo(a.sisa));
    final macet = berhutang.where((b) => b.collectibility == Collectibility.macet).toList();

    final pm = (await backend.readPayments())
        .where((p) => p.statusVerifikasi == 'verified')
        .toList();
    final bayarBulanIni = pm
        .where((p) => p.tanggalBayar.year == n.year && p.tanggalBayar.month == n.month)
        .fold<int>(0, (s, p) => s + p.jumlah);

    final trend = [
      for (var i = 5; i >= 0; i--)
        () {
          final m = DateTime(n.year, n.month - i);
          final total = pm
              .where((p) => p.tanggalBayar.year == m.year && p.tanggalBayar.month == m.month)
              .fold<int>(0, (s, p) => s + p.jumlah);
          return MonthlyTotal(year: m.year, month: m.month, total: total);
        }(),
    ];

    final cs = await backend.readCustomers();
    final namaById = {for (final c in cs) c.id: c.nama};
    final sortedPm = [...pm]..sort((a, b) {
        final c = b.tanggalBayar.compareTo(a.tanggalBayar);
        return c != 0 ? c : b.createdAt.compareTo(a.createdAt);
      });
    final aktivitas = [
      for (final p in sortedPm.take(8))
        if (namaById.containsKey(p.customerId))
          PaymentActivityItem(payment: p, customerName: namaById[p.customerId]!),
    ];

    return DashboardStats(
      totalPiutang: berhutang.fold(0, (s, b) => s + b.sisa),
      bayarBulanIni: bayarBulanIni,
      customerBerhutang: berhutang.length,
      macetTotal: macet.fold(0, (s, b) => s + b.sisa),
      macetCount: macet.length,
      topHutang: berhutang.take(5).toList(),
      trend: trend,
      aktivitas: aktivitas,
    );
  }
```

- [ ] **Step 5: Perbaikan minimal compile-site — app_providers.dart**

Edit `lib/app_providers.dart`. Ganti:
```dart
final customersProvider = FutureProvider.autoDispose
    .family<List<CustomerWithBalance>, ({String query, bool sortByHutang})>(
        (ref, p) => ref
            .watch(repoProvider)
            .customers(query: p.query, sortByHutang: p.sortByHutang));
```
menjadi:
```dart
final customersProvider = FutureProvider.autoDispose
    .family<List<CustomerWithBalance>, ({String query, CustomerFilter filter, CustomerSort sort})>(
        (ref, p) => ref
            .watch(repoProvider)
            .customers(query: p.query, filter: p.filter, sort: p.sort));
```

- [ ] **Step 6: Perbaikan minimal compile-site — customers_page.dart**

Edit `lib/features/customers/customers_page.dart`. Tambahkan import:
```dart
import '../../data/repositories/app_repository.dart';
```
Ganti baris pemanggilan provider:
```dart
    final data =
        ref.watch(customersProvider((query: _query, sortByHutang: _sortByHutang)));
```
menjadi:
```dart
    final data = ref.watch(customersProvider((
      query: _query,
      filter: CustomerFilter.semua,
      sort: _sortByHutang ? CustomerSort.hutang : CustomerSort.nama,
    )));
```
(UI filter chip lengkap dikerjakan di Task 9 — ini hanya supaya tetap compile & lulus test.)

- [ ] **Step 7: Jalankan seluruh test, pastikan lulus**

Run: `flutter analyze && flutter test`
Expected: analyze bersih; semua test PASS (termasuk `customers_page_test.dart` yang
tidak berubah perilakunya).

- [ ] **Step 8: Commit**

```bash
git add lib/data/models/customer.dart lib/data/repositories/app_repository.dart \
        lib/app_providers.dart lib/features/customers/customers_page.dart \
        test/data/repositories/app_repository_test.dart
git commit -m "feat(data): kolektibilitas, filter/sort, stats, aktivitas & tren di AppRepository"
```

---

### Task 6: BrandLogo widget + font terbundel + token gradient + generator aset

**Files:**
- Create: `lib/widgets/brand_logo.dart`
- Create: `tool/brand_assets_test.dart`
- Create: `assets/fonts/Inter-ExtraBold.ttf` (di-download)
- Create: `assets/brand/logo_512.png`, `logo_adaptive.png`, `logo_splash.png`, `logo_pdf.png` (di-generate)
- Modify: `lib/core/theme.dart` (tambah token gradient)
- Modify: `pubspec.yaml` (assets + fonts)
- Test: `test/widgets/brand_logo_test.dart`

**Interfaces:**
- Produces: `class BrandLogo extends StatelessWidget { size }`,
  `class BrandLogoPainter extends CustomPainter { scale }`,
  `const brandGoldGradient` (LinearGradient) di `theme.dart`
- Consumed oleh: Task 7 (logo PDF), Task 8/12 (UI), Task 13 (launcher icon/splash)

- [ ] **Step 1: Download font Inter ExtraBold (dipakai painter & generator, offline-safe)**

```bash
mkdir -p assets/fonts assets/brand
URL=$(curl -s -A "Mozilla/4.0" "https://fonts.googleapis.com/css2?family=Inter:wght@800" \
  | grep -oE "https://[^)]+\.ttf" | head -1)
curl -L -o assets/fonts/Inter-ExtraBold.ttf "$URL"
ls -la assets/fonts/Inter-ExtraBold.ttf   # pastikan > 50KB
```

Jika perintah di atas gagal (mis. tanpa akses internet), simpan manual file TTF
bold/extrabold apa pun ke `assets/fonts/Inter-ExtraBold.ttf` sebelum lanjut —
langkah berikutnya butuh file ini ada.

- [ ] **Step 2: Tambahkan asset & font ke pubspec.yaml**

Tambahkan di section `flutter:` pada `pubspec.yaml`:
```yaml
  assets:
    - assets/brand/
  fonts:
    - family: InterBrand
      fonts:
        - asset: assets/fonts/Inter-ExtraBold.ttf
```

- [ ] **Step 3: Tulis test gagal — BrandLogo**

`test/widgets/brand_logo_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/widgets/brand_logo.dart';

void main() {
  testWidgets('BrandLogo merender CustomPaint tanpa error', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: BrandLogo(size: 64))),
    ));
    expect(find.byType(BrandLogo), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
```

- [ ] **Step 4: Jalankan test, pastikan gagal**

Run: `flutter test test/widgets/brand_logo_test.dart`
Expected: FAIL — `lib/widgets/brand_logo.dart` belum ada.

- [ ] **Step 5: Implementasi BrandLogo**

`lib/widgets/brand_logo.dart`:
```dart
import 'package:flutter/material.dart';

/// Logo monogram "S&I" — rounded square gradient emas. Dipakai di login,
/// app bar, launcher icon, splash, dan header PDF (lewat aset PNG yang
/// di-generate dari painter yang sama, lihat tool/brand_assets_test.dart).
class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: const BrandLogoPainter(),
      );
}

class BrandLogoPainter extends CustomPainter {
  /// Proporsi logo terhadap canvas (1.0 = penuh). Dipakai < 1.0 untuk
  /// safe-zone adaptive icon Android.
  final double scale;
  const BrandLogoPainter({this.scale = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide * scale;
    final center = size.center(Offset.zero);
    final rect = Rect.fromCenter(center: center, width: s, height: s);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(s * 0.24));
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF5B942), Color(0xFFD89B2B)],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);

    final tp = TextPainter(
      text: TextSpan(
        text: 'S&I',
        style: TextStyle(
          fontFamily: 'InterBrand',
          fontSize: s * 0.34,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF1C1600),
          letterSpacing: -0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(BrandLogoPainter oldDelegate) => oldDelegate.scale != scale;
}
```

- [ ] **Step 6: Jalankan test, pastikan lulus**

Run: `flutter test test/widgets/brand_logo_test.dart`
Expected: PASS

- [ ] **Step 7: Tambah token gradient di theme.dart**

Tambahkan di `lib/core/theme.dart`, setelah baris konstanta warna (`const _green = ...`):
```dart
// ── Brand S&I ──────────────────────────────────────────────────────────────
const brandGoldA = Color(0xFFF5B942);
const brandGoldB = Color(0xFFD89B2B);
const brandGoldGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [brandGoldA, brandGoldB],
);
```

- [ ] **Step 8: Tulis generator aset PNG**

`tool/brand_assets_test.dart` (bukan unit test — generator sekali-jalan):
```dart
// Generator aset brand (logo PNG untuk launcher icon, splash, PDF).
// BUKAN bagian dari `flutter test` biasa (folder tool/ tidak di-scan default).
// Jalankan manual setiap kali BrandLogoPainter berubah:
//   flutter test tool/brand_assets_test.dart
@TestOn('vm')
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/widgets/brand_logo.dart';

Future<void> _render(String path, double canvasSize, double logoScale,
    {bool withBackground = false}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = Size.square(canvasSize);
  if (withBackground) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF111318));
  }
  BrandLogoPainter(scale: logoScale).paint(canvas, size);
  final img = await recorder.endRecording().toImage(canvasSize.round(), canvasSize.round());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  test('generate brand PNG assets', () async {
    final fontBytes = File('assets/fonts/Inter-ExtraBold.ttf').readAsBytesSync();
    final loader = FontLoader('InterBrand')
      ..addFont(Future.value(ByteData.view(fontBytes.buffer)));
    await loader.load();

    Directory('assets/brand').createSync(recursive: true);
    await _render('assets/brand/logo_512.png', 512, 1.0);
    await _render('assets/brand/logo_adaptive.png', 1024, 0.62);
    await _render('assets/brand/logo_splash.png', 1024, 0.5, withBackground: true);
    await _render('assets/brand/logo_pdf.png', 256, 1.0);

    for (final f in ['logo_512.png', 'logo_adaptive.png', 'logo_splash.png', 'logo_pdf.png']) {
      expect(File('assets/brand/$f').lengthSync(), greaterThan(1000), reason: f);
    }
  });
}
```

- [ ] **Step 9: Jalankan generator**

Run: `flutter test tool/brand_assets_test.dart`
Expected: PASS — 4 file PNG muncul di `assets/brand/` dengan ukuran > 1KB.

- [ ] **Step 10: Verifikasi keseluruhan**

Run: `flutter analyze && flutter test`
Expected: bersih, semua test lulus.

- [ ] **Step 11: Commit**

```bash
git add pubspec.yaml pubspec.lock assets/fonts/Inter-ExtraBold.ttf assets/brand/ \
        lib/widgets/brand_logo.dart lib/core/theme.dart tool/brand_assets_test.dart \
        test/widgets/brand_logo_test.dart
git commit -m "feat(brand): BrandLogo + font InterBrand + token gradient + generator aset PNG"
```

---

### Task 7: Kartu Piutang PDF

**Files:**
- Create: `lib/features/statement/statement_data.dart`
- Create: `lib/features/statement/statement_pdf.dart`
- Test: `test/features/statement/statement_data_test.dart`
- Modify: `pubspec.yaml` (tambah `pdf`, `printing`)

**Interfaces:**
- Consumes: `CustomerDetailData` (Task 5), `ItemStatus` (`lib/core/logic/fifo.dart`), `kBrandName`/`kBrandTagline` (Task 4)
- Produces: `class StatementData { nama, noHp?, alamat?, totalBelanja, totalBayar, sisaHutang, items, payments, generatedAt }`,
  `StatementData buildStatementData(CustomerDetailData d, {DateTime? now})`,
  `Future<Uint8List> buildStatementPdf(StatementData data, {required Uint8List logoPng})`
- Consumed oleh: Task 10 (tombol "Kartu Piutang")

- [ ] **Step 1: Tambah dependency**

```bash
flutter pub add pdf printing
```

- [ ] **Step 2: Tulis test gagal — buildStatementData**

`test/features/statement/statement_data_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/core/logic/customer_stats.dart';
import 'package:sandiapp/core/logic/fifo.dart';
import 'package:sandiapp/data/models/customer.dart';
import 'package:sandiapp/data/models/payment.dart';
import 'package:sandiapp/data/models/purchase.dart';
import 'package:sandiapp/data/repositories/app_repository.dart';
import 'package:sandiapp/features/statement/statement_data.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1);
  final customer = Customer(id: 'c1', nama: 'WIWIK', noHp: '0812', createdAt: t0, updatedAt: t0);
  final p1 = Purchase(id: 'p1', customerId: 'c1', namaBarang: 'HP', hargaJual: 2000000,
      tanggalBeli: DateTime(2026, 1, 1), createdAt: t0, updatedAt: t0);
  final p2 = Purchase(id: 'p2', customerId: 'c1', namaBarang: 'TV', hargaJual: 1000000,
      tanggalBeli: DateTime(2026, 2, 1), createdAt: t0, updatedAt: t0);
  final m1 = Payment(id: 'm1', customerId: 'c1', jumlah: 1500000, tanggalBayar: DateTime(2026, 1, 15),
      createdAt: t0, updatedAt: t0);

  test('buildStatementData merangkum saldo, barang, dan pembayaran', () {
    final balance = balanceOf([p1, p2], [m1]);
    final items = allocateFifo([p1, p2], balance.totalBayar);
    final detail = CustomerDetailData(
      customer: customer,
      items: items,
      payments: [m1],
      balance: balance,
      stats: customerStatsOf([p1, p2], [m1]),
    );

    final data = buildStatementData(detail, now: DateTime(2026, 8, 12));

    expect(data.nama, 'WIWIK');
    expect(data.noHp, '0812');
    expect(data.totalBelanja, 3000000);
    expect(data.totalBayar, 1500000);
    expect(data.sisaHutang, 1500000);
    expect(data.items.length, 2);
    expect(data.items[0].statusLabel, 'SEBAGIAN'); // p1: 2jt, alokasi 1.5jt
    expect(data.items[0].sisa, 500000);
    expect(data.items[1].statusLabel, 'BELUM'); // p2: belum ter-cover
    expect(data.payments.single.jumlah, 1500000);
    expect(data.generatedAt, DateTime(2026, 8, 12));
  });
}
```

- [ ] **Step 3: Jalankan test, pastikan gagal**

Run: `flutter test test/features/statement/statement_data_test.dart`
Expected: FAIL — `lib/features/statement/statement_data.dart` belum ada.

- [ ] **Step 4: Implementasi statement_data.dart**

`lib/features/statement/statement_data.dart`:
```dart
import '../../core/logic/fifo.dart';
import '../../data/repositories/app_repository.dart';

class StatementItem {
  final String namaBarang, statusLabel;
  final DateTime tanggal;
  final int harga, sisa;
  const StatementItem({
    required this.namaBarang,
    required this.statusLabel,
    required this.tanggal,
    required this.harga,
    required this.sisa,
  });
}

class StatementPayment {
  final DateTime tanggal;
  final int jumlah;
  final String metode;
  const StatementPayment({required this.tanggal, required this.jumlah, required this.metode});
}

class StatementData {
  final String nama;
  final String? noHp, alamat;
  final int totalBelanja, totalBayar, sisaHutang;
  final List<StatementItem> items;
  final List<StatementPayment> payments;
  final DateTime generatedAt;
  const StatementData({
    required this.nama,
    this.noHp,
    this.alamat,
    required this.totalBelanja,
    required this.totalBayar,
    required this.sisaHutang,
    required this.items,
    required this.payments,
    required this.generatedAt,
  });
}

String _statusLabel(ItemStatus s) => switch (s) {
      ItemStatus.lunas => 'LUNAS',
      ItemStatus.sebagian => 'SEBAGIAN',
      ItemStatus.belum => 'BELUM',
    };

/// Rangkum [CustomerDetailData] jadi data siap-cetak (murni, tanpa I/O).
StatementData buildStatementData(CustomerDetailData d, {DateTime? now}) => StatementData(
      nama: d.customer.nama,
      noHp: d.customer.noHp,
      alamat: d.customer.alamat,
      totalBelanja: d.balance.totalHutang,
      totalBayar: d.balance.totalBayar,
      sisaHutang: d.balance.sisa,
      items: [
        for (final i in d.items)
          StatementItem(
            namaBarang: i.purchase.namaBarang,
            statusLabel: _statusLabel(i.status),
            tanggal: i.purchase.tanggalBeli,
            harga: i.purchase.hargaJual,
            sisa: i.sisa,
          ),
      ],
      payments: [
        for (final p in d.payments)
          StatementPayment(tanggal: p.tanggalBayar, jumlah: p.jumlah, metode: p.metode),
      ],
      generatedAt: now ?? DateTime.now(),
    );
```

- [ ] **Step 5: Jalankan test, pastikan lulus**

Run: `flutter test test/features/statement/statement_data_test.dart`
Expected: PASS

- [ ] **Step 6: Implementasi statement_pdf.dart (tanpa test — dirender manual di Task 10)**

`lib/features/statement/statement_pdf.dart`:
```dart
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/brand.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import 'statement_data.dart';

const _charcoal = PdfColor.fromInt(0xFF111318);
const _gold = PdfColor.fromInt(0xFFD89B2B);

Future<Uint8List> buildStatementPdf(StatementData data, {required Uint8List logoPng}) async {
  final logo = pw.MemoryImage(logoPng);
  final doc = pw.Document();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('$kBrandName - $kBrandTagline',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ),
      build: (ctx) => [
        pw.Row(children: [
          pw.Image(logo, width: 44, height: 44),
          pw.SizedBox(width: 12),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(kBrandName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text('Kartu Piutang Customer',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ]),
          pw.Spacer(),
          pw.Text(tampilTanggal(data.generatedAt),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        ]),
        pw.SizedBox(height: 16),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(data.nama, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            if (data.noHp != null) pw.Text(data.noHp!, style: const pw.TextStyle(fontSize: 10)),
            if (data.alamat != null) pw.Text(data.alamat!, style: const pw.TextStyle(fontSize: 10)),
          ]),
        ),
        pw.SizedBox(height: 12),
        pw.Row(children: [
          _summaryBox('Total Belanja', formatRupiah(data.totalBelanja)),
          _summaryBox('Total Bayar', formatRupiah(data.totalBayar)),
          _summaryBox('Sisa Hutang', formatRupiah(data.sisaHutang), highlight: true),
        ]),
        pw.SizedBox(height: 16),
        pw.Text('DAFTAR BARANG',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _gold)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Barang', 'Tanggal', 'Harga', 'Status', 'Sisa'],
          headerStyle:
              pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: _charcoal),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: {2: pw.Alignment.centerRight, 4: pw.Alignment.centerRight},
          data: [
            for (final i in data.items)
              [
                i.namaBarang,
                tampilTanggal(i.tanggal),
                formatRupiah(i.harga),
                i.statusLabel,
                i.sisa > 0 ? formatRupiah(i.sisa) : '-',
              ],
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Text('RIWAYAT PEMBAYARAN',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _gold)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Tanggal', 'Jumlah', 'Metode'],
          headerStyle:
              pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: _charcoal),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: {1: pw.Alignment.centerRight},
          data: [
            for (final p in data.payments) [tampilTanggal(p.tanggal), formatRupiah(p.jumlah), p.metode],
          ],
        ),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _summaryBox(String label, String value, {bool highlight = false}) => pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 3),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: highlight ? const PdfColor.fromInt(0xFFFFF3D6) : PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(label.toUpperCase(), style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ]),
      ),
    );
```

**Catatan:** `tampilTanggal` butuh `initializeDateFormatting('id_ID')` sudah
dipanggil (sudah terjadi di `main()` app). Fungsi ini tidak diuji otomatis di
task ini — diverifikasi manual di Task 10 saat tombol "Kartu Piutang" dipakai.

- [ ] **Step 7: Verifikasi**

Run: `flutter analyze && flutter test`
Expected: bersih, semua test lulus.

- [ ] **Step 8: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/features/statement/ test/features/statement/
git commit -m "feat(statement): kartu piutang PDF (buildStatementData + buildStatementPdf)"
```

---

### Task 8: Dashboard overhaul — hero animasi, macet, tren, aktivitas

**Files:**
- Create: `lib/widgets/collectibility_dot.dart`
- Modify: `lib/widgets/stat_card.dart` (cegah overflow nilai panjang)
- Modify: `lib/features/dashboard/dashboard_page.dart` (rombak total)
- Test: `test/features/dashboard_page_test.dart`

**Interfaces:**
- Consumes: `DashboardStats` extras (Task 5), `formatRupiahCompact`/`relativeDay` (Task 1), `Collectibility` (Task 2)
- Produces: `class CollectibilityDot extends StatelessWidget { status, size }`
- Tidak mengubah: `_pilihCustomerLalu`, `_QuickActionButton` (dipertahankan apa adanya)

- [ ] **Step 1: Buat CollectibilityDot**

`lib/widgets/collectibility_dot.dart`:
```dart
import 'package:flutter/material.dart';

import '../core/logic/collectibility.dart';

/// Dot warna status kolektibilitas. `status == null` (lunas/tanpa hutang) -> tidak tampil.
class CollectibilityDot extends StatelessWidget {
  final Collectibility? status;
  final double size;
  const CollectibilityDot({super.key, required this.status, this.size = 8});

  @override
  Widget build(BuildContext context) {
    final s = status;
    if (s == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final color = switch (s) {
      Collectibility.lancar => cs.tertiary,
      Collectibility.perhatian => const Color(0xFFF59E0B),
      Collectibility.kurangLancar => const Color(0xFFF97316),
      Collectibility.macet => cs.error,
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
```

- [ ] **Step 2: Cegah overflow di StatCard**

Edit `lib/widgets/stat_card.dart`. Ganti bagian `Text(value, ...)` menjadi
dibungkus `FittedBox` agar nilai panjang (mis. hasil `formatRupiahCompact`)
tidak overflow di layar kecil:
```dart
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: effectiveColor, fontWeight: FontWeight.w700)),
          ),
```
(Ganti langsung `Text(value, ...)` yang sebelumnya berdiri sendiri di dalam `Column`.)

- [ ] **Step 3: Tulis test gagal — dashboard baru**

`test/features/dashboard_page_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sandiapp/app_providers.dart';
import 'package:sandiapp/data/models/customer.dart';
import 'package:sandiapp/data/models/payment.dart';
import 'package:sandiapp/data/models/purchase.dart';
import 'package:sandiapp/data/repositories/app_repository.dart';
import 'package:sandiapp/features/dashboard/dashboard_page.dart';

import '../fakes/fake_backend.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  final now = DateTime.now();

  AppRepository makeRepo() => AppRepository(
        FakeBackend(
          customers: [
            Customer(id: 'c1', nama: 'WIWIK', createdAt: now, updatedAt: now),
            Customer(id: 'c2', nama: 'BUDI', createdAt: now, updatedAt: now),
          ],
          purchases: [
            Purchase(id: 'p1', customerId: 'c1', namaBarang: 'HP', hargaJual: 2000000,
                tanggalBeli: now.subtract(const Duration(days: 200)), createdAt: now, updatedAt: now),
            Purchase(id: 'p2', customerId: 'c2', namaBarang: 'TV', hargaJual: 1000000,
                tanggalBeli: now.subtract(const Duration(days: 10)), createdAt: now, updatedAt: now),
          ],
          payments: [
            Payment(id: 'm1', customerId: 'c1', jumlah: 500000,
                tanggalBayar: now.subtract(const Duration(days: 100)), createdAt: now, updatedAt: now),
            Payment(id: 'm2', customerId: 'c2', jumlah: 300000, tanggalBayar: now,
                createdAt: now, updatedAt: now),
          ],
        ),
        currentUserId: () => 'admin-1',
      );

  testWidgets('menampilkan hero, macet, tren, aktivitas terakhir', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [repoProvider.overrideWithValue(makeRepo())],
      child: const MaterialApp(home: Scaffold(body: DashboardPage())),
    ));
    await tester.pumpAndSettle();

    expect(find.text('TOTAL PIUTANG AKTIF'), findsOneWidget);
    expect(find.text('Rp 2,2 jt'), findsOneWidget); // (2jt-500rb)+(1jt-300rb)
    expect(find.textContaining('MACET'), findsWidgets);
    expect(find.text('AKTIVITAS TERAKHIR'), findsOneWidget);
    expect(find.text('BUDI'), findsWidgets); // aktivitas + hutang terbesar
    expect(find.byType(LineChart), findsOneWidget);
  });
}
```

- [ ] **Step 4: Jalankan test, pastikan gagal**

Run: `flutter test test/features/dashboard_page_test.dart`
Expected: FAIL — section baru belum ada di dashboard.

- [ ] **Step 5: Implementasi — ganti isi dashboard_page.dart**

Ganti import di bagian atas `lib/features/dashboard/dashboard_page.dart` menjadi:
```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app_providers.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../data/models/customer.dart';
import '../../data/repositories/app_repository.dart';
import '../../widgets/collectibility_dot.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stat_card.dart';
import '../customers/customer_form_page.dart';
import '../payments/payment_form_page.dart';
import '../purchases/purchase_form_page.dart';
```

Pertahankan `_inisial`, `_pilihCustomerLalu`, `_QuickActionButton` **tanpa
perubahan**. Ganti isi method `build` bagian `data: (s) => ...` (dari
`RefreshIndicator(` sampai penutup `),` sebelum `),` penutup `stats.when`)
menjadi:
```dart
      data: (s) {
        final now = DateTime.now();
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Greeting ────────────────────────────────────────────────
              Text('Halo, Admin 👋', style: textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(tanggal, style: textTheme.bodyMedium),
              const SizedBox(height: 20),

              // ── Hero card piutang total ───────────────────────────────
              _HeroCard(totalPiutang: s.totalPiutang, customerBerhutang: s.customerBerhutang),
              const SizedBox(height: 12),

              // ── Stat cards: masuk bulan ini + macet ───────────────────
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Masuk Bulan Ini',
                      value: formatRupiahCompact(s.bayarBulanIni),
                      valueColor: cs.tertiary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatCard(
                      label: s.macetCount == 0 ? 'Macet >90 Hari' : 'Macet >90 Hari · ${s.macetCount}',
                      value: s.macetCount == 0 ? '—' : formatRupiahCompact(s.macetTotal),
                      valueColor: s.macetCount > 0 ? cs.error : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Tren pembayaran 6 bulan ────────────────────────────────
              Text('TREN PEMBAYARAN 6 BULAN', style: textTheme.labelSmall),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 4),
                  child: _TrendChart(trend: s.trend),
                ),
              ),
              const SizedBox(height: 20),

              // ── Aksi Cepat ──────────────────────────────────────────────
              Text('AKSI CEPAT', style: textTheme.labelSmall),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final gap = constraints.maxWidth < 360 ? 8.0 : 10.0;
                  final tileWidth = (constraints.maxWidth - (gap * 2)) / 3;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      SizedBox(
                        width: tileWidth,
                        child: _QuickActionButton(
                          icon: Icons.payments_outlined,
                          label: 'Bayar',
                          onPressed: () => _pilihCustomerLalu(
                            context,
                            ref,
                            (id) => PaymentFormPage(customerId: id),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: tileWidth,
                        child: _QuickActionButton(
                          icon: Icons.person_add_outlined,
                          label: 'Customer',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CustomerFormPage()),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: tileWidth,
                        child: _QuickActionButton(
                          icon: Icons.add_shopping_cart_outlined,
                          label: 'Barang',
                          onPressed: () => _pilihCustomerLalu(
                            context,
                            ref,
                            (id) => PurchaseFormPage(customerId: id),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // ── Aktivitas Terakhir ──────────────────────────────────────
              Text('AKTIVITAS TERAKHIR', style: textTheme.labelSmall),
              const SizedBox(height: 8),
              if (s.aktivitas.isEmpty)
                const EmptyState(message: 'Belum ada pembayaran tercatat.')
              else
                Card(
                  child: Column(
                    children: [
                      for (int i = 0; i < s.aktivitas.length; i++) ...[
                        if (i > 0)
                          Divider(height: 1, indent: 72, color: cs.surfaceContainerHighest),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            child: Text(_inisial(s.aktivitas[i].customerName),
                                style: TextStyle(
                                    color: cs.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                          title: Text(s.aktivitas[i].customerName,
                              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                          subtitle: Text(relativeDay(s.aktivitas[i].payment.tanggalBayar, now)),
                          trailing: Text('+${formatRupiahCompact(s.aktivitas[i].payment.jumlah)}',
                              style: textTheme.labelLarge?.copyWith(color: cs.tertiary)),
                          onTap: () => context.push('/customers/${s.aktivitas[i].payment.customerId}'),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // ── Hutang Terbesar ─────────────────────────────────────────
              Text('HUTANG TERBESAR', style: textTheme.labelSmall),
              const SizedBox(height: 8),
              if (s.topHutang.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: cs.surfaceContainerHighest),
                    color: cs.surfaceContainer.withValues(alpha: 0.38),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.primaryContainer.withValues(alpha: 0.38),
                        ),
                        child: Icon(Icons.inventory_2_outlined, color: cs.primary, size: 28),
                      ),
                      const SizedBox(height: 14),
                      Text('Tidak ada piutang berjalan.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                )
              else
                Card(
                  child: Column(
                    children: [
                      for (int i = 0; i < s.topHutang.length; i++) ...[
                        if (i > 0)
                          Divider(height: 1, indent: 72, color: cs.surfaceContainerHighest),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            child: Text(_inisial(s.topHutang[i].customer.nama),
                                style: TextStyle(
                                    color: cs.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                          title: Text(s.topHutang[i].customer.nama,
                              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CollectibilityDot(status: s.topHutang[i].collectibility),
                              const SizedBox(width: 6),
                              Text(formatRupiah(s.topHutang[i].sisa),
                                  style: textTheme.labelLarge?.copyWith(color: cs.primary)),
                            ],
                          ),
                          onTap: () => context.push('/customers/${s.topHutang[i].customer.id}'),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
```

Tambahkan 2 class baru di akhir file (setelah `_QuickActionButton`):
```dart
class _HeroCard extends StatelessWidget {
  final int totalPiutang, customerBerhutang;
  const _HeroCard({required this.totalPiutang, required this.customerBerhutang});

  Widget _circle(double d, Color c) =>
      Container(width: d, height: d, decoration: BoxDecoration(shape: BoxShape.circle, color: c));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surfaceContainerHighest,
            cs.surfaceContainer,
            cs.surfaceContainerHighest.withValues(alpha: 0.74),
          ],
          stops: const [0, 0.55, 1],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.surfaceContainerHighest),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 20, offset: const Offset(0, 12)),
        ],
      ),
      child: Stack(children: [
        Positioned(right: -40, top: -40, child: _circle(140, cs.primary.withValues(alpha: 0.06))),
        Positioned(right: 30, bottom: -50, child: _circle(100, cs.primary.withValues(alpha: 0.04))),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text('TOTAL PIUTANG AKTIF', style: textTheme.labelSmall)),
              Icon(Icons.trending_up_rounded, size: 20, color: cs.primary.withValues(alpha: 0.82)),
            ]),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: totalPiutang.toDouble()),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(formatRupiahCompact(v.round()),
                    style: textTheme.displayMedium
                        ?.copyWith(color: cs.primary, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 6),
            Text('dari $customerBerhutang customer berhutang', style: textTheme.bodyMedium),
          ],
        ),
      ]),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<MonthlyTotal> trend;
  const _TrendChart({required this.trend});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxV = trend.fold<double>(0, (m, t) => t.total > m ? t.total.toDouble() : m);
    return SizedBox(
      height: 150,
      child: LineChart(LineChartData(
        minY: 0,
        maxY: maxV == 0 ? 1 : maxV * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= trend.length) return const SizedBox.shrink();
                final t = trend[i];
                return Text(DateFormat('MMM', 'id_ID').format(DateTime(t.year, t.month)),
                    style: Theme.of(context).textTheme.labelSmall);
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < trend.length; i++) FlSpot(i.toDouble(), trend[i].total.toDouble())],
            isCurved: true,
            color: cs.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: cs.primary.withValues(alpha: 0.15)),
          ),
        ],
      )),
    );
  }
}
```

- [ ] **Step 6: Jalankan test, pastikan lulus**

Run: `flutter test test/features/dashboard_page_test.dart`
Expected: PASS (semua)

- [ ] **Step 7: Verifikasi keseluruhan**

Run: `flutter analyze && flutter test`
Expected: bersih, semua test lulus (termasuk test lama yang tidak berubah).

- [ ] **Step 8: Commit**

```bash
git add lib/widgets/collectibility_dot.dart lib/widgets/stat_card.dart \
        lib/features/dashboard/dashboard_page.dart test/features/dashboard_page_test.dart
git commit -m "feat(dashboard): overhaul fintech — hero animasi, macet, tren, aktivitas"
```

---

### Task 9: Customers page — filter chip, sort, dot kolektibilitas

**Files:**
- Modify: `lib/features/customers/customers_page.dart`
- Modify: `test/features/customers_page_test.dart`

**Interfaces:**
- Consumes: `CustomerFilter`, `CustomerSort` (Task 5), `CollectibilityDot` (Task 8)

- [ ] **Step 1: Tulis test gagal — filter chip**

Tambahkan di akhir `test/features/customers_page_test.dart` (sebelum kurung
kurawal penutup `}` dari `main()`), dan tambahkan import
`package:sandiapp/data/repositories/app_repository.dart` di bagian atas jika
diperlukan oleh helper baru:
```dart
  testWidgets('filter chip Macet menyaring customer yang macet', (tester) async {
    final now = DateTime.now();
    final repo = AppRepository(
      FakeBackend(
        customers: [
          Customer(id: 'c1', nama: 'WIWIK', createdAt: now, updatedAt: now),
          Customer(id: 'c2', nama: 'IKA', createdAt: now, updatedAt: now),
        ],
        purchases: [
          Purchase(id: 'p1', customerId: 'c1', namaBarang: 'HP', hargaJual: 2000000,
              tanggalBeli: now.subtract(const Duration(days: 120)), createdAt: now, updatedAt: now),
          Purchase(id: 'p2', customerId: 'c2', namaBarang: 'TV', hargaJual: 1000000,
              tanggalBeli: now.subtract(const Duration(days: 5)), createdAt: now, updatedAt: now),
        ],
        payments: [
          Payment(id: 'm1', customerId: 'c1', jumlah: 500000,
              tanggalBayar: now.subtract(const Duration(days: 100)), createdAt: now, updatedAt: now),
          Payment(id: 'm2', customerId: 'c2', jumlah: 200000,
              tanggalBayar: now.subtract(const Duration(days: 1)), createdAt: now, updatedAt: now),
        ],
      ),
      currentUserId: () => 'admin-1',
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [repoProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: Scaffold(body: CustomersPage())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('WIWIK'), findsOneWidget);
    expect(find.text('IKA'), findsOneWidget);

    await tester.tap(find.text('Macet'));
    await tester.pumpAndSettle();
    expect(find.text('WIWIK'), findsOneWidget); // macet, 100 hari lalu
    expect(find.text('IKA'), findsNothing);     // lancar, 1 hari lalu
  });
```

- [ ] **Step 2: Jalankan test, pastikan gagal**

Run: `flutter test test/features/customers_page_test.dart`
Expected: FAIL — belum ada chip `'Macet'` di halaman.

- [ ] **Step 3: Implementasi — ganti seluruh isi customers_page.dart**

`lib/features/customers/customers_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_providers.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/app_repository.dart';
import '../../widgets/collectibility_dot.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import 'customer_form_page.dart';

class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});
  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  String _query = '';
  CustomerFilter _filter = CustomerFilter.semua;
  CustomerSort _sort = CustomerSort.nama;

  static const _chips = [
    (CustomerFilter.semua, 'Semua'),
    (CustomerFilter.berhutang, 'Berhutang'),
    (CustomerFilter.macet, 'Macet'),
    (CustomerFilter.lunas, 'Lunas'),
    (CustomerFilter.arsip, 'Arsip'),
  ];

  static const _sorts = [
    (CustomerSort.nama, 'Nama A-Z'),
    (CustomerSort.hutang, 'Hutang terbesar'),
    (CustomerSort.terakhirBayar, 'Terakhir bayar'),
  ];

  String _inisial(String nama) {
    final parts = nama.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return nama.isNotEmpty ? nama[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final data = ref.watch(customersProvider((query: _query, filter: _filter, sort: _sort)));
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'customers-fab',
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Tambah'),
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const CustomerFormPage())),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cari nama customer...',
                  prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<CustomerSort>(
              tooltip: 'Urutkan',
              icon: const Icon(Icons.sort),
              initialValue: _sort,
              onSelected: (v) => setState(() => _sort = v),
              itemBuilder: (ctx) => [
                for (final s in _sorts) PopupMenuItem(value: s.$1, child: Text(s.$2)),
              ],
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final c in _chips) ...[
                ChoiceChip(
                  label: Text(c.$2),
                  selected: _filter == c.$1,
                  onSelected: (_) => setState(() => _filter = c.$1),
                ),
                const SizedBox(width: 8),
              ],
            ]),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: data.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(message: 'Gagal memuat data: $e'),
            data: (rows) => rows.isEmpty
                ? EmptyState(
                    message: 'Belum ada customer.',
                    actionLabel: _filter == CustomerFilter.semua && _query.isEmpty
                        ? '+ Tambah Customer'
                        : null,
                    onAction: _filter == CustomerFilter.semua && _query.isEmpty
                        ? () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const CustomerFormPage()))
                        : null,
                  )
                : RefreshIndicator(
                    onRefresh: () async => ref.invalidate(customersProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: rows.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 4),
                      itemBuilder: (_, i) {
                        final r = rows[i];
                        final lunas = r.totalHutang > 0 && r.sisa <= 0;
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: cs.primaryContainer,
                              child: Text(_inisial(r.customer.nama),
                                  style: TextStyle(
                                      color: cs.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                            ),
                            title: Text(r.customer.nama,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            subtitle: lunas
                                ? Row(children: [
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: cs.tertiary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text('LUNAS',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: cs.tertiary)),
                                    ),
                                  ])
                                : Row(children: [
                                    CollectibilityDot(status: r.collectibility),
                                    const SizedBox(width: 6),
                                    Text('Sisa: ${formatRupiah(r.sisa)}',
                                        style: Theme.of(context).textTheme.bodyMedium),
                                  ]),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline, size: 20, color: cs.onSurfaceVariant),
                              tooltip: 'Hapus customer',
                              onPressed: () async {
                                if (await confirmDialog(context,
                                    title: 'Hapus customer?',
                                    message:
                                        'Data ${r.customer.nama} disembunyikan (bisa dipulihkan lewat database).')) {
                                  await mutate(ref,
                                      () => ref.read(repoProvider).deleteCustomer(r.customer.id));
                                }
                              },
                            ),
                            onTap: () => context.push('/customers/${r.customer.id}'),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ]),
    );
  }
}
```

- [ ] **Step 4: Jalankan test, pastikan lulus**

Run: `flutter test test/features/customers_page_test.dart`
Expected: PASS (semua, termasuk 2 test lama)

- [ ] **Step 5: Verifikasi keseluruhan**

Run: `flutter analyze && flutter test`

- [ ] **Step 6: Commit**

```bash
git add lib/features/customers/customers_page.dart test/features/customers_page_test.dart
git commit -m "feat(customers): filter chip kolektibilitas + sort + dot status"
```

---

### Task 10: Customer detail — Customer 360°, badge setia, reminder WA, kartu PDF

**Files:**
- Modify: `lib/features/customers/customer_detail_page.dart`
- Test: `test/features/customer_detail_page_test.dart`

**Interfaces:**
- Consumes: `CustomerDetailData.stats` (Task 5), `normalizePhoneId`/`buildWaReminderUri`/`renderWaTemplate` (Task 4),
  `waTemplateProvider` (Task 4), `buildStatementData`/`buildStatementPdf` (Task 7)

- [ ] **Step 1: Tulis test gagal**

`test/features/customer_detail_page_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sandiapp/app_providers.dart';
import 'package:sandiapp/data/models/customer.dart';
import 'package:sandiapp/data/models/payment.dart';
import 'package:sandiapp/data/models/purchase.dart';
import 'package:sandiapp/data/repositories/app_repository.dart';
import 'package:sandiapp/features/customers/customer_detail_page.dart';

import '../fakes/fake_backend.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  final t0 = DateTime.utc(2026, 1, 1);

  AppRepository makeRepo({String? noHp}) => AppRepository(
        FakeBackend(
          customers: [Customer(id: 'c1', nama: 'WIWIK', noHp: noHp, createdAt: t0, updatedAt: t0)],
          purchases: [
            Purchase(id: 'p1', customerId: 'c1', namaBarang: 'HP', hargaJual: 500000,
                tanggalBeli: DateTime(2026, 1, 1), createdAt: t0, updatedAt: t0),
            Purchase(id: 'p2', customerId: 'c1', namaBarang: 'TV', hargaJual: 500000,
                tanggalBeli: DateTime(2026, 2, 1), createdAt: t0, updatedAt: t0),
            Purchase(id: 'p3', customerId: 'c1', namaBarang: 'AC', hargaJual: 500000,
                tanggalBeli: DateTime(2026, 3, 1), createdAt: t0, updatedAt: t0),
          ],
          payments: const [],
        ),
        currentUserId: () => 'admin-1',
      );

  Future<void> pump(WidgetTester tester, AppRepository repo) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [repoProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: CustomerDetailPage(customerId: 'c1')),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('badge Customer Setia muncul untuk >= 3 transaksi + 360 section', (tester) async {
    await pump(tester, makeRepo());
    expect(find.text('Customer Setia'), findsOneWidget);
    await tester.dragUntilVisible(
        find.text('RINGKASAN CUSTOMER'), find.byType(CustomScrollView), const Offset(0, -300));
    expect(find.text('RINGKASAN CUSTOMER'), findsOneWidget);
  });

  testWidgets('tombol Ingatkan via WA disabled tanpa no_hp valid', (tester) async {
    await pump(tester, makeRepo());
    await tester.dragUntilVisible(
        find.text('Ingatkan via WA'), find.byType(CustomScrollView), const Offset(0, -300));
    final btn = tester.widget<OutlinedButton>(
        find.ancestor(of: find.text('Ingatkan via WA'), matching: find.byType(OutlinedButton)));
    expect(btn.onPressed, isNull);
  });

  testWidgets('tombol Ingatkan via WA aktif dengan no_hp valid', (tester) async {
    await pump(tester, makeRepo(noHp: '081234567890'));
    await tester.dragUntilVisible(
        find.text('Ingatkan via WA'), find.byType(CustomScrollView), const Offset(0, -300));
    final btn = tester.widget<OutlinedButton>(
        find.ancestor(of: find.text('Ingatkan via WA'), matching: find.byType(OutlinedButton)));
    expect(btn.onPressed, isNotNull);
  });
}
```

- [ ] **Step 2: Jalankan test, pastikan gagal**

Run: `flutter test test/features/customer_detail_page_test.dart`
Expected: FAIL — badge/section/tombol belum ada.

- [ ] **Step 3: Implementasi — tambah import**

Tambahkan di bagian atas `lib/features/customers/customer_detail_page.dart`:
```dart
import 'package:flutter/services.dart' show rootBundle;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/whatsapp.dart';
import '../../core/wa_template.dart';
import '../statement/statement_data.dart';
import '../statement/statement_pdf.dart';
```

- [ ] **Step 4: Tambah badge di header**

Di dalam `flexibleSpace`, ganti `Column` yang berisi nama/hp/alamat customer
(cari `Text(d.customer.nama, style: Theme.of(context).textTheme.titleLarge),`)
menjadi:
```dart
                              Text(d.customer.nama,
                                  style: Theme.of(context).textTheme.titleLarge),
                              if (d.stats.customerSetia)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: cs.primaryContainer.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      Icon(Icons.star_rounded, size: 12, color: cs.primary),
                                      const SizedBox(width: 4),
                                      Text('Customer Setia',
                                          style: TextStyle(
                                              fontSize: 10, fontWeight: FontWeight.w700, color: cs.primary)),
                                    ]),
                                  ),
                                ),
```

- [ ] **Step 5: Tambah action row + section 360° setelah stat cards**

Cari blok:
```dart
                  StatCard(
                    label: 'Sisa Hutang',
                    value: formatRupiah(d.balance.sisa),
                    valueColor: d.balance.sisa > 0 ? cs.error : cs.tertiary,
                  ),
                  const SizedBox(height: 24),
```
Ganti `const SizedBox(height: 24),` di baris itu menjadi:
```dart
                  const SizedBox(height: 12),

                  // ── Aksi WA & PDF ─────────────────────────────────────
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.chat_outlined, size: 18),
                        label: const Text('Ingatkan via WA'),
                        onPressed: normalizePhoneId(d.customer.noHp) == null
                            ? null
                            : () => _ingatkanWA(context, ref, d),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                        label: const Text('Kartu Piutang'),
                        onPressed: () => _bagikanPdf(context, d),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── Customer 360 ──────────────────────────────────────
                  Text('RINGKASAN CUSTOMER', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        Row(children: [
                          Expanded(
                              child: _InfoItem(
                                  label: 'Customer Sejak',
                                  value: d.stats.customerSejak != null
                                      ? tampilTanggal(d.stats.customerSejak!)
                                      : '-')),
                          Expanded(
                              child:
                                  _InfoItem(label: 'Transaksi', value: '${d.stats.jumlahTransaksi}')),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                              child: _InfoItem(
                                  label: 'Rata-rata Cicilan',
                                  value: d.stats.rataRataCicilan != null
                                      ? formatRupiah(d.stats.rataRataCicilan!)
                                      : '-')),
                          Expanded(
                              child: _InfoItem(
                                  label: 'Kecepatan Lunas',
                                  value: d.stats.kecepatanLunasHari != null
                                      ? '${d.stats.kecepatanLunasHari} hari'
                                      : '-')),
                        ]),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 24),
```

- [ ] **Step 6: Tambah handler & widget bantu di akhir file**

Tambahkan sebelum penutup class terakhir (`_StatusChip`), tambahkan 2 fungsi
top-level dan 1 widget baru di akhir file:
```dart
Future<void> _ingatkanWA(BuildContext context, WidgetRef ref, CustomerDetailData d) async {
  final phone = normalizePhoneId(d.customer.noHp);
  if (phone == null) return; // tombol sudah disabled
  final template = ref.read(waTemplateProvider);
  final msg = renderWaTemplate(template, nama: d.customer.nama, sisaHutang: d.balance.sisa);
  try {
    final ok =
        await launchUrl(buildWaReminderUri(phone: phone, message: msg), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Tidak bisa membuka WhatsApp.')));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Tidak bisa membuka WhatsApp.')));
    }
  }
}

Future<void> _bagikanPdf(BuildContext context, CustomerDetailData d) async {
  try {
    final logo = await rootBundle.load('assets/brand/logo_pdf.png');
    final data = buildStatementData(d);
    final bytes = await buildStatementPdf(data, logoPng: logo.buffer.asUint8List());
    await Printing.sharePdf(bytes: bytes, filename: 'kartu-piutang-${d.customer.nama}.pdf');
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Gagal membuat PDF. Coba lagi.')));
    }
  }
}

class _InfoItem extends StatelessWidget {
  final String label, value;
  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: tt.labelSmall),
      const SizedBox(height: 4),
      Text(value, style: tt.titleMedium),
    ]);
  }
}
```

- [ ] **Step 7: Jalankan test, pastikan lulus**

Run: `flutter test test/features/customer_detail_page_test.dart`
Expected: PASS (semua)

- [ ] **Step 8: Verifikasi keseluruhan**

Run: `flutter analyze && flutter test`

- [ ] **Step 9: Commit**

```bash
git add lib/features/customers/customer_detail_page.dart test/features/customer_detail_page_test.dart
git commit -m "feat(customers): detail 360°, badge Customer Setia, reminder WA, kartu PDF"
```

---

### Task 11: Settings — editor template pesan WA

**Files:**
- Modify: `lib/features/settings/settings_page.dart`

**Interfaces:**
- Consumes: `waTemplateProvider` (Task 4), `kDefaultWaTemplate` (Task 4)

- [ ] **Step 1: Tambah import**

Tambahkan di bagian atas `lib/features/settings/settings_page.dart`:
```dart
import '../../core/utils/whatsapp.dart';
import '../../core/wa_template.dart';
```

- [ ] **Step 2: Tambah ListTile & dialog editor**

Di dalam `build`, tambahkan `final template = ref.watch(waTemplateProvider);`
di dekat deklarasi `final sync = ref.watch(syncControllerProvider);`.

Tambahkan `ListTile` baru di dalam `Card` "Preferensi", setelah blok `if (!kIsWeb) [...]`
(sebelum penutup `]),` dari `Column`):
```dart
          Divider(height: 1, indent: 16, color: cs.surfaceContainerHighest),
          ListTile(
            leading: Icon(Icons.chat_outlined, color: cs.onSurfaceVariant),
            title: const Text('Template Pesan WA'),
            subtitle: Text(template, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.edit_outlined, size: 18),
            onTap: () => _editWaTemplate(context, ref, template),
          ),
```

Tambahkan fungsi top-level baru di akhir file:
```dart
Future<void> _editWaTemplate(BuildContext context, WidgetRef ref, String current) async {
  final ctrl = TextEditingController(text: current);
  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Template Pesan WA'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Placeholder: {nama}, {sisa_hutang}, {bisnis}',
            style: Theme.of(ctx).textTheme.bodyMedium),
        const SizedBox(height: 12),
        TextField(
          controller: ctrl,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Tulis template pesan...'),
        ),
      ]),
      actions: [
        TextButton(
          onPressed: () async {
            await ref.read(waTemplateProvider.notifier).reset();
            if (ctx.mounted) Navigator.pop(ctx, false);
          },
          child: const Text('Reset'),
        ),
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        FilledButton(
          onPressed: () async {
            final v = ctrl.text.trim();
            await ref.read(waTemplateProvider.notifier).setTemplate(v.isEmpty ? kDefaultWaTemplate : v);
            if (ctx.mounted) Navigator.pop(ctx, true);
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
  ctrl.dispose();
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template disimpan.')));
  }
}
```

- [ ] **Step 3: Verifikasi**

Run: `flutter analyze && flutter test`
Expected: bersih, semua test lulus (tidak ada widget test untuk `SettingsPage`
karena butuh Supabase/drift terinisialisasi — cukup diverifikasi lewat
`test/core/wa_template_test.dart` yang sudah ada di Task 4).

- [ ] **Step 4: Commit**

```bash
git add lib/features/settings/settings_page.dart
git commit -m "feat(settings): editor template pesan WA"
```

---

### Task 12: Login brand moment + nama app S&I Finance

**Files:**
- Modify: `lib/features/auth/login_page.dart`
- Modify: `lib/app.dart`
- Modify: `lib/features/shell/app_shell.dart`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `web/index.html`

- [ ] **Step 1: Login page — logo animasi + nama brand**

Tambahkan import di `lib/features/auth/login_page.dart`:
```dart
import '../../core/brand.dart';
import '../../widgets/brand_logo.dart';
```
Ganti blok:
```dart
                  const SizedBox(height: 48),
                  Text('SandiApp',
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(color: cs.primary)),
                  const SizedBox(height: 8),
                  Text('Kelola kredit barang dengan mudah',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 48),
```
menjadi:
```dart
                  const SizedBox(height: 40),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                    builder: (_, v, child) => Opacity(
                      opacity: v.clamp(0.0, 1.0),
                      child: Transform.scale(scale: 0.7 + 0.3 * v, child: child),
                    ),
                    child: const BrandLogo(size: 84),
                  ),
                  const SizedBox(height: 20),
                  Text(kBrandName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(kBrandTagline, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 40),
```

- [ ] **Step 2: Judul app**

Edit `lib/app.dart`. Tambahkan import `import 'core/brand.dart';` dan ganti
`title: 'SandiApp',` menjadi `title: kBrandShortName,`.

- [ ] **Step 3: AppBar shell**

Edit `lib/features/shell/app_shell.dart`. Tambahkan import:
```dart
import '../../core/brand.dart';
import '../../widgets/brand_logo.dart';
```
Ganti `title: const Text('SandiApp'),` menjadi:
```dart
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          const BrandLogo(size: 22),
          const SizedBox(width: 8),
          Text(kBrandShortName),
        ]),
```

- [ ] **Step 4: Label Android**

Edit `android/app/src/main/AndroidManifest.xml`. Ganti
`android:label="sandiapp"` menjadi `android:label="S&amp;I Finance"`
(ampersand **wajib** di-escape di XML).

- [ ] **Step 5: Judul & metadata web**

Edit `web/index.html`. Ganti:
```html
  <meta name="description" content="A new Flutter project.">
```
menjadi:
```html
  <meta name="description" content="S&amp;I Finance Solution — Kelola Kredit, Tanpa Ribet">
```
Ganti `content="sandiapp">` (apple-mobile-web-app-title) menjadi
`content="S&amp;I Finance">`, dan ganti `<title>sandiapp</title>` menjadi
`<title>S&amp;I Finance</title>`.

- [ ] **Step 6: Verifikasi**

Run: `flutter analyze && flutter test`
Expected: bersih, semua test lulus.

- [ ] **Step 7: Commit**

```bash
git add lib/features/auth/login_page.dart lib/app.dart lib/features/shell/app_shell.dart \
        android/app/src/main/AndroidManifest.xml web/index.html
git commit -m "feat(brand): login brand moment + nama app S&I Finance"
```

---

### Task 13: Splash screen + launcher icon

**Files:**
- Modify: `pubspec.yaml` (dev deps + konfigurasi)
- Generated: file icon Android/web, `launch_background.xml`, dll (oleh tooling)

- [ ] **Step 1: Tambah dev dependencies**

```bash
flutter pub add -d flutter_launcher_icons flutter_native_splash
```

- [ ] **Step 2: Tambah konfigurasi di pubspec.yaml**

Tambahkan di level root `pubspec.yaml` (sejajar dengan `dependencies:`,
`dev_dependencies:`, `flutter:`):
```yaml
flutter_launcher_icons:
  android: true
  image_path: "assets/brand/logo_512.png"
  adaptive_icon_background: "#111318"
  adaptive_icon_foreground: "assets/brand/logo_adaptive.png"
  web:
    generate: true
    image_path: "assets/brand/logo_512.png"
    background_color: "#111318"
    theme_color: "#111318"

flutter_native_splash:
  color: "#111318"
  image: "assets/brand/logo_splash.png"
  android_12:
    color: "#111318"
    image: "assets/brand/logo_splash.png"
  web: true
```

- [ ] **Step 3: Jalankan generator icon**

```bash
dart run flutter_launcher_icons
```
Expected: log sukses, file di `android/app/src/main/res/mipmap-*/` &
`web/icons/` berubah.

- [ ] **Step 4: Jalankan generator splash**

```bash
dart run flutter_native_splash:create
```
Expected: log sukses, `android/app/src/main/res/drawable*/launch_background.xml`
& `android/app/src/main/res/values*/styles.xml` berubah, `web/splash/` muncul.

- [ ] **Step 5: Verifikasi**

```bash
git status --short   # pastikan file icon/splash berubah sesuai ekspektasi
flutter analyze && flutter test
```
Manual (opsional, jika ada waktu): `./scripts/build_apk.sh` lalu install ke
device/emulator untuk memastikan icon & splash tampil benar.

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock android/ web/
git commit -m "feat(brand): splash screen + launcher icon S&I"
```

---

### Task 14: Kunci PIN (stretch — opsional, kerjakan terakhir)

Task ini boleh dilewati tanpa mengganggu task lain jika waktu terbatas.

**Files:**
- Create: `lib/core/pin_lock.dart`
- Create: `lib/features/auth/pin_lock_page.dart`
- Modify: `lib/app.dart`
- Modify: `lib/features/settings/settings_page.dart`
- Modify: `pubspec.yaml` (tambah `crypto`)
- Test: `test/core/pin_lock_test.dart`

**Interfaces:**
- Produces: `String hashPin(String pin)`, `class PinLockState { enabled, locked }`,
  `pinLockProvider` (`NotifierProvider<PinLockNotifier, PinLockState>`),
  `class PinLockPage extends ConsumerStatefulWidget`

- [ ] **Step 1: Tambah dependency**

```bash
flutter pub add crypto
```

- [ ] **Step 2: Tulis test gagal**

`test/core/pin_lock_test.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandiapp/core/pin_lock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('hashPin deterministik & beda pin -> beda hash', () {
    expect(hashPin('1234'), hashPin('1234'));
    expect(hashPin('1234'), isNot(hashPin('4321')));
  });

  test('enable -> enabled true, locked false; sesi baru -> locked true', () async {
    SharedPreferences.setMockInitialValues({});
    final c1 = ProviderContainer();
    addTearDown(c1.dispose);
    expect(c1.read(pinLockProvider).enabled, isFalse);

    await c1.read(pinLockProvider.notifier).enable('1234');
    expect(c1.read(pinLockProvider).enabled, isTrue);
    expect(c1.read(pinLockProvider).locked, isFalse);

    final c2 = ProviderContainer(); // simulasi restart app
    addTearDown(c2.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(c2.read(pinLockProvider).enabled, isTrue);
    expect(c2.read(pinLockProvider).locked, isTrue);
  });

  test('unlock: benar -> true & locked false; salah -> false, tetap locked', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(pinLockProvider.notifier).enable('1234');

    expect(await c.read(pinLockProvider.notifier).unlock('0000'), isFalse);
    expect(await c.read(pinLockProvider.notifier).unlock('1234'), isTrue);
    expect(c.read(pinLockProvider).locked, isFalse);
  });

  test('disable -> kembali ke nonaktif', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(pinLockProvider.notifier).enable('1234');
    await c.read(pinLockProvider.notifier).disable();
    expect(c.read(pinLockProvider).enabled, isFalse);
  });
}
```

- [ ] **Step 3: Jalankan test, pastikan gagal**

Run: `flutter test test/core/pin_lock_test.dart`
Expected: FAIL — file belum ada.

- [ ] **Step 4: Implementasi pin_lock.dart**

`lib/core/pin_lock.dart`:
```dart
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

String hashPin(String pin) => sha256.convert(utf8.encode('sni:$pin')).toString();

class PinLockState {
  final bool enabled, locked;
  const PinLockState({required this.enabled, required this.locked});
}

class PinLockNotifier extends Notifier<PinLockState> {
  static const _key = 'pin_hash';

  @override
  PinLockState build() {
    SharedPreferences.getInstance().then((p) {
      final h = p.getString(_key);
      state = PinLockState(enabled: h != null, locked: h != null);
    });
    return const PinLockState(enabled: false, locked: false);
  }

  Future<void> enable(String pin) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, hashPin(pin));
    state = const PinLockState(enabled: true, locked: false);
  }

  Future<bool> unlock(String pin) async {
    final p = await SharedPreferences.getInstance();
    final ok = p.getString(_key) == hashPin(pin);
    if (ok) state = const PinLockState(enabled: true, locked: false);
    return ok;
  }

  Future<void> disable() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
    state = const PinLockState(enabled: false, locked: false);
  }
}

final pinLockProvider = NotifierProvider<PinLockNotifier, PinLockState>(PinLockNotifier.new);
```

- [ ] **Step 5: Jalankan test, pastikan lulus**

Run: `flutter test test/core/pin_lock_test.dart`
Expected: PASS (semua)

- [ ] **Step 6: Implementasi PinLockPage**

`lib/features/auth/pin_lock_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/pin_lock.dart';
import '../../widgets/brand_logo.dart';

class PinLockPage extends ConsumerStatefulWidget {
  const PinLockPage({super.key});
  @override
  ConsumerState<PinLockPage> createState() => _PinLockPageState();
}

class _PinLockPageState extends ConsumerState<PinLockPage> {
  String _input = '';

  void _tap(String d) {
    if (_input.length >= 4) return;
    setState(() => _input += d);
    if (_input.length == 4) _verify();
  }

  void _backspace() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  Future<void> _verify() async {
    final ok = await ref.read(pinLockProvider.notifier).unlock(_input);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('PIN salah. Coba lagi.')));
      setState(() => _input = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const BrandLogo(size: 64),
            const SizedBox(height: 16),
            Text('Masukkan PIN', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < 4; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _input.length ? cs.primary : cs.surfaceContainerHighest,
                  ),
                ),
            ]),
            const SizedBox(height: 32),
            SizedBox(
              width: 240,
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final d in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
                    TextButton(onPressed: () => _tap(d), child: Text(d, style: const TextStyle(fontSize: 22))),
                  const SizedBox.shrink(),
                  TextButton(onPressed: () => _tap('0'), child: const Text('0', style: TextStyle(fontSize: 22))),
                  IconButton(onPressed: _backspace, icon: const Icon(Icons.backspace_outlined)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Gate di app.dart**

Edit `lib/app.dart`. Tambahkan import:
```dart
import 'core/pin_lock.dart';
import 'features/auth/pin_lock_page.dart';
```
Ubah `SandiApp.build` menjadi:
```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pin = ref.watch(pinLockProvider);
    if (pin.enabled && pin.locked) {
      return MaterialApp(
        title: kBrandShortName,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: ref.watch(themeModeProvider),
        home: const PinLockPage(),
      );
    }
    return MaterialApp.router(
      title: kBrandShortName,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id'), Locale('en')],
    );
  }
```

- [ ] **Step 8: Toggle di Settings**

Edit `lib/features/settings/settings_page.dart`. Tambahkan import
`import '../../core/pin_lock.dart';` dan `final pin = ref.watch(pinLockProvider);`.
Tambahkan `SwitchListTile` baru di Card "Preferensi" (setelah `ListTile` Template WA):
```dart
          Divider(height: 1, indent: 16, color: cs.surfaceContainerHighest),
          SwitchListTile(
            secondary: Icon(Icons.lock_outline, color: cs.onSurfaceVariant),
            title: const Text('Kunci PIN'),
            subtitle: const Text('Kunci aplikasi dengan PIN 4 digit'),
            value: pin.enabled,
            onChanged: (v) async {
              if (v) {
                await _setPinDialog(context, ref);
              } else {
                if (await confirmDialog(context,
                    title: 'Matikan kunci PIN?', message: 'App tidak akan meminta PIN lagi.')) {
                  await ref.read(pinLockProvider.notifier).disable();
                }
              }
            },
          ),
```

Tambahkan fungsi top-level baru di akhir file:
```dart
Future<void> _setPinDialog(BuildContext context, WidgetRef ref) async {
  final ctrl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Atur PIN'),
      content: TextField(
        controller: ctrl,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 4,
        decoration: const InputDecoration(hintText: '4 digit PIN'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        FilledButton(
          onPressed: ctrl.text.length == 4 ? () => Navigator.pop(ctx, true) : null,
          child: const Text('Aktifkan'),
        ),
      ],
    ),
  );
  if (ok == true && ctrl.text.length == 4) {
    await ref.read(pinLockProvider.notifier).enable(ctrl.text);
  }
  ctrl.dispose();
}
```

- [ ] **Step 9: Verifikasi keseluruhan**

Run: `flutter analyze && flutter test`
Expected: bersih, semua test lulus.

- [ ] **Step 10: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/pin_lock.dart lib/features/auth/pin_lock_page.dart \
        lib/app.dart lib/features/settings/settings_page.dart test/core/pin_lock_test.dart
git commit -m "feat(settings): kunci PIN opsional (stretch)"
```

---

## Verifikasi Akhir (setelah semua task)

```bash
flutter analyze
flutter test
./scripts/build_apk.sh    # opsional tapi disarankan — cek icon, splash, label
```

Kriteria sukses (dari spec §10):
- Splash → login → dashboard terasa seperti produk fintech.
- F1–F6 berfungsi di Android & web (WA/PDF menyesuaikan platform: mobile share
  sheet vs download/print di web).
- Tidak ada regresi fungsional; `flutter analyze` bersih; semua test hijau.
- Brand S&I konsisten: icon, splash, login, dashboard, PDF.

