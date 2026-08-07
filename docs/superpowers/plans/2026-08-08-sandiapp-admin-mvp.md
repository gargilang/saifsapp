# SandiApp Admin MVP — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Aplikasi admin kredit barang (running balance + FIFO) — Flutter, Android offline-first + web online-only, backend Supabase.

**Architecture:** Satu codebase Flutter. Repository tunggal `AppRepository` di atas interface `Backend` (Android: `DriftBackend` SQLite + `SyncEngine` ⇄ Supabase; web: `RemoteBackend` langsung Supabase). Semua kalkulasi (FIFO, saldo, keuntungan, anggaran) adalah fungsi Dart murni yang di-test, dipakai kedua backend. Spec: `docs/superpowers/specs/2026-08-08-sandiapp-admin-design.md`.

**Tech Stack:** Flutter 3.44.2 / Dart 3.12.2, Riverpod (Notifier API), drift (SQLite), supabase_flutter, go_router, connectivity_plus, workmanager, fl_chart, intl, uuid, shared_preferences.

## Global Constraints

- Target platform **hanya** `android` dan `web` (tidak ada iOS, tidak ada desktop).
- Semua teks UI dalam **Bahasa Indonesia**.
- Uang = `int` rupiah (tanpa desimal). Tampil `Rp 1.500.000` via `intl` locale `id_ID`.
- ID = UUIDv4 dibuat di client (package `uuid`).
- Semua tabel bisnis: soft delete via `deleted_at`, `updated_at` UTC, `created_by`.
- Kredensial Supabase HANYA via `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`; tidak di-commit.
- Pembayaran yang dihitung ke saldo hanya `status_verifikasi = 'verified'` (default untuk input admin).
- TDD: test dulu untuk semua logika murni & data layer. Widget test wajib: list customer, form pembayaran.
- Commit per task, conventional commits (`feat:`, `test:`, `chore:`).
- Perintah test: `flutter test`. Perintah analisis: `flutter analyze` (harus bersih sebelum commit).

## Struktur File (yang dibuat di seluruh plan)

```
lib/
  main.dart                     # bootstrap: Supabase init, pilih backend, ProviderContainer
  app.dart                      # SandiApp + routerProvider
  app_providers.dart            # repoProvider, data providers, mutate(), invalidation
  core/theme.dart
  core/utils/money.dart         # formatRupiah, parseRupiah
  core/utils/dates.dart         # dateOnly, today, tampilTanggal, bulanTahun, monthRange
  core/logic/fifo.dart          # ItemStatus, PurchaseStatus, Balance, balanceOf, allocateFifo
  core/logic/budget.dart        # BudgetLine, withRunningSaldo
  core/logic/profit.dart        # ProfitRow, profitPerMonth, profitPerYear
  data/models/customer.dart     # Customer, CustomerWithBalance
  data/models/purchase.dart
  data/models/payment.dart
  data/models/budget_entry.dart
  data/local/app_database.dart  # drift: 4 tabel + AppDatabase + mapper row<->model
  data/local/drift_backend.dart # DriftBackend implements Backend
  data/remote/remote_store.dart # RemoteStore (abstract) + SupabaseRemoteStore
  data/remote/remote_backend.dart # RemoteBackend implements Backend (web)
  data/repositories/backend.dart  # abstract Backend
  data/repositories/app_repository.dart
  data/sync/sync_state.dart     # SyncStateStore (shared_preferences)
  data/sync/sync_engine.dart
  data/sync/sync_controller.dart
  features/auth/auth_controller.dart, login_page.dart
  features/shell/app_shell.dart
  features/dashboard/dashboard_page.dart
  features/customers/customers_page.dart, customer_detail_page.dart, customer_form_page.dart
  features/purchases/purchase_form_page.dart
  features/payments/payment_form_page.dart
  features/reports/reports_page.dart
  features/budget/budget_page.dart
  features/settings/settings_page.dart
  widgets/money_input_field.dart, empty_state.dart, confirm_dialog.dart,
          sync_badge.dart, offline_banner.dart, stat_card.dart
test/
  core/utils/money_test.dart
  core/logic/fifo_test.dart, budget_test.dart, profit_test.dart
  data/models/models_test.dart
  data/local/app_database_test.dart
  data/sync/sync_engine_test.dart
  data/repositories/app_repository_test.dart
  fakes/fake_remote_store.dart, fake_backend.dart
  features/customers_page_test.dart, payment_form_test.dart
supabase/migrations/0001_init.sql
docs/supabase-setup.md
AGENTS.md
```

---

### Task 1: Scaffold proyek Flutter + tooling

**Files:**
- Create: seluruh skeleton via `flutter create` di `/home/gemi/Projects/sandiapp`
- Create: `AGENTS.md`, `lib/core/theme.dart`
- Modify: `pubspec.yaml` (via `flutter pub add`), `lib/main.dart` (sementara), `test/widget_test.dart` (ganti bawaan)

**Interfaces:**
- Produces: proyek Flutter bernama `sandiapp`, org `com.sandiapp`, platform android+web; semua dependency terinstall; `flutter analyze` bersih.

- [ ] **Step 1: Inisialisasi git + flutter create**

```bash
cd /home/gemi/Projects/sandiapp
git init
flutter create --project-name sandiapp --org com.sandiapp --platforms android,web .
```

(`ref/`, `docs/` tetap ada; flutter create tidak menimpanya.)

- [ ] **Step 2: Tambah dependency**

```bash
flutter pub add flutter_riverpod go_router supabase_flutter drift drift_flutter \
  connectivity_plus workmanager intl fl_chart uuid shared_preferences
flutter pub add flutter_localizations --sdk flutter
flutter pub add --dev drift_dev build_runner
```

- [ ] **Step 3: Buat struktur folder + theme**

```bash
mkdir -p lib/core/utils lib/core/logic lib/data/models lib/data/local lib/data/remote \
  lib/data/repositories lib/data/sync lib/features/auth lib/features/shell \
  lib/features/dashboard lib/features/customers lib/features/purchases \
  lib/features/payments lib/features/reports lib/features/budget lib/features/settings \
  lib/widgets test/core/utils test/core/logic test/data/models test/data/local \
  test/data/sync test/data/repositories test/fakes test/features supabase/migrations
```

`lib/core/theme.dart`:

```dart
import 'package:flutter/material.dart';

ThemeData buildTheme(Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorSchemeSeed: const Color(0xFF00695C),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
  );
}
```

- [ ] **Step 4: Ganti `lib/main.dart` sementara + `test/widget_test.dart` smoke test**

`lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'core/theme.dart';

void main() => runApp(const SandiApp());

class SandiApp extends StatelessWidget {
  const SandiApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'SandiApp',
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: const Scaffold(body: Center(child: Text('SandiApp'))),
      );
}
```

`test/widget_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/main.dart';

void main() {
  testWidgets('smoke: app renders', (tester) async {
    await tester.pumpWidget(const SandiApp());
    expect(find.text('SandiApp'), findsOneWidget);
  });
}
```

- [ ] **Step 5: Tulis AGENTS.md**

```markdown
# SandiApp

Aplikasi admin kredit barang (running balance + FIFO). Flutter: Android (offline-first,
drift SQLite + sync) & web (online-only langsung Supabase). Backend: Supabase.

## Perintah
- Test: `flutter test`
- Analisis: `flutter analyze`
- Run Android: `flutter run -d <device> --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
- Build web: `flutter build web --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
- Codegen drift: `dart run build_runner build --delete-conflicting-outputs`

## Konvensi
- Teks UI Bahasa Indonesia. Uang = int rupiah. ID = UUIDv4 client-side.
- Soft delete (`deleted_at`). TDD untuk logika murni. Commit conventional.
- Spec: docs/superpowers/specs/. Plan: docs/superpowers/plans/.
- Data asli Excel: ref/ (migrasi nanti, bukan scope MVP).
```

- [ ] **Step 6: Verifikasi + commit**

```bash
flutter analyze && flutter test
```

Expected: analyze bersih, 1 test pass. Lalu:

```bash
git add -A && git commit -m "chore: scaffold proyek Flutter + tooling"
```

---

### Task 2: Skema database Supabase (migrasi SQL + panduan setup)

**Files:**
- Create: `supabase/migrations/0001_init.sql`
- Create: `docs/supabase-setup.md`

**Interfaces:**
- Produces: tabel `profiles, customers, purchases, payments, budget_entries`; trigger `updated_at`; trigger `handle_new_user`; RLS policy admin; bucket `bukti-bayar`; policy customer masa depan (ter-comment). Dieksekusi manual oleh user di SQL Editor dashboard Supabase.

- [ ] **Step 1: Tulis `supabase/migrations/0001_init.sql`**

```sql
-- SandiApp — skema awal
-- Jalankan di Supabase SQL Editor. Lihat docs/supabase-setup.md.

create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  display_name text not null,
  role text not null default 'admin' check (role in ('admin', 'customer')),
  created_at timestamptz not null default now()
);

-- Profil otomatis saat user baru dibuat via dashboard Auth.
-- CATATAN fase client app: pendaftaran customer harus men-set role 'customer'
-- (mis. via raw_user_meta_data), jangan biarkan default 'admin'.
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1)));
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create table public.customers (
  id uuid primary key,
  nama text not null,
  no_hp text,
  alamat text,
  catatan text,
  is_archived boolean not null default false,
  auth_user_id uuid,                 -- PLACEHOLDER client app: link akun customer
  created_by uuid references public.profiles,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.purchases (
  id uuid primary key,
  customer_id uuid not null references public.customers,
  nama_barang text not null,
  harga_jual bigint not null check (harga_jual >= 0),
  harga_beli bigint check (harga_beli >= 0),  -- null = dikecualikan dari laporan keuntungan
  tanggal_beli date not null,
  catatan text,
  created_by uuid references public.profiles,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.payments (
  id uuid primary key,
  customer_id uuid not null references public.customers,
  jumlah bigint not null check (jumlah > 0),
  tanggal_bayar date not null,
  metode text not null default 'tunai' check (metode in ('tunai', 'transfer', 'lainnya')),
  catatan text,
  sumber text not null default 'admin' check (sumber in ('admin', 'client')),
  status_verifikasi text not null default 'verified'
    check (status_verifikasi in ('pending', 'verified', 'rejected')),
  bukti_foto_url text,               -- PLACEHOLDER client app
  created_by uuid references public.profiles,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.budget_entries (
  id uuid primary key,
  tanggal date not null,
  nama_transaksi text not null,
  tipe text not null check (tipe in ('pemasukan', 'pengeluaran')),
  jumlah bigint not null check (jumlah > 0),
  catatan text,
  created_by uuid references public.profiles,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

-- updated_at kanonik di server (dipakai sync pull + last-write-wins)
create or replace function public.set_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

create trigger trg_customers_updated before insert or update on public.customers
  for each row execute function public.set_updated_at();
create trigger trg_purchases_updated before insert or update on public.purchases
  for each row execute function public.set_updated_at();
create trigger trg_payments_updated before insert or update on public.payments
  for each row execute function public.set_updated_at();
create trigger trg_budget_updated before insert or update on public.budget_entries
  for each row execute function public.set_updated_at();

-- RLS: WAJIB aktif
alter table public.profiles enable row level security;
alter table public.customers enable row level security;
alter table public.purchases enable row level security;
alter table public.payments enable row level security;
alter table public.budget_entries enable row level security;

create policy "profiles_read_own" on public.profiles for select to authenticated
  using (id = auth.uid());

-- MVP: admin boleh semua. (Jumlah admin kecil, satu workspace bersama.)
create policy "admin_all_customers" on public.customers for all to authenticated
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'))
  with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));
create policy "admin_all_purchases" on public.purchases for all to authenticated
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'))
  with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));
create policy "admin_all_payments" on public.payments for all to authenticated
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'))
  with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));
create policy "admin_all_budget" on public.budget_entries for all to authenticated
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'))
  with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));

-- ===== FUTURE client app (BELUM AKTIF — uncomment saat fase client) =====
-- create policy "customer_read_own" on public.customers for select to authenticated
--   using (auth_user_id = auth.uid());
-- create policy "customer_read_own_purchases" on public.purchases for select to authenticated
--   using (exists (select 1 from public.customers c
--     where c.id = customer_id and c.auth_user_id = auth.uid()));
-- create policy "customer_read_own_payments" on public.payments for select to authenticated
--   using (exists (select 1 from public.customers c
--     where c.id = customer_id and c.auth_user_id = auth.uid()));
-- create policy "customer_insert_own_payment" on public.payments for insert to authenticated
--   with check (exists (select 1 from public.customers c
--     where c.id = customer_id and c.auth_user_id = auth.uid()));

-- Bucket cadangan client app (private; belum dipakai UI MVP)
insert into storage.buckets (id, name, public) values ('bukti-bayar', 'bukti-bayar', false);
```

- [ ] **Step 2: Tulis `docs/supabase-setup.md`**

```markdown
# Setup Supabase (sekali, oleh owner)

1. Buat project baru di https://supabase.com/dashboard (region Singapore, plan Free cukup).
2. Buka SQL Editor → paste isi `supabase/migrations/0001_init.sql` → Run.
3. Buat akun admin: Authentication → Users → Add user → email + password,
   centang "Auto Confirm User". Profil admin terbuat otomatis (lihat tabel profiles).
4. Project Settings → API → salin `Project URL` dan `anon public key`.
5. Jalankan app:
   flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=eyJ...
6. Kedua nilai ini RAHASIA-lokal: jangan commit. Anon key aman diekspos ke client
   SELAMA RLS aktif (sudah diatur di migrasi).
```

- [ ] **Step 3: Commit**

```bash
git add supabase/ docs/supabase-setup.md && git commit -m "feat: skema database Supabase + panduan setup"
```

---

### Task 3: Utils uang & tanggal (TDD)

**Files:**
- Create: `lib/core/utils/money.dart`, `lib/core/utils/dates.dart`
- Test: `test/core/utils/money_test.dart`

**Interfaces:**
- Produces: `String formatRupiah(int)`, `int parseRupiah(String)`, `String dateOnly(DateTime)` ('yyyy-MM-dd'), `DateTime today()`, `String tampilTanggal(DateTime)` ('d MMM yyyy' id-ID), `String bulanTahun(int year, int month)`, `(DateTime, DateTime) monthRange(int year, int month)` (awal inklusif, akhir eksklusif).

- [ ] **Step 1: Tulis test gagal — `test/core/utils/money_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sandiapp/core/utils/money.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  group('formatRupiah', () {
    test('format ribuan', () => expect(formatRupiah(1500000), 'Rp 1.500.000'));
    test('nol', () => expect(formatRupiah(0), 'Rp 0'));
  });
  group('parseRupiah', () {
    test('angka polos', () => expect(parseRupiah('1500000'), 1500000));
    test('dengan pemisah', () => expect(parseRupiah('Rp 1.500.000'), 1500000));
    test('kosong', () => expect(parseRupiah(''), 0));
  });
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

```bash
flutter test test/core/utils/money_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: package:sandiapp/core/utils/money.dart`.

- [ ] **Step 3: Implementasi**

`lib/core/utils/money.dart`:

```dart
import 'package:intl/intl.dart';

final _rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

/// 1500000 -> 'Rp 1.500.000'
String formatRupiah(int value) => _rupiah.format(value);

/// 'Rp 1.500.000' / '1500000' -> 1500000. Input non-digit dibuang.
int parseRupiah(String input) {
  final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.isEmpty ? 0 : int.parse(digits);
}
```

`lib/core/utils/dates.dart`:

```dart
import 'package:intl/intl.dart';

final _iso = DateFormat('yyyy-MM-dd');

/// DateTime -> 'yyyy-MM-dd' (untuk kolom date Postgres)
String dateOnly(DateTime d) => _iso.format(d);

/// Hari ini tanpa komponen jam.
DateTime today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

/// '8 Agu 2026'
String tampilTanggal(DateTime d) => DateFormat('d MMM yyyy', 'id_ID').format(d);

/// 'Agustus 2026'
String bulanTahun(int year, int month) =>
    DateFormat('MMMM yyyy', 'id_ID').format(DateTime(year, month));

/// Rentang bulan [awal inklusif, akhir eksklusif).
(DateTime, DateTime) monthRange(int year, int month) =>
    (DateTime(year, month), DateTime(year, month + 1));
```

Catatan: `initializeDateFormatting('id_ID')` dipanggil sekali di `main.dart` (Task 12) dan di setUpAll test.

- [ ] **Step 4: Jalankan, pastikan pass**

```bash
flutter test test/core/utils/money_test.dart
```

Expected: 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils test/core/utils && git commit -m "feat: utils uang & tanggal"
```

---

### Task 4: Model domain + JSON (TDD)

**Files:**
- Create: `lib/data/models/customer.dart`, `purchase.dart`, `payment.dart`, `budget_entry.dart`
- Test: `test/data/models/models_test.dart`

**Interfaces:**
- Produces (dipakai semua task berikutnya):
  - `Customer({id, nama, noHp?, alamat?, catatan?, isArchived, authUserId?, createdBy?, createdAt, updatedAt, deletedAt?})` + `copyWith` + `fromJson/toJson`
  - `CustomerWithBalance({customer, totalHutang, totalBayar})` + getter `sisa`
  - `Purchase({id, customerId, namaBarang, hargaJual, hargaBeli?, tanggalBeli, catatan?, createdBy?, createdAt, updatedAt, deletedAt?})` + `copyWith` + `fromJson/toJson`
  - `Payment({id, customerId, jumlah, tanggalBayar, metode, catatan?, sumber, statusVerifikasi, buktiFotoUrl?, createdBy?, createdAt, updatedAt, deletedAt?})` + `copyWith` + `fromJson/toJson`. Default: `metode='tunai'`, `sumber='admin'`, `statusVerifikasi='verified'`.
  - `BudgetEntry({id, tanggal, namaTransaksi, tipe, jumlah, catatan?, createdBy?, createdAt, updatedAt, deletedAt?})` + `copyWith` + `fromJson/toJson`. `tipe` ∈ {'pemasukan','pengeluaran'}.
  - JSON: snake_case sesuai kolom SQL; `tanggal_beli/tanggal_bayar/tanggal` format 'yyyy-MM-dd' via `dateOnly`; timestamps ISO8601 UTC.

- [ ] **Step 1: Tulis test gagal — `test/data/models/models_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/data/models/customer.dart';
import 'package:sandiapp/data/models/purchase.dart';
import 'package:sandiapp/data/models/payment.dart';
import 'package:sandiapp/data/models/budget_entry.dart';

void main() {
  final now = DateTime.utc(2026, 8, 8, 10);

  test('Customer json roundtrip', () {
    final c = Customer(
      id: 'c1', nama: 'WIWIK', noHp: '0812', isArchived: false,
      createdAt: now, updatedAt: now,
    );
    final back = Customer.fromJson(c.toJson());
    expect(back.id, 'c1');
    expect(back.nama, 'WIWIK');
    expect(back.noHp, '0812');
    expect(back.isArchived, false);
    expect(back.deletedAt, isNull);
  });

  test('Purchase json roundtrip, tanggal date-only', () {
    final p = Purchase(
      id: 'p1', customerId: 'c1', namaBarang: 'HP', hargaJual: 2050000,
      hargaBeli: 1700000, tanggalBeli: DateTime(2020, 12, 30),
      createdAt: now, updatedAt: now,
    );
    final j = p.toJson();
    expect(j['tanggal_beli'], '2020-12-30');
    final back = Purchase.fromJson(j);
    expect(back.hargaJual, 2050000);
    expect(back.hargaBeli, 1700000);
    expect(back.tanggalBeli, DateTime(2020, 12, 30));
  });

  test('Payment default metode/sumber/statusVerifikasi', () {
    final pm = Payment(
      id: 'm1', customerId: 'c1', jumlah: 300000,
      tanggalBayar: DateTime(2021, 1, 30), createdAt: now, updatedAt: now,
    );
    expect(pm.metode, 'tunai');
    expect(pm.sumber, 'admin');
    expect(pm.statusVerifikasi, 'verified');
    expect(Payment.fromJson(pm.toJson()).jumlah, 300000);
  });

  test('BudgetEntry json roundtrip', () {
    final b = BudgetEntry(
      id: 'b1', tanggal: DateTime(2021, 4, 27), namaTransaksi: 'Belanja',
      tipe: 'pengeluaran', jumlah: 160000, createdAt: now, updatedAt: now,
    );
    final back = BudgetEntry.fromJson(b.toJson());
    expect(back.tipe, 'pengeluaran');
    expect(back.jumlah, 160000);
  });

  test('CustomerWithBalance.sisa', () {
    final c = Customer(id: 'c1', nama: 'A', createdAt: now, updatedAt: now);
    final wb = CustomerWithBalance(customer: c, totalHutang: 6500000, totalBayar: 5300000);
    expect(wb.sisa, 1200000);
  });

  test('copyWith mengubah field', () {
    final c = Customer(id: 'c1', nama: 'A', createdAt: now, updatedAt: now);
    final c2 = c.copyWith(nama: 'B', isArchived: true);
    expect(c2.nama, 'B');
    expect(c2.isArchived, true);
    expect(c2.id, 'c1');
  });
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

```bash
flutter test test/data/models/models_test.dart
```

Expected: FAIL — URI tidak ada.

- [ ] **Step 3: Implementasi keempat model**

`lib/data/models/customer.dart`:

```dart
class Customer {
  final String id;
  final String nama;
  final String? noHp, alamat, catatan, authUserId, createdBy;
  final bool isArchived;
  final DateTime createdAt, updatedAt;
  final DateTime? deletedAt;

  const Customer({
    required this.id,
    required this.nama,
    this.noHp,
    this.alamat,
    this.catatan,
    this.isArchived = false,
    this.authUserId,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        id: j['id'] as String,
        nama: j['nama'] as String,
        noHp: j['no_hp'] as String?,
        alamat: j['alamat'] as String?,
        catatan: j['catatan'] as String?,
        isArchived: j['is_archived'] as bool? ?? false,
        authUserId: j['auth_user_id'] as String?,
        createdBy: j['created_by'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
        deletedAt: j['deleted_at'] == null ? null : DateTime.parse(j['deleted_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'no_hp': noHp,
        'alamat': alamat,
        'catatan': catatan,
        'is_archived': isArchived,
        'auth_user_id': authUserId,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  Customer copyWith({
    String? nama, String? noHp, String? alamat, String? catatan,
    bool? isArchived, String? createdBy, DateTime? updatedAt, DateTime? deletedAt,
  }) =>
      Customer(
        id: id,
        nama: nama ?? this.nama,
        noHp: noHp ?? this.noHp,
        alamat: alamat ?? this.alamat,
        catatan: catatan ?? this.catatan,
        isArchived: isArchived ?? this.isArchived,
        authUserId: authUserId,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );
}

class CustomerWithBalance {
  final Customer customer;
  final int totalHutang, totalBayar;
  const CustomerWithBalance({
    required this.customer,
    required this.totalHutang,
    required this.totalBayar,
  });
  int get sisa => totalHutang - totalBayar;
}
```

`lib/data/models/purchase.dart`:

```dart
import '../../core/utils/dates.dart';

class Purchase {
  final String id, customerId, namaBarang;
  final int hargaJual;
  final int? hargaBeli;
  final DateTime tanggalBeli; // date-only
  final String? catatan, createdBy;
  final DateTime createdAt, updatedAt;
  final DateTime? deletedAt;

  const Purchase({
    required this.id,
    required this.customerId,
    required this.namaBarang,
    required this.hargaJual,
    this.hargaBeli,
    required this.tanggalBeli,
    this.catatan,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Purchase.fromJson(Map<String, dynamic> j) => Purchase(
        id: j['id'] as String,
        customerId: j['customer_id'] as String,
        namaBarang: j['nama_barang'] as String,
        hargaJual: (j['harga_jual'] as num).toInt(),
        hargaBeli: (j['harga_beli'] as num?)?.toInt(),
        tanggalBeli: DateTime.parse(j['tanggal_beli'] as String),
        catatan: j['catatan'] as String?,
        createdBy: j['created_by'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
        deletedAt: j['deleted_at'] == null ? null : DateTime.parse(j['deleted_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'nama_barang': namaBarang,
        'harga_jual': hargaJual,
        'harga_beli': hargaBeli,
        'tanggal_beli': dateOnly(tanggalBeli),
        'catatan': catatan,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  Purchase copyWith({
    String? namaBarang, int? hargaJual, int? Function()? hargaBeli,
    DateTime? tanggalBeli, String? catatan, String? createdBy,
    DateTime? updatedAt, DateTime? deletedAt,
  }) =>
      Purchase(
        id: id,
        customerId: customerId,
        namaBarang: namaBarang ?? this.namaBarang,
        hargaJual: hargaJual ?? this.hargaJual,
        hargaBeli: hargaBeli != null ? hargaBeli() : this.hargaBeli,
        tanggalBeli: tanggalBeli ?? this.tanggalBeli,
        catatan: catatan ?? this.catatan,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );
}
```

`lib/data/models/payment.dart`:

```dart
import '../../core/utils/dates.dart';

class Payment {
  final String id, customerId;
  final int jumlah;
  final DateTime tanggalBayar; // date-only
  final String metode; // 'tunai' | 'transfer' | 'lainnya'
  final String? catatan, buktiFotoUrl, createdBy;
  final String sumber; // 'admin' | 'client' (client = masa depan)
  final String statusVerifikasi; // 'pending' | 'verified' | 'rejected'
  final DateTime createdAt, updatedAt;
  final DateTime? deletedAt;

  const Payment({
    required this.id,
    required this.customerId,
    required this.jumlah,
    required this.tanggalBayar,
    this.metode = 'tunai',
    this.catatan,
    this.sumber = 'admin',
    this.statusVerifikasi = 'verified',
    this.buktiFotoUrl,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        id: j['id'] as String,
        customerId: j['customer_id'] as String,
        jumlah: (j['jumlah'] as num).toInt(),
        tanggalBayar: DateTime.parse(j['tanggal_bayar'] as String),
        metode: j['metode'] as String? ?? 'tunai',
        catatan: j['catatan'] as String?,
        sumber: j['sumber'] as String? ?? 'admin',
        statusVerifikasi: j['status_verifikasi'] as String? ?? 'verified',
        buktiFotoUrl: j['bukti_foto_url'] as String?,
        createdBy: j['created_by'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
        deletedAt: j['deleted_at'] == null ? null : DateTime.parse(j['deleted_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'jumlah': jumlah,
        'tanggal_bayar': dateOnly(tanggalBayar),
        'metode': metode,
        'catatan': catatan,
        'sumber': sumber,
        'status_verifikasi': statusVerifikasi,
        'bukti_foto_url': buktiFotoUrl,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  Payment copyWith({
    int? jumlah, DateTime? tanggalBayar, String? metode, String? catatan,
    String? statusVerifikasi, String? createdBy, DateTime? updatedAt, DateTime? deletedAt,
  }) =>
      Payment(
        id: id,
        customerId: customerId,
        jumlah: jumlah ?? this.jumlah,
        tanggalBayar: tanggalBayar ?? this.tanggalBayar,
        metode: metode ?? this.metode,
        catatan: catatan ?? this.catatan,
        sumber: sumber,
        statusVerifikasi: statusVerifikasi ?? this.statusVerifikasi,
        buktiFotoUrl: buktiFotoUrl,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );
}
```

`lib/data/models/budget_entry.dart`:

```dart
import '../../core/utils/dates.dart';

class BudgetEntry {
  final String id;
  final DateTime tanggal; // date-only
  final String namaTransaksi;
  final String tipe; // 'pemasukan' | 'pengeluaran'
  final int jumlah;
  final String? catatan, createdBy;
  final DateTime createdAt, updatedAt;
  final DateTime? deletedAt;

  const BudgetEntry({
    required this.id,
    required this.tanggal,
    required this.namaTransaksi,
    required this.tipe,
    required this.jumlah,
    this.catatan,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory BudgetEntry.fromJson(Map<String, dynamic> j) => BudgetEntry(
        id: j['id'] as String,
        tanggal: DateTime.parse(j['tanggal'] as String),
        namaTransaksi: j['nama_transaksi'] as String,
        tipe: j['tipe'] as String,
        jumlah: (j['jumlah'] as num).toInt(),
        catatan: j['catatan'] as String?,
        createdBy: j['created_by'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
        deletedAt: j['deleted_at'] == null ? null : DateTime.parse(j['deleted_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tanggal': dateOnly(tanggal),
        'nama_transaksi': namaTransaksi,
        'tipe': tipe,
        'jumlah': jumlah,
        'catatan': catatan,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  BudgetEntry copyWith({
    DateTime? tanggal, String? namaTransaksi, String? tipe, int? jumlah,
    String? catatan, String? createdBy, DateTime? updatedAt, DateTime? deletedAt,
  }) =>
      BudgetEntry(
        id: id,
        tanggal: tanggal ?? this.tanggal,
        namaTransaksi: namaTransaksi ?? this.namaTransaksi,
        tipe: tipe ?? this.tipe,
        jumlah: jumlah ?? this.jumlah,
        catatan: catatan ?? this.catatan,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );
}
```

- [ ] **Step 4: Jalankan, pastikan pass**

```bash
flutter test test/data/models/models_test.dart
```

Expected: 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/data/models lib/core/utils/dates.dart test/data/models && git commit -m "feat: model domain + serialisasi JSON"
```

---

### Task 5: Logika FIFO & saldo (TDD) — INTI BISNIS

**Files:**
- Create: `lib/core/logic/fifo.dart`
- Test: `test/core/logic/fifo_test.dart`

**Interfaces:**
- Consumes: `Purchase`, `Payment` (Task 4).
- Produces:
  - `enum ItemStatus { lunas, sebagian, belum }`
  - `class PurchaseStatus { Purchase purchase; int allocated; int get sisa; ItemStatus get status; }`
  - `class Balance { int totalHutang, totalBayar; int get sisa; }`
  - `Balance balanceOf(List<Purchase>, List<Payment>)` — hanya payment `statusVerifikasi == 'verified'`.
  - `List<PurchaseStatus> allocateFifo(List<Purchase>, int totalBayar)` — urut `(tanggalBeli, createdAt)`; tiap barang dialokasikan sebagian/penuh sampai totalBayar habis.

- [ ] **Step 1: Tulis test gagal — `test/core/logic/fifo_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/core/logic/fifo.dart';
import 'package:sandiapp/data/models/purchase.dart';
import 'package:sandiapp/data/models/payment.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1);

  Purchase p(String id, int harga, DateTime beli, {DateTime? created}) => Purchase(
      id: id, customerId: 'c1', namaBarang: id, hargaJual: harga,
      tanggalBeli: beli, createdAt: created ?? t0, updatedAt: t0);

  Payment pm(int jumlah, {String status = 'verified'}) => Payment(
      id: 'm$jumlah', customerId: 'c1', jumlah: jumlah, tanggalBayar: t0,
      statusVerifikasi: status, createdAt: t0, updatedAt: t0);

  group('balanceOf', () {
    test('total hutang, bayar, sisa', () {
      final b = balanceOf([p('a', 5000000, t0), p('b', 300000, t0)], [pm(2000000)]);
      expect(b.totalHutang, 5300000);
      expect(b.totalBayar, 2000000);
      expect(b.sisa, 3300000);
    });
    test('payment pending/rejected tidak dihitung', () {
      final b = balanceOf([p('a', 1000, t0)],
          [pm(500, status: 'pending'), pm(300, status: 'rejected'), pm(200)]);
      expect(b.totalBayar, 200);
    });
  });

  group('allocateFifo', () {
    test('contoh handoff: 5jt + 300rb + 1.2jt, bayar 5.3jt', () {
      final res = allocateFifo(
          [p('hp', 5000000, DateTime(2026, 1, 1)),
           p('cooker', 300000, DateTime(2026, 2, 1)),
           p('kulkas', 1200000, DateTime(2026, 3, 1))],
          5300000);
      expect(res[0].status, ItemStatus.lunas);
      expect(res[1].status, ItemStatus.lunas);
      expect(res[2].status, ItemStatus.belum);
      expect(res[2].sisa, 1200000);
    });
    test('sebagian: bayar 5.1jt', () {
      final res = allocateFifo(
          [p('a', 5000000, DateTime(2026, 1, 1)), p('b', 300000, DateTime(2026, 2, 1))],
          5100000);
      expect(res[0].status, ItemStatus.lunas);
      expect(res[1].status, ItemStatus.sebagian);
      expect(res[1].allocated, 100000);
      expect(res[1].sisa, 200000);
    });
    test('urut by tanggalBeli lalu createdAt; kelebihan bayar aman', () {
      final res = allocateFifo(
          [p('baru', 1000, DateTime(2026, 5, 1)), p('lama', 1000, DateTime(2026, 1, 1))],
          5000);
      expect(res[0].purchase.id, 'lama'); // tertua dulu
      expect(res.every((r) => r.status == ItemStatus.lunas), true);
    });
    test('tanpa pembayaran: semua belum', () {
      final res = allocateFifo([p('a', 1000, t0)], 0);
      expect(res.single.status, ItemStatus.belum);
    });
  });
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

```bash
flutter test test/core/logic/fifo_test.dart
```

Expected: FAIL — URI tidak ada.

- [ ] **Step 3: Implementasi `lib/core/logic/fifo.dart`**

```dart
import '../../data/models/payment.dart';
import '../../data/models/purchase.dart';

enum ItemStatus { lunas, sebagian, belum }

class PurchaseStatus {
  final Purchase purchase;
  final int allocated; // bagian total bayar yang meng-cover barang ini (FIFO)
  const PurchaseStatus({required this.purchase, required this.allocated});

  int get sisa => purchase.hargaJual - allocated;
  ItemStatus get status {
    if (allocated <= 0) return ItemStatus.belum;
    if (allocated >= purchase.hargaJual) return ItemStatus.lunas;
    return ItemStatus.sebagian;
  }
}

class Balance {
  final int totalHutang, totalBayar;
  const Balance(this.totalHutang, this.totalBayar);
  int get sisa => totalHutang - totalBayar;
}

/// Total hutang & bayar satu customer. Hanya payment 'verified' yang dihitung.
Balance balanceOf(List<Purchase> purchases, List<Payment> payments) {
  final hutang = purchases.fold<int>(0, (s, p) => s + p.hargaJual);
  final bayar = payments
      .where((p) => p.statusVerifikasi == 'verified')
      .fold<int>(0, (s, p) => s + p.jumlah);
  return Balance(hutang, bayar);
}

/// Alokasi totalBayar ke barang tertua dulu (FIFO). Hasil urut tertua -> termuda.
List<PurchaseStatus> allocateFifo(List<Purchase> purchases, int totalBayar) {
  final sorted = [...purchases]..sort((a, b) {
      final c = a.tanggalBeli.compareTo(b.tanggalBeli);
      return c != 0 ? c : a.createdAt.compareTo(b.createdAt);
    });
  var remaining = totalBayar;
  return [
    for (final p in sorted)
      () {
        final alloc = remaining <= 0
            ? 0
            : (remaining >= p.hargaJual ? p.hargaJual : remaining);
        remaining -= alloc;
        return PurchaseStatus(purchase: p, allocated: alloc);
      }()
  ];
}
```

- [ ] **Step 4: Jalankan, pastikan pass**

```bash
flutter test test/core/logic/fifo_test.dart
```

Expected: 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/core/logic test/core/logic && git commit -m "feat: logika running balance + alokasi FIFO"
```

---

### Task 6: Logika anggaran belanja (TDD)

**Files:**
- Create: `lib/core/logic/budget.dart`
- Test: `test/core/logic/budget_test.dart`

**Interfaces:**
- Consumes: `BudgetEntry` (Task 4).
- Produces: `class BudgetLine { BudgetEntry entry; int saldo; }`, `List<BudgetLine> withRunningSaldo(List<BudgetEntry>, {int saldoAwal = 0})` — urut `(tanggal, createdAt)`, pemasukan menambah, pengeluaran mengurangi.

- [ ] **Step 1: Tulis test gagal — `test/core/logic/budget_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/core/logic/budget.dart';
import 'package:sandiapp/data/models/budget_entry.dart';

void main() {
  final t0 = DateTime.utc(2021, 4, 27, 8);

  BudgetEntry e(String id, String tipe, int jumlah, DateTime tgl, DateTime created) =>
      BudgetEntry(id: id, tanggal: tgl, namaTransaksi: id, tipe: tipe,
          jumlah: jumlah, createdAt: created, updatedAt: created);

  test('saldo berjalan sesuai Sheet3 Excel', () {
    final lines = withRunningSaldo([
      e('a', 'pemasukan', 5000000, DateTime(2021, 4, 27), t0),
      e('b', 'pengeluaran', 160000, DateTime(2021, 4, 27), t0.add(const Duration(minutes: 1))),
      e('c', 'pengeluaran', 100000, DateTime(2021, 4, 27), t0.add(const Duration(minutes: 2))),
    ]);
    expect(lines.map((l) => l.saldo), [5000000, 4840000, 4740000]);
  });

  test('urut by tanggal lalu createdAt, saldoAwal diperhitungkan', () {
    final lines = withRunningSaldo([
      e('nanti', 'pemasukan', 1000, DateTime(2021, 5, 1), t0),
      e('dulu', 'pemasukan', 2000, DateTime(2021, 4, 1), t0),
    ], saldoAwal: 100);
    expect(lines.first.entry.id, 'dulu');
    expect(lines.map((l) => l.saldo), [2100, 3100]);
  });
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

```bash
flutter test test/core/logic/budget_test.dart
```

Expected: FAIL — URI tidak ada.

- [ ] **Step 3: Implementasi `lib/core/logic/budget.dart`**

```dart
import '../../data/models/budget_entry.dart';

class BudgetLine {
  final BudgetEntry entry;
  final int saldo; // saldo setelah entri ini
  const BudgetLine({required this.entry, required this.saldo});
}

/// Saldo berjalan, urut (tanggal, createdAt). pemasukan +, pengeluaran -.
List<BudgetLine> withRunningSaldo(List<BudgetEntry> entries, {int saldoAwal = 0}) {
  final sorted = [...entries]..sort((a, b) {
      final c = a.tanggal.compareTo(b.tanggal);
      return c != 0 ? c : a.createdAt.compareTo(b.createdAt);
    });
  var saldo = saldoAwal;
  return [
    for (final e in sorted)
      BudgetLine(
          entry: e,
          saldo: saldo += e.tipe == 'pemasukan' ? e.jumlah : -e.jumlah),
  ];
}
```

- [ ] **Step 4: Jalankan, pastikan pass**

```bash
flutter test test/core/logic/budget_test.dart
```

Expected: 2 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/core/logic/budget.dart test/core/logic/budget_test.dart && git commit -m "feat: logika saldo berjalan anggaran belanja"
```

---

### Task 7: Logika laporan keuntungan (TDD)

**Files:**
- Create: `lib/core/logic/profit.dart`
- Test: `test/core/logic/profit_test.dart`

**Interfaces:**
- Consumes: `Purchase` (Task 4).
- Produces:
  - `class ProfitRow { int year, month, qty, penjualan, modal; int get keuntungan; }` (`month == 0` = baris tahunan)
  - `List<ProfitRow> profitPerMonth(List<Purchase>, int year)` — hanya `hargaBeli != null`, grup by bulan `tanggalBeli`, urut bulan.
  - `List<ProfitRow> profitPerYear(List<Purchase>)` — grup by tahun, urut tahun.

- [ ] **Step 1: Tulis test gagal — `test/core/logic/profit_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/core/logic/profit.dart';
import 'package:sandiapp/data/models/purchase.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1);

  Purchase p(int jual, int? beli, DateTime tgl) => Purchase(
      id: '$tgl-$jual', customerId: 'c1', namaBarang: 'x', hargaJual: jual,
      hargaBeli: beli, tanggalBeli: tgl, createdAt: t0, updatedAt: t0);

  final data = [
    p(2050000, 1700000, DateTime(2020, 12, 30)),
    p(5000000, 3000000, DateTime(2020, 12, 28)),
    p(2100000, 1750000, DateTime(2021, 1, 8)),
    p(1000000, null, DateTime(2021, 1, 20)), // tanpa harga beli: dikecualikan
  ];

  test('profitPerYear: grup + hitung, skip hargaBeli null', () {
    final rows = profitPerYear(data);
    expect(rows.length, 2);
    expect(rows[0].year, 2020);
    expect(rows[0].qty, 2);
    expect(rows[0].penjualan, 7050000);
    expect(rows[0].modal, 4700000);
    expect(rows[0].keuntungan, 2350000);
    expect(rows[1].year, 2021);
    expect(rows[1].qty, 1);
  });

  test('profitPerMonth: filter tahun, grup per bulan', () {
    final rows = profitPerMonth(data, 2020);
    expect(rows.single.month, 12);
    expect(rows.single.keuntungan, 2350000);
    expect(profitPerMonth(data, 2022), isEmpty);
  });
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

```bash
flutter test test/core/logic/profit_test.dart
```

Expected: FAIL — URI tidak ada.

- [ ] **Step 3: Implementasi `lib/core/logic/profit.dart`**

```dart
import '../../data/models/purchase.dart';

class ProfitRow {
  final int year, month; // month == 0 -> baris agregat tahunan
  final int qty, penjualan, modal;
  const ProfitRow({
    required this.year,
    required this.month,
    required this.qty,
    required this.penjualan,
    required this.modal,
  });
  int get keuntungan => penjualan - modal;
}

ProfitRow _aggregate(int year, int month, List<Purchase> items) => ProfitRow(
      year: year,
      month: month,
      qty: items.length,
      penjualan: items.fold(0, (s, p) => s + p.hargaJual),
      modal: items.fold(0, (s, p) => s + (p.hargaBeli ?? 0)),
    );

/// Keuntungan per bulan dalam [year]. Purchase tanpa hargaBeli dikecualikan.
List<ProfitRow> profitPerMonth(List<Purchase> purchases, int year) {
  final byMonth = <int, List<Purchase>>{};
  for (final p in purchases.where(
      (p) => p.hargaBeli != null && p.tanggalBeli.year == year)) {
    byMonth.putIfAbsent(p.tanggalBeli.month, () => []).add(p);
  }
  return [
    for (final m in byMonth.keys.toList()..sort()) _aggregate(year, m, byMonth[m]!),
  ];
}

/// Keuntungan per tahun (semua tahun yang ada datanya).
List<ProfitRow> profitPerYear(List<Purchase> purchases) {
  final byYear = <int, List<Purchase>>{};
  for (final p in purchases.where((p) => p.hargaBeli != null)) {
    byYear.putIfAbsent(p.tanggalBeli.year, () => []).add(p);
  }
  return [
    for (final y in byYear.keys.toList()..sort()) _aggregate(y, 0, byYear[y]!),
  ];
}
```

- [ ] **Step 4: Jalankan, pastikan pass**

```bash
flutter test test/core/logic/profit_test.dart
```

Expected: 2 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/core/logic/profit.dart test/core/logic/profit_test.dart && git commit -m "feat: logika rekap keuntungan bulanan/tahunan"
```

---

### Task 8: Database lokal drift (SQLite) — Android offline-first

**Files:**
- Create: `lib/data/local/app_database.dart`
- Test: `test/data/local/app_database_test.dart`

**Interfaces:**
- Consumes: models Task 4.
- Produces (dipakai Task 9-11, 14):
  - `class AppDatabase` — konstruktor `AppDatabase()` (file `sandiapp.sqlite` via drift_flutter) dan `AppDatabase.memory()` (test).
  - Tabel: `Customers, Purchases, Payments, BudgetEntries` → row class `CustomerRow, PurchaseRow, PaymentRow, BudgetEntryRow` (via `@DataClassName`). Semua tabel punya kolom snake_case drift (camelCase di Dart) + `isDirty bool default false`.
  - Method per tabel (contoh customers; 3 lainnya analog): `activeCustomers()`, `upsertCustomerRow(CustomersCompanion)`, `dirtyCustomerRows()`, `clearCustomersDirty(List<String>)`, `applyRemoteCustomers(List<Customer>)`.
  - `Future<int> dirtyCount()`.
  - Mapper extension: `CustomerRow.toModel()`, `Customer.toCompanion({required bool dirty})` (juga untuk 3 tabel lain).

- [ ] **Step 1: Tulis test gagal — `test/data/local/app_database_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/data/local/app_database.dart';
import 'package:sandiapp/data/models/customer.dart';
import 'package:sandiapp/data/models/payment.dart';

void main() {
  late AppDatabase db;
  final t0 = DateTime.utc(2026, 8, 8, 10);

  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  test('upsert + baca aktif + dirty flag', () async {
    final c = Customer(id: 'c1', nama: 'WIWIK', createdAt: t0, updatedAt: t0);
    await db.upsertCustomerRow(c.toCompanion(dirty: true));
    expect((await db.activeCustomers()).single.nama, 'WIWIK');
    expect((await db.dirtyCustomerRows()).single.id, 'c1');
    expect(await db.dirtyCount(), 1);

    await db.clearCustomersDirty(['c1']);
    expect(await db.dirtyCount(), 0);
  });

  test('soft delete menghilangkan dari activeCustomers tapi tetap bisa di-push', () async {
    final c = Customer(id: 'c1', nama: 'A', createdAt: t0, updatedAt: t0,
        deletedAt: t0.add(const Duration(days: 1)));
    await db.upsertCustomerRow(c.toCompanion(dirty: true));
    expect(await db.activeCustomers(), isEmpty);
    expect((await db.dirtyCustomerRows()).single.deletedAt, isNotNull);
  });

  test('applyRemote menulis tanpa dirty', () async {
    await db.applyRemotePayments([
      Payment(id: 'm1', customerId: 'c1', jumlah: 50000,
          tanggalBayar: DateTime(2026, 8, 1), createdAt: t0, updatedAt: t0),
    ]);
    expect((await db.activePayments()).single.jumlah, 50000);
    expect(await db.dirtyCount(), 0);
  });
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

```bash
flutter test test/data/local/app_database_test.dart
```

Expected: FAIL — URI tidak ada.

- [ ] **Step 3: Implementasi `lib/data/local/app_database.dart`**

```dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:drift/native.dart';

import '../models/budget_entry.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../models/purchase.dart';

part 'app_database.g.dart';

@DataClassName('CustomerRow')
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get nama => text()();
  TextColumn get noHp => text().nullable()();
  TextColumn get alamat => text().nullable()();
  TextColumn get catatan => text().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get authUserId => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PurchaseRow')
class Purchases extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text()();
  TextColumn get namaBarang => text()();
  Int64Column get hargaJual => int64()();
  Int64Column get hargaBeli => int64().nullable()();
  DateTimeColumn get tanggalBeli => dateTime()();
  TextColumn get catatan => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PaymentRow')
class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text()();
  Int64Column get jumlah => int64()();
  DateTimeColumn get tanggalBayar => dateTime()();
  TextColumn get metode => text().withDefault(const Constant('tunai'))();
  TextColumn get catatan => text().nullable()();
  TextColumn get sumber => text().withDefault(const Constant('admin'))();
  TextColumn get statusVerifikasi => text().withDefault(const Constant('verified'))();
  TextColumn get buktiFotoUrl => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BudgetEntryRow')
class BudgetEntries extends Table {
  TextColumn get id => text()();
  DateTimeColumn get tanggal => dateTime()();
  TextColumn get namaTransaksi => text()();
  TextColumn get tipe => text()();
  Int64Column get jumlah => int64()();
  TextColumn get catatan => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Customers, Purchases, Payments, BudgetEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'sandiapp'));
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  // ---- customers ----
  Future<List<CustomerRow>> activeCustomers() =>
      (select(customers)..where((t) => t.deletedAt.isNull())).get();
  Future<void> upsertCustomerRow(CustomersCompanion c) =>
      into(customers).insertOnConflictUpdate(c);
  Future<List<CustomerRow>> dirtyCustomerRows() =>
      (select(customers)..where((t) => t.isDirty)).get();
  Future<void> clearCustomersDirty(List<String> ids) =>
      (update(customers)..where((t) => t.id.isIn(ids)))
          .write(const CustomersCompanion(isDirty: Value(false)));
  Future<void> applyRemoteCustomers(List<Customer> items) async =>
      batch((b) => b.insertAllOnConflictUpdate(
          customers, [for (final c in items) c.toCompanion(dirty: false)]));

  // ---- purchases ----
  Future<List<PurchaseRow>> activePurchases() =>
      (select(purchases)..where((t) => t.deletedAt.isNull())).get();
  Future<void> upsertPurchaseRow(PurchasesCompanion c) =>
      into(purchases).insertOnConflictUpdate(c);
  Future<List<PurchaseRow>> dirtyPurchaseRows() =>
      (select(purchases)..where((t) => t.isDirty)).get();
  Future<void> clearPurchasesDirty(List<String> ids) =>
      (update(purchases)..where((t) => t.id.isIn(ids)))
          .write(const PurchasesCompanion(isDirty: Value(false)));
  Future<void> applyRemotePurchases(List<Purchase> items) async =>
      batch((b) => b.insertAllOnConflictUpdate(
          purchases, [for (final p in items) p.toCompanion(dirty: false)]));

  // ---- payments ----
  Future<List<PaymentRow>> activePayments() =>
      (select(payments)..where((t) => t.deletedAt.isNull())).get();
  Future<void> upsertPaymentRow(PaymentsCompanion c) =>
      into(payments).insertOnConflictUpdate(c);
  Future<List<PaymentRow>> dirtyPaymentRows() =>
      (select(payments)..where((t) => t.isDirty)).get();
  Future<void> clearPaymentsDirty(List<String> ids) =>
      (update(payments)..where((t) => t.id.isIn(ids)))
          .write(const PaymentsCompanion(isDirty: Value(false)));
  Future<void> applyRemotePayments(List<Payment> items) async =>
      batch((b) => b.insertAllOnConflictUpdate(
          payments, [for (final p in items) p.toCompanion(dirty: false)]));

  // ---- budget_entries ----
  Future<List<BudgetEntryRow>> activeBudgetEntries() =>
      (select(budgetEntries)..where((t) => t.deletedAt.isNull())).get();
  Future<void> upsertBudgetEntryRow(BudgetEntriesCompanion c) =>
      into(budgetEntries).insertOnConflictUpdate(c);
  Future<List<BudgetEntryRow>> dirtyBudgetEntryRows() =>
      (select(budgetEntries)..where((t) => t.isDirty)).get();
  Future<void> clearBudgetEntriesDirty(List<String> ids) =>
      (update(budgetEntries)..where((t) => t.id.isIn(ids)))
          .write(const BudgetEntriesCompanion(isDirty: Value(false)));
  Future<void> applyRemoteBudgetEntries(List<BudgetEntry> items) async =>
      batch((b) => b.insertAllOnConflictUpdate(
          budgetEntries, [for (final e in items) e.toCompanion(dirty: false)]));

  Future<int> dirtyCount() async {
    int count(String table) async =>
        (await customSelect('SELECT COUNT(*) AS c FROM $table WHERE is_dirty = 1')
                .getSingle())
            .data['c'] as int;
    return await count('customers') +
        await count('purchases') +
        await count('payments') +
        await count('budget_entries');
  }
}

// ---- mapper row <-> model ----
extension CustomerRowX on CustomerRow {
  Customer toModel() => Customer(
      id: id, nama: nama, noHp: noHp, alamat: alamat, catatan: catatan,
      isArchived: isArchived, authUserId: authUserId, createdBy: createdBy,
      createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt);
}

extension CustomerX on Customer {
  CustomersCompanion toCompanion({required bool dirty}) => CustomersCompanion(
      id: Value(id), nama: Value(nama), noHp: Value(noHp), alamat: Value(alamat),
      catatan: Value(catatan), isArchived: Value(isArchived),
      authUserId: Value(authUserId), createdBy: Value(createdBy),
      createdAt: Value(createdAt), updatedAt: Value(updatedAt),
      deletedAt: Value(deletedAt), isDirty: Value(dirty));
}

extension PurchaseRowX on PurchaseRow {
  Purchase toModel() => Purchase(
      id: id, customerId: customerId, namaBarang: namaBarang, hargaJual: hargaJual,
      hargaBeli: hargaBeli, tanggalBeli: tanggalBeli, catatan: catatan,
      createdBy: createdBy, createdAt: createdAt, updatedAt: updatedAt,
      deletedAt: deletedAt);
}

extension PurchaseX on Purchase {
  PurchasesCompanion toCompanion({required bool dirty}) => PurchasesCompanion(
      id: Value(id), customerId: Value(customerId), namaBarang: Value(namaBarang),
      hargaJual: Value(hargaJual), hargaBeli: Value(hargaBeli),
      tanggalBeli: Value(tanggalBeli), catatan: Value(catatan),
      createdBy: Value(createdBy), createdAt: Value(createdAt),
      updatedAt: Value(updatedAt), deletedAt: Value(deletedAt),
      isDirty: Value(dirty));
}

extension PaymentRowX on PaymentRow {
  Payment toModel() => Payment(
      id: id, customerId: customerId, jumlah: jumlah, tanggalBayar: tanggalBayar,
      metode: metode, catatan: catatan, sumber: sumber,
      statusVerifikasi: statusVerifikasi, buktiFotoUrl: buktiFotoUrl,
      createdBy: createdBy, createdAt: createdAt, updatedAt: updatedAt,
      deletedAt: deletedAt);
}

extension PaymentX on Payment {
  PaymentsCompanion toCompanion({required bool dirty}) => PaymentsCompanion(
      id: Value(id), customerId: Value(customerId), jumlah: Value(jumlah),
      tanggalBayar: Value(tanggalBayar), metode: Value(metode),
      catatan: Value(catatan), sumber: Value(sumber),
      statusVerifikasi: Value(statusVerifikasi), buktiFotoUrl: Value(buktiFotoUrl),
      createdBy: Value(createdBy), createdAt: Value(createdAt),
      updatedAt: Value(updatedAt), deletedAt: Value(deletedAt),
      isDirty: Value(dirty));
}

extension BudgetEntryRowX on BudgetEntryRow {
  BudgetEntry toModel() => BudgetEntry(
      id: id, tanggal: tanggal, namaTransaksi: namaTransaksi, tipe: tipe,
      jumlah: jumlah, catatan: catatan, createdBy: createdBy,
      createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt);
}

extension BudgetEntryX on BudgetEntry {
  BudgetEntriesCompanion toCompanion({required bool dirty}) =>
      BudgetEntriesCompanion(
          id: Value(id), tanggal: Value(tanggal),
          namaTransaksi: Value(namaTransaksi), tipe: Value(tipe),
          jumlah: Value(jumlah), catatan: Value(catatan),
          createdBy: Value(createdBy), createdAt: Value(createdAt),
          updatedAt: Value(updatedAt), deletedAt: Value(deletedAt),
          isDirty: Value(dirty));
}
```

- [ ] **Step 4: Codegen drift, lalu jalankan test**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/data/local/app_database_test.dart
```

Expected: codegen menghasilkan `lib/data/local/app_database.g.dart`; 3 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/data/local test/data/local && git commit -m "feat: database lokal drift (SQLite) + flag sync"
```

---

### Task 9: RemoteStore — interface + implementasi Supabase + Fake untuk test

**Files:**
- Create: `lib/data/remote/remote_store.dart`
- Create: `test/fakes/fake_remote_store.dart`

**Interfaces:**
- Produces:
  - `abstract class RemoteStore { Future<List<Map<String, dynamic>>> fetchSince(String table, DateTime? since); Future<void> upsert(String table, List<Map<String, dynamic>> rows); }` — `since == null` berarti ambil semua.
  - `class SupabaseRemoteStore implements RemoteStore` — konstruktor menerima `SupabaseClient`.
  - `class FakeRemoteStore implements RemoteStore` (test) — penyimpanan in-memory; `upsert` mensimulasikan trigger server dengan men-set `updated_at = clock()`; punya `int upsertCalls` untuk asersi.

- [ ] **Step 1: Implementasi (tidak ada test terpisah; diuji lewat Task 10)**

`lib/data/remote/remote_store.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Akses generik per tabel ke Supabase (json key = nama kolom).
abstract class RemoteStore {
  /// Ambil semua row (semua kolom), atau hanya yang updated_at > [since].
  Future<List<Map<String, dynamic>>> fetchSince(String table, DateTime? since);
  Future<void> upsert(String table, List<Map<String, dynamic>> rows);
}

class SupabaseRemoteStore implements RemoteStore {
  final SupabaseClient _client;
  SupabaseRemoteStore(this._client);

  @override
  Future<List<Map<String, dynamic>>> fetchSince(String table, DateTime? since) {
    var q = _client.from(table).select();
    if (since != null) q = q.gt('updated_at', since.toIso8601String());
    return q;
  }

  @override
  Future<void> upsert(String table, List<Map<String, dynamic>> rows) =>
      _client.from(table).upsert(rows);
}
```

`test/fakes/fake_remote_store.dart`:

```dart
import 'package:sandiapp/data/remote/remote_store.dart';

class FakeRemoteStore implements RemoteStore {
  final Map<String, Map<String, Map<String, dynamic>>> tables = {};
  int upsertCalls = 0;
  DateTime Function() clock = () => DateTime.now().toUtc();

  @override
  Future<List<Map<String, dynamic>>> fetchSince(String table, DateTime? since) async {
    final rows = (tables[table] ?? {}).values;
    if (since == null) return [for (final r in rows) Map<String, dynamic>.from(r)];
    return [
      for (final r in rows)
        if (DateTime.parse(r['updated_at'] as String).isAfter(since))
          Map<String, dynamic>.from(r),
    ];
  }

  @override
  Future<void> upsert(String table, List<Map<String, dynamic>> rows) async {
    upsertCalls++;
    final t = tables.putIfAbsent(table, () => {});
    for (final row in rows) {
      // simulasi trigger set_updated_at di server
      t[row['id'] as String] = {...row, 'updated_at': clock().toIso8601String()};
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/data/remote test/fakes && git commit -m "feat: RemoteStore (Supabase) + fake untuk test"
```

---

### Task 10: SyncStateStore + SyncEngine (TDD) — INTI OFFLINE SYNC

**Files:**
- Create: `lib/data/sync/sync_state.dart`
- Create: `lib/data/sync/sync_engine.dart`
- Test: `test/data/sync/sync_engine_test.dart`

**Interfaces:**
- Consumes: `AppDatabase` (Task 8), `RemoteStore` (Task 9), models (Task 4).
- Produces:
  - `class SyncStateStore { Future<DateTime?> lastPull(String table); Future<void> setLastPull(String table, DateTime t); }` — via shared_preferences, key `last_pull_<table>`.
  - `class SyncEngine { SyncEngine(AppDatabase, RemoteStore, SyncStateStore); Future<void> syncAll(); }` — per tabel: push dirty → pull `updated_at > lastPull` → simpan watermark waktu mulai pull. Kegagalan push melempar exception (flag dirty tetap → retrial trigger berikutnya).

- [ ] **Step 1: Tulis test gagal — `test/data/sync/sync_engine_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/data/local/app_database.dart';
import 'package:sandiapp/data/models/customer.dart';
import 'package:sandiapp/data/sync/sync_engine.dart';
import 'package:sandiapp/data/sync/sync_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fakes/fake_remote_store.dart';

void main() {
  late AppDatabase db;
  late FakeRemoteStore remote;
  late SyncEngine engine;
  final t0 = DateTime.utc(2026, 8, 8, 10);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.memory();
    remote = FakeRemoteStore();
    engine = SyncEngine(db, remote, SyncStateStore(await SharedPreferences.getInstance()));
  });
  tearDown(() => db.close());

  test('push: row dirty terkirim ke remote & flag dibersihkan', () async {
    await db.upsertCustomerRow(
        Customer(id: 'c1', nama: 'WIWIK', createdAt: t0, updatedAt: t0)
            .toCompanion(dirty: true));
    await engine.syncAll();
    expect(remote.tables['customers']!['c1']!['nama'], 'WIWIK');
    expect(await db.dirtyCount(), 0);
  });

  test('pull: perubahan remote masuk ke lokal tanpa dirty', () async {
    await engine.syncAll(); // watermark awal
    remote.clock = () => DateTime.now().toUtc().add(const Duration(seconds: 1));
    await remote.upsert('customers', [
      Customer(id: 'c9', nama: 'DARI SERVER', createdAt: t0, updatedAt: t0).toJson()
    ]);
    await engine.syncAll();
    expect((await db.activeCustomers()).single.nama, 'DARI SERVER');
    expect(await db.dirtyCount(), 0);
  });

  test('soft delete lokal ikut ter-push', () async {
    await db.upsertCustomerRow(Customer(
            id: 'c1', nama: 'A', createdAt: t0, updatedAt: t0,
            deletedAt: t0.add(const Duration(days: 1)))
        .toCompanion(dirty: true));
    await engine.syncAll();
    expect(remote.tables['customers']!['c1']!['deleted_at'], isNotNull);
  });

  test('pull kedua tidak mengambil ulang (watermark)', () async {
    await engine.syncAll();
    final calls = remote.upsertCalls;
    await engine.syncAll();
    expect(remote.upsertCalls, calls); // tidak ada dirty -> tidak ada push
  });
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

```bash
flutter test test/data/sync/sync_engine_test.dart
```

Expected: FAIL — URI tidak ada.

- [ ] **Step 3: Implementasi**

`lib/data/sync/sync_state.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';

/// Watermark pull per tabel (updated_at server terakhir yang sudah diambil).
class SyncStateStore {
  final SharedPreferences _prefs;
  SyncStateStore(this._prefs);

  Future<DateTime?> lastPull(String table) async {
    final s = _prefs.getString('last_pull_$table');
    return s == null ? null : DateTime.parse(s);
  }

  Future<void> setLastPull(String table, DateTime t) =>
      _prefs.setString('last_pull_$table', t.toIso8601String());
}
```

`lib/data/sync/sync_engine.dart`:

```dart
import '../local/app_database.dart';
import '../models/budget_entry.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../models/purchase.dart';
import '../remote/remote_store.dart';
import 'sync_state.dart';

/// Push dirty -> pull delta. Last-write-wins by updated_at server.
/// Push gagal -> exception, flag dirty tetap, dicoba lagi di trigger berikutnya.
class SyncEngine {
  final AppDatabase db;
  final RemoteStore remote;
  final SyncStateStore state;

  SyncEngine(this.db, this.remote, this.state);

  Future<void> syncAll() async {
    await _syncCustomers();
    await _syncPurchases();
    await _syncPayments();
    await _syncBudgetEntries();
  }

  Future<void> _syncCustomers() async {
    final dirty = await db.dirtyCustomerRows();
    if (dirty.isNotEmpty) {
      await remote.upsert('customers', [for (final r in dirty) r.toModel().toJson()]);
      await db.clearCustomersDirty([for (final r in dirty) r.id]);
    }
    await _pull('customers', (rows) => db.applyRemoteCustomers(
        [for (final j in rows) Customer.fromJson(j)]));
  }

  Future<void> _syncPurchases() async {
    final dirty = await db.dirtyPurchaseRows();
    if (dirty.isNotEmpty) {
      await remote.upsert('purchases', [for (final r in dirty) r.toModel().toJson()]);
      await db.clearPurchasesDirty([for (final r in dirty) r.id]);
    }
    await _pull('purchases', (rows) => db.applyRemotePurchases(
        [for (final j in rows) Purchase.fromJson(j)]));
  }

  Future<void> _syncPayments() async {
    final dirty = await db.dirtyPaymentRows();
    if (dirty.isNotEmpty) {
      await remote.upsert('payments', [for (final r in dirty) r.toModel().toJson()]);
      await db.clearPaymentsDirty([for (final r in dirty) r.id]);
    }
    await _pull('payments', (rows) => db.applyRemotePayments(
        [for (final j in rows) Payment.fromJson(j)]));
  }

  Future<void> _syncBudgetEntries() async {
    final dirty = await db.dirtyBudgetEntryRows();
    if (dirty.isNotEmpty) {
      await remote.upsert(
          'budget_entries', [for (final r in dirty) r.toModel().toJson()]);
      await db.clearBudgetEntriesDirty([for (final r in dirty) r.id]);
    }
    await _pull('budget_entries', (rows) => db.applyRemoteBudgetEntries(
        [for (final j in rows) BudgetEntry.fromJson(j)]));
  }

  Future<void> _pull(String table,
      Future<void> Function(List<Map<String, dynamic>>) apply) async {
    final since = await state.lastPull(table);
    final started = DateTime.now().toUtc();
    final rows = await remote.fetchSince(table, since);
    await apply(rows);
    await state.setLastPull(table, started);
  }
}
```

- [ ] **Step 4: Jalankan, pastikan pass**

```bash
flutter test test/data/sync/sync_engine_test.dart
```

Expected: 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/data/sync test/data/sync && git commit -m "feat: sync engine push/pull + watermark"
```

---

### Task 11: Backend + AppRepository (TDD)

**Files:**
- Create: `lib/data/repositories/backend.dart`, `lib/data/repositories/app_repository.dart`
- Create: `lib/data/local/drift_backend.dart`, `lib/data/remote/remote_backend.dart`
- Test: `test/data/repositories/app_repository_test.dart`, `test/fakes/fake_backend.dart`

**Interfaces:**
- Consumes: models (4), fifo/budget/profit logic (5-7), `AppDatabase` (8), `RemoteStore` (9).
- Produces:
  - `abstract class Backend` — `readCustomers/readPurchases/readPayments/readBudgetEntries()` (aktif saja), `writeCustomer/writePurchase/writePayment/writeBudgetEntry(model)`, `deleteCustomer/deletePurchase/deletePayment/deleteBudgetEntry(String id, DateTime at)` (soft).
  - `class DriftBackend implements Backend` — wrap `AppDatabase`; write → `toCompanion(dirty: true)`; delete → companion `deletedAt + updatedAt + isDirty`.
  - `class RemoteBackend implements Backend` — wrap `RemoteStore`; read filter `deleted_at is null` dilakukan di Dart (RemoteStore.fetchSince mengambil semua); write → upsert `toJson`; delete → upsert `{id, deleted_at, updated_at}`.
  - `class AppRepository` — konstruktor `AppRepository(Backend, {required String? Function() currentUserId, void Function()? onLocalWrite})`. Method:
    - `Future<List<CustomerWithBalance>> customers({String query = '', bool includeArchived = false, bool sortByHutang = false})`
    - `Future<CustomerDetailData> customerDetail(String customerId)` → `CustomerDetailData({Customer customer, List<PurchaseStatus> items, List<Payment> payments, Balance balance})` (payments urut terbaru dulu)
    - `Future<DashboardStats> dashboardStats()` → `DashboardStats({int totalPiutang, int bayarBulanIni, int customerBerhutang, List<CustomerWithBalance> topHutang})` (top 5 sisa > 0)
    - `Future<List<ProfitRow>> profitYearly()` / `Future<List<ProfitRow>> profitMonthly(int year)`
    - `Future<List<BudgetLine>> budgetMonth(int year, int month)` — saldoAwal = akumulasi semua entri sebelum bulan itu
    - `saveCustomer/savePurchase/savePayment/saveBudgetEntry(model)` — set `createdBy` bila null + `updatedAt = now UTC`, panggil `onLocalWrite` setelah sukses
    - `deleteCustomer/deletePurchase/deletePayment/deleteBudgetEntry(String id)`

- [ ] **Step 1: Tulis fakes + test gagal**

`test/fakes/fake_backend.dart`:

```dart
import 'package:sandiapp/data/models/budget_entry.dart';
import 'package:sandiapp/data/models/customer.dart';
import 'package:sandiapp/data/models/payment.dart';
import 'package:sandiapp/data/models/purchase.dart';
import 'package:sandiapp/data/repositories/backend.dart';

class FakeBackend implements Backend {
  List<Customer> customers;
  List<Purchase> purchases;
  List<Payment> payments;
  List<BudgetEntry> budget;
  FakeBackend(
      {List<Customer>? customers, List<Purchase>? purchases,
      List<Payment>? payments, List<BudgetEntry>? budget})
      : customers = [...?customers],
        purchases = [...?purchases],
        payments = [...?payments],
        budget = [...?budget];

  List<T> _active<T>(List<T> all, DateTime? Function(T) deletedAt) =>
      all.where((e) => deletedAt(e) == null).toList();

  @override
  Future<List<Customer>> readCustomers() async => _active(customers, (e) => e.deletedAt);
  @override
  Future<List<Purchase>> readPurchases() async => _active(purchases, (e) => e.deletedAt);
  @override
  Future<List<Payment>> readPayments() async => _active(payments, (e) => e.deletedAt);
  @override
  Future<List<BudgetEntry>> readBudgetEntries() async => _active(budget, (e) => e.deletedAt);

  void _put<T>(List<T> list, T item, String Function(T) id) {
    list.removeWhere((e) => id(e) == id(item));
    list.add(item);
  }

  @override
  Future<void> writeCustomer(Customer v) async => _put(customers, v, (e) => e.id);
  @override
  Future<void> writePurchase(Purchase v) async => _put(purchases, v, (e) => e.id);
  @override
  Future<void> writePayment(Payment v) async => _put(payments, v, (e) => e.id);
  @override
  Future<void> writeBudgetEntry(BudgetEntry v) async => _put(budget, v, (e) => e.id);

  @override
  Future<void> deleteCustomer(String id, DateTime at) async {
    customers = [for (final c in customers) c.id == id ? c.copyWith(deletedAt: at) : c];
  }
  @override
  Future<void> deletePurchase(String id, DateTime at) async {
    purchases = [for (final p in purchases) p.id == id ? p.copyWith(deletedAt: at) : p];
  }
  @override
  Future<void> deletePayment(String id, DateTime at) async {
    payments = [for (final p in payments) p.id == id ? p.copyWith(deletedAt: at) : p];
  }
  @override
  Future<void> deleteBudgetEntry(String id, DateTime at) async {
    budget = [for (final b in budget) b.id == id ? b.copyWith(deletedAt: at) : b];
  }
}
```

`test/data/repositories/app_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/core/logic/fifo.dart';
import 'package:sandiapp/data/models/budget_entry.dart';
import 'package:sandiapp/data/models/customer.dart';
import 'package:sandiapp/data/models/payment.dart';
import 'package:sandiapp/data/models/purchase.dart';
import 'package:sandiapp/data/repositories/app_repository.dart';

import '../../fakes/fake_backend.dart';

void main() {
  final t0 = DateTime.utc(2026, 8, 1, 10);
  late FakeBackend backend;
  late AppRepository repo;
  var syncRequested = 0;

  Customer c(String id, String nama) =>
      Customer(id: id, nama: nama, createdAt: t0, updatedAt: t0);
  Purchase p(String id, String cid, int jual, DateTime beli, {int? beli_}) => Purchase(
      id: id, customerId: cid, namaBarang: id, hargaJual: jual, hargaBeli: beli_,
      tanggalBeli: beli, createdAt: t0, updatedAt: t0);
  Payment pm(String id, String cid, int jumlah, DateTime tgl) => Payment(
      id: id, customerId: cid, jumlah: jumlah, tanggalBayar: tgl,
      createdAt: t0, updatedAt: t0);

  setUp(() {
    syncRequested = 0;
    backend = FakeBackend(
      customers: [c('c1', 'WIWIK'), c('c2', 'IKA'), c('c3', 'ANAS')],
      purchases: [
        p('p1', 'c1', 2050000, DateTime(2026, 7, 1), beli_: 1700000),
        p('p2', 'c1', 1200000, DateTime(2026, 8, 2)),
        p('p3', 'c2', 5000000, DateTime(2026, 8, 3), beli_: 3000000),
      ],
      payments: [
        pm('m1', 'c1', 2500000, DateTime(2026, 8, 5)),
        pm('m2', 'c2', 1000000, DateTime(2026, 8, 6)),
      ],
    );
    repo = AppRepository(backend,
        currentUserId: () => 'admin-1', onLocalWrite: () => syncRequested++);
  });

  test('customers: saldo dihitung, search, sortByHutang', () async {
    final all = await repo.customers();
    final wiwik = all.singleWhere((e) => e.customer.id == 'c1');
    expect(wiwik.totalHutang, 3250000);
    expect(wiwik.totalBayar, 2500000);
    expect(wiwik.sisa, 750000);

    expect((await repo.customers(query: 'ika')).single.customer.nama, 'IKA');
    final sorted = await repo.customers(sortByHutang: true);
    expect(sorted.first.customer.id, 'c2'); // sisa 4jt > 750rb > 0
  });

  test('customerDetail: FIFO + payments terbaru dulu', () async {
    final d = await repo.customerDetail('c1');
    expect(d.balance.sisa, 750000);
    expect(d.items.first.status, ItemStatus.lunas); // p1 tertua lunas
    expect(d.items.last.status, ItemStatus.sebagian); // sisa masuk ke p2
    expect(d.payments.single.id, 'm1');
  });

  test('dashboardStats', () async {
    final s = await repo.dashboardStats(now: t0); // t0 = Agustus 2026
    expect(s.totalPiutang, 4750000); // 750rb + 4jt
    expect(s.bayarBulanIni, 3500000); // m1 + m2, keduanya di Agustus 2026
    expect(s.customerBerhutang, 2);
    expect(s.topHutang.first.customer.id, 'c2');
  });

  test('savePayment: set createdBy, panggil onLocalWrite', () async {
    await repo.savePayment(pm('m9', 'c1', 100000, DateTime(2026, 8, 8)));
    expect(backend.payments.singleWhere((e) => e.id == 'm9').createdBy, 'admin-1');
    expect(syncRequested, 1);
  });

  test('deleteCustomer: soft delete, hilang dari read', () async {
    await repo.deleteCustomer('c3');
    expect(await repo.customers(), isNot(contains(isA<CustomerWithBalance>()
        .having((e) => e.customer.id, 'id', 'c3'))));
    expect(backend.customers.singleWhere((e) => e.id == 'c3').deletedAt, isNotNull);
  });

  test('budgetMonth: saldoAwal dari bulan sebelumnya', () async {
    backend.budget.addAll([
      BudgetEntry(id: 'b0', tanggal: DateTime(2026, 7, 1), namaTransaksi: 'x',
          tipe: 'pemasukan', jumlah: 1000000, createdAt: t0, updatedAt: t0),
      BudgetEntry(id: 'b1', tanggal: DateTime(2026, 8, 1), namaTransaksi: 'y',
          tipe: 'pengeluaran', jumlah: 250000, createdAt: t0, updatedAt: t0),
    ]);
    final lines = await repo.budgetMonth(2026, 8);
    expect(lines.single.saldo, 750000);
  });
}
```

Catatan: `dashboardStats` menerima parameter opsional `{DateTime? now}` (default `DateTime.now()`) agar test tidak rapuh waktu.

- [ ] **Step 2: Jalankan, pastikan gagal**

```bash
flutter test test/data/repositories/app_repository_test.dart
```

Expected: FAIL — URI tidak ada.

- [ ] **Step 3: Implementasi**

`lib/data/repositories/backend.dart`:

```dart
import '../models/budget_entry.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../models/purchase.dart';

/// Akses penyimpanan per platform. Baca = data aktif (non-deleted) saja.
abstract class Backend {
  Future<List<Customer>> readCustomers();
  Future<List<Purchase>> readPurchases();
  Future<List<Payment>> readPayments();
  Future<List<BudgetEntry>> readBudgetEntries();
  Future<void> writeCustomer(Customer v);
  Future<void> writePurchase(Purchase v);
  Future<void> writePayment(Payment v);
  Future<void> writeBudgetEntry(BudgetEntry v);
  Future<void> deleteCustomer(String id, DateTime at);
  Future<void> deletePurchase(String id, DateTime at);
  Future<void> deletePayment(String id, DateTime at);
  Future<void> deleteBudgetEntry(String id, DateTime at);
}
```

`lib/data/local/drift_backend.dart`:

```dart
import 'package:drift/drift.dart' show Value;

import '../models/budget_entry.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../models/purchase.dart';
import '../repositories/backend.dart';
import 'app_database.dart';

/// Backend Android: SQLite lokal, semua tulis ditandai dirty untuk sync.
class DriftBackend implements Backend {
  final AppDatabase db;
  DriftBackend(this.db);

  @override
  Future<List<Customer>> readCustomers() async =>
      [for (final r in await db.activeCustomers()) r.toModel()];
  @override
  Future<List<Purchase>> readPurchases() async =>
      [for (final r in await db.activePurchases()) r.toModel()];
  @override
  Future<List<Payment>> readPayments() async =>
      [for (final r in await db.activePayments()) r.toModel()];
  @override
  Future<List<BudgetEntry>> readBudgetEntries() async =>
      [for (final r in await db.activeBudgetEntries()) r.toModel()];

  @override
  Future<void> writeCustomer(Customer v) => db.upsertCustomerRow(v.toCompanion(dirty: true));
  @override
  Future<void> writePurchase(Purchase v) => db.upsertPurchaseRow(v.toCompanion(dirty: true));
  @override
  Future<void> writePayment(Payment v) => db.upsertPaymentRow(v.toCompanion(dirty: true));
  @override
  Future<void> writeBudgetEntry(BudgetEntry v) =>
      db.upsertBudgetEntryRow(v.toCompanion(dirty: true));

  @override
  Future<void> deleteCustomer(String id, DateTime at) => db.upsertCustomerRow(
      CustomersCompanion(id: Value(id), deletedAt: Value(at),
          updatedAt: Value(at), isDirty: const Value(true)));
  @override
  Future<void> deletePurchase(String id, DateTime at) => db.upsertPurchaseRow(
      PurchasesCompanion(id: Value(id), deletedAt: Value(at),
          updatedAt: Value(at), isDirty: const Value(true)));
  @override
  Future<void> deletePayment(String id, DateTime at) => db.upsertPaymentRow(
      PaymentsCompanion(id: Value(id), deletedAt: Value(at),
          updatedAt: Value(at), isDirty: const Value(true)));
  @override
  Future<void> deleteBudgetEntry(String id, DateTime at) => db.upsertBudgetEntryRow(
      BudgetEntriesCompanion(id: Value(id), deletedAt: Value(at),
          updatedAt: Value(at), isDirty: const Value(true)));
}
```

`lib/data/remote/remote_backend.dart`:

```dart
import '../models/budget_entry.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../models/purchase.dart';
import '../repositories/backend.dart';
import 'remote_store.dart';

/// Backend web: langsung Supabase, tanpa antrean sync.
class RemoteBackend implements Backend {
  final RemoteStore remote;
  RemoteBackend(this.remote);

  Future<List<T>> _read<T>(
      String table, T Function(Map<String, dynamic>) fromJson) async =>
      [
        for (final j in await remote.fetchSince(table, null))
          if (j['deleted_at'] == null) fromJson(j),
      ];

  @override
  Future<List<Customer>> readCustomers() => _read('customers', Customer.fromJson);
  @override
  Future<List<Purchase>> readPurchases() => _read('purchases', Purchase.fromJson);
  @override
  Future<List<Payment>> readPayments() => _read('payments', Payment.fromJson);
  @override
  Future<List<BudgetEntry>> readBudgetEntries() =>
      _read('budget_entries', BudgetEntry.fromJson);

  @override
  Future<void> writeCustomer(Customer v) => remote.upsert('customers', [v.toJson()]);
  @override
  Future<void> writePurchase(Purchase v) => remote.upsert('purchases', [v.toJson()]);
  @override
  Future<void> writePayment(Payment v) => remote.upsert('payments', [v.toJson()]);
  @override
  Future<void> writeBudgetEntry(BudgetEntry v) =>
      remote.upsert('budget_entries', [v.toJson()]);

  Future<void> _delete(String table, String id, DateTime at) => remote.upsert(table, [
        {
          'id': id,
          'deleted_at': at.toIso8601String(),
          'updated_at': at.toIso8601String(),
        }
      ]);

  @override
  Future<void> deleteCustomer(String id, DateTime at) => _delete('customers', id, at);
  @override
  Future<void> deletePurchase(String id, DateTime at) => _delete('purchases', id, at);
  @override
  Future<void> deletePayment(String id, DateTime at) => _delete('payments', id, at);
  @override
  Future<void> deleteBudgetEntry(String id, DateTime at) =>
      _delete('budget_entries', id, at);
}
```

`lib/data/repositories/app_repository.dart`:

```dart
import '../../core/logic/budget.dart';
import '../../core/logic/fifo.dart';
import '../../core/logic/profit.dart';
import '../models/budget_entry.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../models/purchase.dart';
import 'backend.dart';

class CustomerDetailData {
  final Customer customer;
  final List<PurchaseStatus> items; // urut FIFO (tertua dulu)
  final List<Payment> payments; // urut terbaru dulu
  final Balance balance;
  const CustomerDetailData({
    required this.customer,
    required this.items,
    required this.payments,
    required this.balance,
  });
}

class DashboardStats {
  final int totalPiutang, bayarBulanIni, customerBerhutang;
  final List<CustomerWithBalance> topHutang; // maks 5, sisa > 0
  const DashboardStats({
    required this.totalPiutang,
    required this.bayarBulanIni,
    required this.customerBerhutang,
    required this.topHutang,
  });
}

/// Satu-satunya pintu data untuk UI. Platform beda hanya di [Backend].
class AppRepository {
  final Backend backend;
  final String? Function() currentUserId;
  final void Function()? onLocalWrite; // Android: minta sync; web: null

  AppRepository(this.backend, {required this.currentUserId, this.onLocalWrite});

  DateTime _now() => DateTime.now().toUtc();

  Future<List<CustomerWithBalance>> customers(
      {String query = '', bool includeArchived = false, bool sortByHutang = false}) async {
    final cs = await backend.readCustomers();
    final ps = await backend.readPurchases();
    final pm = await backend.readPayments();
    final rows = [
      for (final c in cs)
        if (includeArchived || !c.isArchived)
          () {
            final b = balanceOf(
              ps.where((p) => p.customerId == c.id).toList(),
              pm.where((p) => p.customerId == c.id).toList(),
            );
            return CustomerWithBalance(
                customer: c, totalHutang: b.totalHutang, totalBayar: b.totalBayar);
          }(),
    ];
    final q = query.trim().toLowerCase();
    final filtered =
        q.isEmpty ? rows : rows.where((r) => r.customer.nama.toLowerCase().contains(q)).toList();
    filtered.sort((a, b) => sortByHutang
        ? b.sisa.compareTo(a.sisa)
        : a.customer.nama.toLowerCase().compareTo(b.customer.nama.toLowerCase()));
    return filtered;
  }

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
    );
  }

  Future<DashboardStats> dashboardStats({DateTime? now}) async {
    final n = now ?? DateTime.now();
    final balances = await customers();
    final berhutang = balances.where((b) => b.sisa > 0).toList()
      ..sort((a, b) => b.sisa.compareTo(a.sisa));
    final pm = await backend.readPayments();
    final bayarBulanIni = pm
        .where((p) =>
            p.statusVerifikasi == 'verified' &&
            p.tanggalBayar.year == n.year &&
            p.tanggalBayar.month == n.month)
        .fold<int>(0, (s, p) => s + p.jumlah);
    return DashboardStats(
      totalPiutang: berhutang.fold(0, (s, b) => s + b.sisa),
      bayarBulanIni: bayarBulanIni,
      customerBerhutang: berhutang.length,
      topHutang: berhutang.take(5).toList(),
    );
  }

  Future<List<ProfitRow>> profitYearly() async => profitPerYear(await backend.readPurchases());
  Future<List<ProfitRow>> profitMonthly(int year) async =>
      profitPerMonth(await backend.readPurchases(), year);

  Future<List<BudgetLine>> budgetMonth(int year, int month) async {
    final all = await backend.readBudgetEntries();
    final awalBulan = DateTime(year, month);
    final akhirBulan = DateTime(year, month + 1);
    final sebelum = all.where((e) => e.tanggal.isBefore(awalBulan)).toList();
    final saldoAwal = withRunningSaldo(sebelum).fold<int>(0, (_, l) => l.saldo);
    final bulanIni = all
        .where((e) =>
            !e.tanggal.isBefore(awalBulan) && e.tanggal.isBefore(akhirBulan))
        .toList();
    return withRunningSaldo(bulanIni, saldoAwal: saldoAwal);
  }

  Future<void> saveCustomer(Customer v) =>
      _write(() => backend.writeCustomer(
          v.copyWith(createdBy: v.createdBy ?? currentUserId(), updatedAt: _now())));
  Future<void> savePurchase(Purchase v) =>
      _write(() => backend.writePurchase(
          v.copyWith(createdBy: v.createdBy ?? currentUserId(), updatedAt: _now())));
  Future<void> savePayment(Payment v) =>
      _write(() => backend.writePayment(
          v.copyWith(createdBy: v.createdBy ?? currentUserId(), updatedAt: _now())));
  Future<void> saveBudgetEntry(BudgetEntry v) =>
      _write(() => backend.writeBudgetEntry(
          v.copyWith(createdBy: v.createdBy ?? currentUserId(), updatedAt: _now())));

  Future<void> deleteCustomer(String id) =>
      _write(() => backend.deleteCustomer(id, _now()));
  Future<void> deletePurchase(String id) =>
      _write(() => backend.deletePurchase(id, _now()));
  Future<void> deletePayment(String id) =>
      _write(() => backend.deletePayment(id, _now()));
  Future<void> deleteBudgetEntry(String id) =>
      _write(() => backend.deleteBudgetEntry(id, _now()));

  Future<T> _write<T>(Future<T> Function() action) async {
    final r = await action();
    onLocalWrite?.call();
    return r;
  }
}
```

- [ ] **Step 4: Jalankan, pastikan pass**

```bash
flutter test test/data/repositories/app_repository_test.dart
```

Expected: 6 tests pass (sesuaikan test dashboardStats memakai `now: t0`).

- [ ] **Step 5: Commit**

```bash
git add lib/data test/data/repositories test/fakes && git commit -m "feat: Backend (drift/remote) + AppRepository"
```

---

### Task 12: Bootstrap app — main.dart, providers, router + auth gate

**Files:**
- Modify: `lib/main.dart` (ganti sementara Task 1)
- Create: `lib/app.dart`, `lib/app_providers.dart`

**Interfaces:**
- Consumes: semua data layer (Task 8-11).
- Produces (dipakai semua task UI):
  - `repoProvider: Provider<AppRepository>`
  - `syncControllerProvider: NotifierProvider<SyncController, SyncUiState>` (lihat Task 14; di task ini cukup stub `SyncController` minimal)
  - `authStateProvider: StreamProvider<AuthState>`
  - `routerProvider: Provider<GoRouter>` — redirect `/login`
  - `Future<T> mutate<T>(Ref ref, Future<T> Function() action)` — jalankan aksi lalu invalidate semua data provider
  - Data provider: `customersProvider`, `customerDetailProvider(String id)`, `dashboardProvider`, `profitYearlyProvider`, `profitMonthlyProvider(int year)`, `budgetMonthProvider((int,int))` — semua `FutureProvider.autoDispose` (family sesuai parameter)
  - `main()` menginisialisasi: `initializeDateFormatting('id_ID')`, `Supabase.initialize(url/anonKey dari String.fromEnvironment)`, pilih Backend via `kIsWeb`, jalankan sync awal (Android), lalu `runApp`.

- [ ] **Step 1: Implementasi `lib/app_providers.dart`**

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/logic/budget.dart';
import 'core/logic/profit.dart';
import 'data/local/app_database.dart';
import 'data/local/drift_backend.dart';
import 'data/models/customer.dart';
import 'data/remote/remote_backend.dart';
import 'data/remote/remote_store.dart';
import 'data/repositories/app_repository.dart';
import 'data/repositories/backend.dart';
import 'data/sync/sync_controller.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final remoteStoreProvider =
    Provider<RemoteStore>((_) => SupabaseRemoteStore(Supabase.instance.client));

final backendProvider = Provider<Backend>((ref) => kIsWeb
    ? RemoteBackend(ref.watch(remoteStoreProvider))
    : DriftBackend(ref.watch(appDatabaseProvider)));

final repoProvider = Provider<AppRepository>((ref) => AppRepository(
      ref.watch(backendProvider),
      currentUserId: () => Supabase.instance.client.auth.currentUser?.id,
      onLocalWrite:
          kIsWeb ? null : () => ref.read(syncControllerProvider.notifier).requestSync(),
    ));

final authStateProvider = StreamProvider(
    (ref) => Supabase.instance.client.auth.onAuthStateChange);

// ---- data providers (di-invalidate oleh mutate() / selesai sync) ----
final customersProvider = FutureProvider.autoDispose
    .family<List<CustomerWithBalance>, ({String query, bool sortByHutang})>(
        (ref, p) => ref
            .watch(repoProvider)
            .customers(query: p.query, sortByHutang: p.sortByHutang));

final customerDetailProvider =
    FutureProvider.autoDispose.family<CustomerDetailData, String>(
        (ref, id) => ref.watch(repoProvider).customerDetail(id));

final dashboardProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(repoProvider).dashboardStats());

final profitYearlyProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(repoProvider).profitYearly());

final profitMonthlyProvider = FutureProvider.autoDispose
    .family<List<ProfitRow>, int>((ref, year) =>
        ref.watch(repoProvider).profitMonthly(year));

final budgetMonthProvider = FutureProvider.autoDispose
    .family<List<BudgetLine>, (int, int)>((ref, ym) =>
        ref.watch(repoProvider).budgetMonth(ym.$1, ym.$2));

/// Jalankan mutasi lalu refresh semua data provider.
Future<T> mutate<T>(Ref ref, Future<T> Function() action) async {
  final r = await action();
  invalidateAllData(ref);
  return r;
}

void invalidateAllData(Ref ref) {
  ref.invalidate(customersProvider);
  ref.invalidate(customerDetailProvider);
  ref.invalidate(dashboardProvider);
  ref.invalidate(profitYearlyProvider);
  ref.invalidate(profitMonthlyProvider);
  ref.invalidate(budgetMonthProvider);
}
```

- [ ] **Step 2: Implementasi `lib/main.dart`**

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'data/sync/sync_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  final container = ProviderContainer();
  if (!kIsWeb) {
    // sync awal saat app start (best effort; gagal = tetap jalan offline)
    Future(() => container.read(syncControllerProvider.notifier).syncNow());
  }
  runApp(UncontrolledProviderScope(container: container, child: const SandiApp()));
}
```

(syncController di-stub dulu di Step 4 agar kompilasi jalan, diisi penuh di Task 14.)

- [ ] **Step 3: Implementasi `lib/app.dart` (router + auth gate)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_providers.dart';
import 'core/theme.dart';
import 'features/auth/login_page.dart';
import 'features/budget/budget_page.dart';
import 'features/customers/customer_detail_page.dart';
import 'features/customers/customers_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/reports/reports_page.dart';
import 'features/settings/settings_page.dart';
import 'features/shell/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref
    ..onDispose(refresh.dispose)
    ..listen(authStateProvider, (_, __) => refresh.value++);

  return GoRouter(
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = Supabase.instance.client.auth.currentSession != null;
      final onLogin = state.matchedLocation == '/login';
      if (!loggedIn && !onLogin) return '/login';
      if (loggedIn && onLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const DashboardPage()),
          GoRoute(path: '/customers', builder: (_, __) => const CustomersPage()),
          GoRoute(
              path: '/customers/:id',
              builder: (_, s) => CustomerDetailPage(customerId: s.pathParameters['id']!)),
          GoRoute(path: '/reports', builder: (_, __) => const ReportsPage()),
          GoRoute(path: '/budget', builder: (_, __) => const BudgetPage()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
        ],
      ),
    ],
  );
});

class SandiApp extends ConsumerWidget {
  const SandiApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'SandiApp',
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      routerConfig: ref.watch(routerProvider),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id'), Locale('en')],
    );
  }
}
```

- [ ] **Step 4: Stub halaman & SyncController agar kompilasi jalan**

Buat halaman placeholder sementara (diisi penuh di task masing-masing), contoh pola untuk keenam halaman:

```dart
// lib/features/dashboard/dashboard_page.dart
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Dashboard'));
}
```

(analog: `LoginPage`, `CustomersPage`, `CustomerDetailPage({required String customerId})`, `ReportsPage`, `BudgetPage`, `SettingsPage`, dan `AppShell({required Widget child})` yang meng-render `Scaffold(body: child)`.)

`lib/data/sync/sync_controller.dart` (stub, dipenuhi Task 14):

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SyncUiState {
  final bool syncing;
  final int pending;
  final DateTime? lastSync;
  const SyncUiState({this.syncing = false, this.pending = 0, this.lastSync});
}

class SyncController extends Notifier<SyncUiState> {
  @override
  SyncUiState build() => const SyncUiState();
  void requestSync() {}
  Future<void> syncNow() async {}
}

final syncControllerProvider =
    NotifierProvider<SyncController, SyncUiState>(SyncController.new);
```

- [ ] **Step 5: Verifikasi kompilasi + smoke test lama masih jalan**

```bash
flutter analyze
```

Expected: bersih. (`test/widget_test.dart` bawaan Task 1 akan gagal karena main.dart berubah — ganti isinya menjadi test trivial:)

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder', () => expect(1 + 1, 2));
}
```

Lalu:

```bash
flutter test
```

Expected: semua pass.

- [ ] **Step 6: Commit**

```bash
git add lib test && git commit -m "feat: bootstrap app, providers, router dengan auth gate"
```

---

### Task 13: Login + AuthController

**Files:**
- Create: `lib/features/auth/auth_controller.dart`, `lib/features/auth/login_page.dart`
- Modify: `lib/app.dart` (import sudah ada; tidak berubah)

**Interfaces:**
- Consumes: `Supabase.instance.client`, `app_providers.dart`.
- Produces: `authControllerProvider: NotifierProvider<AuthController, AsyncValue<void>>` dengan `Future<void> signIn(String email, String password)` dan `Future<void> signOut()`.

- [ ] **Step 1: Implementasi `auth_controller.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => Supabase.instance.client.auth
        .signInWithPassword(email: email.trim(), password: password));
  }

  Future<void> signOut() => Supabase.instance.client.auth.signOut();
}

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);
```

- [ ] **Step 2: Implementasi `login_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authControllerProvider.notifier).signIn(_email.text, _password.text);
    final err = ref.read(authControllerProvider).error;
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login gagal. Periksa email & password.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authControllerProvider).isLoading;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                Text('SandiApp', style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: loading ? null : _submit,
                  child: loading
                      ? const SizedBox.square(
                          dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Masuk'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Verifikasi + commit**

```bash
flutter analyze && flutter test
```

Expected: bersih & pass. Lalu:

```bash
git add lib/features/auth && git commit -m "feat: login email/password + auth controller"
```

---

### Task 14: SyncController penuh + AppShell (navigasi, OfflineBanner, SyncBadge)

**Files:**
- Modify: `lib/data/sync/sync_controller.dart` (ganti stub Task 12)
- Create: `lib/features/shell/app_shell.dart`, `lib/widgets/offline_banner.dart`, `lib/widgets/sync_badge.dart`

**Interfaces:**
- Consumes: `SyncEngine` (10), `SyncStateStore` (10), `appDatabaseProvider`, `remoteStoreProvider`, `_invalidateAll` (12) — ekspor `_invalidateAll` sebagai `invalidateAllData(Ref)` dari `app_providers.dart` (rename, update pemakaian di `mutate`).
- Produces:
  - `SyncUiState({bool syncing, int pending, DateTime? lastSync, bool offline})`
  - `SyncController extends Notifier<SyncUiState>`: `requestSync()` (debounce 5 detik), `Future<void> syncNow()`, auto-sync saat konektivitas pulih (`connectivity_plus`), update `pending` dari `db.dirtyCount()`, setelah sync sukses panggil `invalidateAllData(ref)`.
  - `connectivityProvider: StreamProvider<bool>` (true = online)
  - `AppShell`: `NavigationBar` 5 tujuan (Beranda `/`, Customer `/customers`, Laporan `/reports`, Anggaran `/budget`, Pengaturan `/settings`), `OfflineBanner` di atas body, `SyncBadge` di AppBar (Android saja; web disembunyikan).

- [ ] **Step 1: Implementasi `sync_controller.dart`**

```dart
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_providers.dart';
import '../local/app_database.dart';
import 'sync_engine.dart';
import 'sync_state.dart';

class SyncUiState {
  final bool syncing, offline;
  final int pending;
  final DateTime? lastSync;
  const SyncUiState(
      {this.syncing = false, this.offline = false, this.pending = 0, this.lastSync});

  SyncUiState copyWith(
          {bool? syncing, bool? offline, int? pending, DateTime? lastSync}) =>
      SyncUiState(
          syncing: syncing ?? this.syncing,
          offline: offline ?? this.offline,
          pending: pending ?? this.pending,
          lastSync: lastSync ?? this.lastSync);
}

class SyncController extends Notifier<SyncUiState> {
  Timer? _debounce;
  bool _running = false;

  @override
  SyncUiState build() {
    ref.listen(connectivityProvider, (_, next) {
      if (next.value == true) requestSync();
    });
    _refreshPending();
    return const SyncUiState();
  }

  Future<void> _refreshPending() async {
    final n = await ref.read(appDatabaseProvider).dirtyCount();
    state = state.copyWith(pending: n);
  }

  void requestSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 5), () => syncNow());
  }

  Future<void> syncNow() async {
    if (_running) return;
    _running = true;
    state = state.copyWith(syncing: true);
    try {
      final db = ref.read(appDatabaseProvider);
      final engine = SyncEngine(db, ref.read(remoteStoreProvider),
          SyncStateStore(await SharedPreferences.getInstance()));
      await engine.syncAll();
      state = state.copyWith(
          syncing: false, offline: false, lastSync: DateTime.now());
      invalidateAllData(ref);
    } catch (_) {
      state = state.copyWith(syncing: false, offline: true);
    } finally {
      _running = false;
      await _refreshPending();
    }
  }
}

final syncControllerProvider =
    NotifierProvider<SyncController, SyncUiState>(SyncController.new);

final connectivityProvider = StreamProvider<bool>((ref) => Connectivity()
    .onConnectivityChanged
    .map((results) => results.any((r) => r != ConnectivityResult.none)));
```

(`invalidateAllData` sudah publik di `app_providers.dart` sejak Task 12 dan dipakai `mutate` — tidak perlu perubahan.)

- [ ] **Step 2: Implementasi `app_shell.dart` + 2 widget**

`lib/widgets/offline_banner.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sync/sync_controller.dart';

/// Banner saat tidak ada koneksi (Android) / selalu tersembunyi di web bila online.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(connectivityProvider).value ?? true;
    if (online) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Text('Tidak ada koneksi — data disimpan lokal, disinkronkan nanti',
          style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
    );
  }
}
```

`lib/widgets/sync_badge.dart`:

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sync/sync_controller.dart';

/// Ikon status sync di AppBar (Android saja): jumlah pending / tersinkron.
class SyncBadge extends ConsumerWidget {
  const SyncBadge({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb) return const SizedBox.shrink();
    final s = ref.watch(syncControllerProvider);
    if (s.syncing) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return IconButton(
      tooltip: s.pending > 0 ? '${s.pending} belum tersinkron' : 'Tersinkron',
      icon: Icon(s.pending > 0 ? Icons.cloud_upload_outlined : Icons.cloud_done_outlined),
      onPressed: () => ref.read(syncControllerProvider.notifier).syncNow(),
    );
  }
}
```

`lib/features/shell/app_shell.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/offline_banner.dart';
import '../../widgets/sync_badge.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = ['/', '/customers', '/reports', '/budget', '/settings'];

  int _indexOf(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/customers')) return 1;
    if (loc.startsWith('/reports')) return 2;
    if (loc.startsWith('/budget')) return 3;
    if (loc.startsWith('/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SandiApp'), actions: const [SyncBadge()]),
      body: Column(children: [const OfflineBanner(), Expanded(child: child)]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexOf(context),
        onDestinationSelected: (i) => context.go(_tabs[i]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Customer'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Laporan'),
          NavigationDestination(icon: Icon(Icons.wallet_outlined), label: 'Anggaran'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Pengaturan'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Verifikasi + commit**

```bash
flutter analyze && flutter test
```

Expected: bersih & pass. Lalu:

```bash
git add lib && git commit -m "feat: sync controller + app shell (navigasi, offline banner, sync badge)"
```

---

### Task 15: Customers list + search/sort (+ widget test)

**Files:**
- Create: `lib/features/customers/customers_page.dart` (ganti stub), `lib/widgets/empty_state.dart`
- Test: `test/features/customers_page_test.dart`

**Interfaces:**
- Consumes: `customersProvider`, `repoProvider`, `mutate` (Task 12).
- Produces: `CustomersPage` — search field, toggle sort (nama/sisa hutang), list `CustomerWithBalance` (nama + badge sisa, "LUNAS" bila sisa ≤ 0 & pernah belanja), tap → `/customers/:id`, FAB → `CustomerFormPage` (Task 17, route via `Navigator.push` material — form belum ada di task ini, FAB di-wire di Task 17), pull-to-refresh (`ref.invalidate`).
- `EmptyState({required String message, String? actionLabel, VoidCallback? onAction})`.

- [ ] **Step 1: Tulis widget test gagal — `test/features/customers_page_test.dart`**

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
import 'package:sandiapp/features/customers/customers_page.dart';

import '../fakes/fake_backend.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  final t0 = DateTime.utc(2026, 8, 1);

  AppRepository makeRepo() => AppRepository(
        FakeBackend(
          customers: [
            Customer(id: 'c1', nama: 'WIWIK', createdAt: t0, updatedAt: t0),
            Customer(id: 'c2', nama: 'IKA', createdAt: t0, updatedAt: t0),
          ],
          purchases: [
            Purchase(id: 'p1', customerId: 'c1', namaBarang: 'HP', hargaJual: 2000000,
                tanggalBeli: t0, createdAt: t0, updatedAt: t0),
          ],
          payments: [
            Payment(id: 'm1', customerId: 'c1', jumlah: 500000, tanggalBayar: t0,
                createdAt: t0, updatedAt: t0),
          ],
        ),
        currentUserId: () => 'admin-1',
      );

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(ProviderScope(
        overrides: [repoProvider.overrideWithValue(makeRepo())],
        child: const MaterialApp(home: Scaffold(body: CustomersPage())),
      ));

  testWidgets('menampilkan customer + sisa hutang terformat', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();
    expect(find.text('WIWIK'), findsOneWidget);
    expect(find.text('IKA'), findsOneWidget);
    expect(find.textContaining('1.500.000'), findsOneWidget); // sisa WIWIK
  });

  testWidgets('search memfilter nama', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ika');
    await tester.pumpAndSettle();
    expect(find.text('WIWIK'), findsNothing);
    expect(find.text('IKA'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

```bash
flutter test test/features/customers_page_test.dart
```

Expected: FAIL — `CustomersPage` masih stub (tidak ada TextField).

- [ ] **Step 3: Implementasi**

`lib/widgets/empty_state.dart`:

```dart
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState({super.key, required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(message, style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ]),
      );
}
```

`lib/features/customers/customers_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_providers.dart';
import '../../core/utils/money.dart';
import '../../widgets/empty_state.dart';

class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});
  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  String _query = '';
  bool _sortByHutang = false;

  @override
  Widget build(BuildContext context) {
    final data =
        ref.watch(customersProvider((query: _query, sortByHutang: _sortByHutang)));
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(8),
        child: Row(children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                  hintText: 'Cari nama customer...', prefixIcon: Icon(Icons.search)),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          IconButton(
            tooltip: _sortByHutang ? 'Urut nama' : 'Urut hutang terbesar',
            icon: Icon(_sortByHutang ? Icons.sort_by_alpha : Icons.sort),
            onPressed: () => setState(() => _sortByHutang = !_sortByHutang),
          ),
        ]),
      ),
      Expanded(
        child: data.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(message: 'Gagal memuat data: $e'),
          data: (rows) => rows.isEmpty
              ? const EmptyState(message: 'Belum ada customer.')
              : RefreshIndicator(
                  onRefresh: () async => ref.invalidate(customersProvider),
                  child: ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (_, i) {
                      final r = rows[i];
                      final lunas = r.totalHutang > 0 && r.sisa <= 0;
                      return ListTile(
                        title: Text(r.customer.nama),
                        subtitle: lunas
                            ? const Text('LUNAS')
                            : Text('Sisa: ${formatRupiah(r.sisa)}'),
                        trailing: lunas
                            ? const Icon(Icons.check_circle_outline, color: Colors.green)
                            : null,
                        onTap: () => context.push('/customers/${r.customer.id}'),
                      );
                    },
                  ),
                ),
        ),
      ),
    ]);
  }
}
```

(FAB tambah customer dipasang di Task 17 bersama form-nya.)

- [ ] **Step 4: Jalankan test, pastikan pass**

```bash
flutter test test/features/customers_page_test.dart
```

Expected: 2 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/customers lib/widgets test/features && git commit -m "feat: daftar customer dengan search, sort, badge sisa hutang"
```

---

### Task 16: Customer detail — ringkasan + status FIFO + riwayat bayar

**Files:**
- Create: `lib/features/customers/customer_detail_page.dart` (ganti stub), `lib/widgets/stat_card.dart`

**Interfaces:**
- Consumes: `customerDetailProvider`, logic fifo.
- Produces: `CustomerDetailPage({required String customerId})` — ringkasan (total belanja, total bayar, sisa hutang besar), seksi "Barang" (nama, harga, status chip LUNAS/SEBAGIAN/BELUM + sisa per item), seksi "Pembayaran" (tanggal, nominal, metode), tombol aksi tambah barang/pembayaran (di-wire di Task 18-19).

- [ ] **Step 1: Implementasi `stat_card.dart`**

```dart
import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const StatCard({super.key, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: valueColor)),
          ]),
        ),
      );
}
```

- [ ] **Step 2: Implementasi `customer_detail_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/logic/fifo.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stat_card.dart';

class CustomerDetailPage extends ConsumerWidget {
  final String customerId;
  const CustomerDetailPage({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(customerDetailProvider(customerId));
    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(message: 'Gagal memuat: $e'),
      data: (d) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(customerDetailProvider(customerId)),
        child: ListView(padding: const EdgeInsets.all(12), children: [
          Row(children: [
            Expanded(child: StatCard(label: 'Total Belanja', value: formatRupiah(d.balance.totalHutang))),
            Expanded(child: StatCard(label: 'Total Bayar', value: formatRupiah(d.balance.totalBayar))),
          ]),
          StatCard(
            label: 'Sisa Hutang',
            value: formatRupiah(d.balance.sisa),
            valueColor: d.balance.sisa > 0
                ? Theme.of(context).colorScheme.error
                : Colors.green,
          ),
          const SizedBox(height: 16),
          Text('Barang', style: Theme.of(context).textTheme.titleMedium),
          if (d.items.isEmpty) const ListTile(title: Text('Belum ada barang.')),
          for (final item in d.items)
            ListTile(
              title: Text(item.purchase.namaBarang),
              subtitle: Text(
                  '${tampilTanggal(item.purchase.tanggalBeli)} · ${formatRupiah(item.purchase.hargaJual)}'
                  '${item.status == ItemStatus.sebagian ? ' · sisa ${formatRupiah(item.sisa)}' : ''}'),
              trailing: _StatusChip(status: item.status),
            ),
          const SizedBox(height: 16),
          Text('Riwayat Pembayaran', style: Theme.of(context).textTheme.titleMedium),
          if (d.payments.isEmpty) const ListTile(title: Text('Belum ada pembayaran.')),
          for (final p in d.payments)
            ListTile(
              dense: true,
              title: Text(formatRupiah(p.jumlah)),
              subtitle: Text('${tampilTanggal(p.tanggalBayar)} · ${p.metode}'),
            ),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ItemStatus status;
  const _StatusChip({required this.status});
  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ItemStatus.lunas => ('LUNAS', Colors.green),
      ItemStatus.sebagian => ('SEBAGIAN', Colors.orange),
      ItemStatus.belum => ('BELUM', Colors.red),
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide.none,
    );
  }
}
```

- [ ] **Step 3: Verifikasi + commit**

```bash
flutter analyze && flutter test
```

Expected: bersih & pass. Lalu:

```bash
git add lib/features/customers lib/widgets && git commit -m "feat: detail customer dengan status FIFO per barang"
```

---

### Task 17: Form customer (tambah/edit/arsip/hapus)

**Files:**
- Create: `lib/features/customers/customer_form_page.dart`, `lib/widgets/confirm_dialog.dart`
- Modify: `lib/features/customers/customers_page.dart` (tambah FAB), `lib/features/customers/customer_detail_page.dart` (menu edit/arsip/hapus)

**Interfaces:**
- Produces: `CustomerFormPage({Customer? existing})` — field nama (wajib), no_hp, alamat, catatan; simpan via `repoProvider.saveCustomer` dalam `mutate`; id baru via `Uuid().v4()`.
- `Future<bool> confirmDialog(BuildContext, {required String title, required String message})`.

- [ ] **Step 1: Implementasi `confirm_dialog.dart`**

```dart
import 'package:flutter/material.dart';

Future<bool> confirmDialog(BuildContext context,
    {required String title, required String message}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya')),
      ],
    ),
  );
  return ok ?? false;
}
```

- [ ] **Step 2: Implementasi `customer_form_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app_providers.dart';
import '../../data/models/customer.dart';

class CustomerFormPage extends ConsumerStatefulWidget {
  final Customer? existing;
  const CustomerFormPage({super.key, this.existing});
  @override
  ConsumerState<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends ConsumerState<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nama = TextEditingController(text: widget.existing?.nama);
  late final _noHp = TextEditingController(text: widget.existing?.noHp);
  late final _alamat = TextEditingController(text: widget.existing?.alamat);
  late final _catatan = TextEditingController(text: widget.existing?.catatan);
  bool _saving = false;

  @override
  void dispose() {
    _nama.dispose();
    _noHp.dispose();
    _alamat.dispose();
    _catatan.dispose();
    super.dispose();
  }

  String? _emptyToNull(String s) => s.trim().isEmpty ? null : s.trim();

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final now = DateTime.now().toUtc();
    final e = widget.existing;
    final customer = Customer(
      id: e?.id ?? const Uuid().v4(),
      nama: _nama.text.trim(),
      noHp: _emptyToNull(_noHp.text),
      alamat: _emptyToNull(_alamat.text),
      catatan: _emptyToNull(_catatan.text),
      isArchived: e?.isArchived ?? false,
      authUserId: e?.authUserId,
      createdBy: e?.createdBy,
      createdAt: e?.createdAt ?? now,
      updatedAt: now,
    );
    await mutate(ref, () => ref.read(repoProvider).saveCustomer(customer));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.existing == null ? 'Tambah Customer' : 'Edit Customer')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextFormField(
            controller: _nama,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Nama *'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
              controller: _noHp,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'No. HP')),
          const SizedBox(height: 12),
          TextFormField(
              controller: _alamat, decoration: const InputDecoration(labelText: 'Alamat')),
          const SizedBox(height: 12),
          TextFormField(
              controller: _catatan, decoration: const InputDecoration(labelText: 'Catatan')),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
          ),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 3: Wire FAB di `customers_page.dart` + menu di `customer_detail_page.dart`**

Di `_CustomersPageState.build`, bungkus `Column` dengan `Scaffold`? Tidak — halaman sudah di dalam `AppShell`. Tambahkan FAB via `Scaffold.floatingActionButton` milik shell tidak memungkinkan; sebagai gantinya bungkus body halaman dengan `Scaffold` transparan:

```dart
return Scaffold(
  floatingActionButton: FloatingActionButton(
    heroTag: 'customers-fab',
    onPressed: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const CustomerFormPage())),
    child: const Icon(Icons.person_add),
  ),
  body: Column(children: [ /* ... konten existing ... */ ]),
);
```

Di `CustomerDetailPage`, tambahkan `actions` tidak tersedia (AppBar milik shell) → tambahkan baris tombol di atas konten:

```dart
// di dalam ListView, paling atas:
Row(mainAxisAlignment: MainAxisAlignment.end, children: [
  TextButton.icon(
    icon: const Icon(Icons.edit),
    label: const Text('Edit'),
    onPressed: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => CustomerFormPage(existing: d.customer))),
  ),
  TextButton.icon(
    icon: const Icon(Icons.delete_outline),
    label: const Text('Hapus'),
    onPressed: () async {
      if (await confirmDialog(context,
          title: 'Hapus customer?', message: 'Data ${d.customer.nama} disembunyikan (soft delete).')) {
        await mutate(ref, () => ref.read(repoProvider).deleteCustomer(customerId));
        if (context.mounted) context.pop();
      }
    },
  ),
]),
```

(tambahkan import `confirm_dialog.dart`, `go_router` untuk `context.pop`, dan `customer_form_page.dart`.)

- [ ] **Step 4: Verifikasi + commit**

```bash
flutter analyze && flutter test
```

Expected: bersih & pass. Lalu:

```bash
git add lib && git commit -m "feat: form customer (tambah/edit/hapus) + konfirmasi"
```

---

### Task 18: Form barang kredit (purchase) + MoneyInputField

**Files:**
- Create: `lib/widgets/money_input_field.dart`
- Create: `lib/features/purchases/purchase_form_page.dart`
- Modify: `lib/features/customers/customer_detail_page.dart` (tombol "Tambah Barang")

**Interfaces:**
- Produces:
  - `MoneyInputField({TextEditingController controller, String label, String? Function(String?)? validator})` — keyboard angka, menampilkan format ribuan saat mengetik (simpan digit mentah di controller via listener internal: tampil `1.500.000`, nilai diambil dengan `parseRupiah(controller.text)`).
  - `PurchaseFormPage({required String customerId, Purchase? existing})` — nama barang (wajib), harga jual (wajib > 0), harga beli (opsional), tanggal beli (default hari ini, date picker), catatan.

- [ ] **Step 1: Implementasi `money_input_field.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/money.dart';

/// Input rupiah: mengetik angka -> tampil terformat ribuan (1.500.000).
/// Baca nilai dengan parseRupiah(controller.text).
class MoneyInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  const MoneyInputField(
      {super.key, required this.controller, required this.label, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, prefixText: 'Rp '),
      validator: validator,
      onChanged: (v) {
        final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
        final formatted =
            digits.isEmpty ? '' : formatRupiah(int.parse(digits)).replaceFirst('Rp ', '');
        if (formatted != v) {
          controller.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      },
    );
  }
}
```

- [ ] **Step 2: Implementasi `purchase_form_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app_providers.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../data/models/purchase.dart';
import '../../widgets/money_input_field.dart';

class PurchaseFormPage extends ConsumerStatefulWidget {
  final String customerId;
  final Purchase? existing;
  const PurchaseFormPage({super.key, required this.customerId, this.existing});
  @override
  ConsumerState<PurchaseFormPage> createState() => _PurchaseFormPageState();
}

class _PurchaseFormPageState extends ConsumerState<PurchaseFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nama = TextEditingController(text: widget.existing?.namaBarang);
  late final _hargaJual = TextEditingController(
      text: widget.existing == null ? '' : _fmt(widget.existing!.hargaJual));
  late final _hargaBeli = TextEditingController(
      text: widget.existing?.hargaBeli == null ? '' : _fmt(widget.existing!.hargaBeli!));
  late DateTime _tanggal =
      widget.existing?.tanggalBeli ?? today();
  bool _saving = false;

  static String _fmt(int v) => formatRupiah(v).replaceFirst('Rp ', '');

  @override
  void dispose() {
    _nama.dispose();
    _hargaJual.dispose();
    _hargaBeli.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final now = DateTime.now().toUtc();
    final e = widget.existing;
    final beliDigits = parseRupiah(_hargaBeli.text);
    final purchase = Purchase(
      id: e?.id ?? const Uuid().v4(),
      customerId: widget.customerId,
      namaBarang: _nama.text.trim(),
      hargaJual: parseRupiah(_hargaJual.text),
      hargaBeli: beliDigits == 0 ? null : beliDigits,
      tanggalBeli: _tanggal,
      catatan: e?.catatan,
      createdBy: e?.createdBy,
      createdAt: e?.createdAt ?? now,
      updatedAt: now,
    );
    await mutate(ref, () => ref.read(repoProvider).savePurchase(purchase));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.existing == null ? 'Tambah Barang' : 'Edit Barang')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextFormField(
            controller: _nama,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Nama barang *'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
          ),
          const SizedBox(height: 12),
          MoneyInputField(
            controller: _hargaJual,
            label: 'Harga jual *',
            validator: (v) =>
                parseRupiah(v ?? '') <= 0 ? 'Harga jual harus lebih dari 0' : null,
          ),
          const SizedBox(height: 12),
          MoneyInputField(
              controller: _hargaBeli, label: 'Harga beli (opsional, untuk laporan)'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range),
            label: Text('Tanggal beli: ${tampilTanggal(_tanggal)}'),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _tanggal,
                firstDate: DateTime(2015),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                locale: const Locale('id', 'ID'),
              );
              if (picked != null) setState(() => _tanggal = picked);
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Menyimpan...' : 'Simpan')),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 3: Wire tombol di `customer_detail_page.dart`**

Di atas seksi "Barang", ubah judul menjadi Row dengan aksi:

```dart
Row(children: [
  Expanded(child: Text('Barang', style: Theme.of(context).textTheme.titleMedium)),
  TextButton.icon(
    icon: const Icon(Icons.add),
    label: const Text('Tambah'),
    onPressed: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => PurchaseFormPage(customerId: customerId))),
  ),
]),
```

Dan di tiap `ListTile` barang: `onTap` → `PurchaseFormPage(customerId: customerId, existing: item.purchase)` untuk edit; hapus via long-press `confirmDialog` + `repoProvider.deletePurchase` dalam `mutate`.

- [ ] **Step 4: Verifikasi + commit**

```bash
flutter analyze && flutter test
```

Expected: bersih & pass. Lalu:

```bash
git add lib && git commit -m "feat: form barang kredit + input rupiah terformat"
```

---

### Task 19: Form pembayaran + nominal cepat (+ widget test)

**Files:**
- Create: `lib/features/payments/payment_form_page.dart`
- Modify: `lib/features/customers/customer_detail_page.dart` (tombol "Tambah Pembayaran" di seksi Riwayat Pembayaran, pola sama dengan Task 18)
- Test: `test/features/payment_form_test.dart`

**Interfaces:**
- Produces: `PaymentFormPage({required String customerId, Payment? existing})` — `MoneyInputField` jumlah (wajib > 0), chip nominal cepat (50rb/100rb/200rb/500rb — menimpa nilai field), tanggal bayar (default hari ini), dropdown metode (tunai/transfer/lainnya), catatan opsional.

- [ ] **Step 1: Tulis widget test gagal — `test/features/payment_form_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sandiapp/app_providers.dart';
import 'package:sandiapp/data/repositories/app_repository.dart';
import 'package:sandiapp/features/payments/payment_form_page.dart';

import '../fakes/fake_backend.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  Future<void> pump(WidgetTester tester, FakeBackend backend) =>
      tester.pumpWidget(ProviderScope(
        overrides: [
          repoProvider.overrideWithValue(
              AppRepository(backend, currentUserId: () => 'admin-1')),
        ],
        child: const MaterialApp(home: PaymentFormPage(customerId: 'c1')),
      ));

  testWidgets('chip nominal cepat mengisi field terformat', (tester) async {
    await pump(tester, FakeBackend());
    await tester.pumpAndSettle();
    await tester.tap(find.text('100rb'));
    await tester.pump();
    expect(find.text('100.000'), findsOneWidget);
  });

  testWidgets('jumlah 0 ditolak validasi', (tester) async {
    await pump(tester, FakeBackend());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pump();
    expect(find.text('Jumlah harus lebih dari 0'), findsOneWidget);
  });

  testWidgets('simpan pembayaran valid masuk backend', (tester) async {
    final backend = FakeBackend();
    await pump(tester, backend);
    await tester.pumpAndSettle();
    await tester.tap(find.text('200rb'));
    await tester.pump();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(backend.payments.single.jumlah, 200000);
    expect(backend.payments.single.customerId, 'c1');
  });
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

```bash
flutter test test/features/payment_form_test.dart
```

Expected: FAIL — URI tidak ada.

- [ ] **Step 3: Implementasi `payment_form_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app_providers.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../data/models/payment.dart';
import '../../widgets/money_input_field.dart';

class PaymentFormPage extends ConsumerStatefulWidget {
  final String customerId;
  final Payment? existing;
  const PaymentFormPage({super.key, required this.customerId, this.existing});
  @override
  ConsumerState<PaymentFormPage> createState() => _PaymentFormPageState();
}

class _PaymentFormPageState extends ConsumerState<PaymentFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _jumlah = TextEditingController(
      text: widget.existing == null
          ? ''
          : formatRupiah(widget.existing!.jumlah).replaceFirst('Rp ', ''));
  late final _catatan = TextEditingController(text: widget.existing?.catatan);
  late DateTime _tanggal = widget.existing?.tanggalBayar ?? today();
  late String _metode = widget.existing?.metode ?? 'tunai';
  bool _saving = false;

  @override
  void dispose() {
    _jumlah.dispose();
    _catatan.dispose();
    super.dispose();
  }

  void _setJumlah(int v) {
    _jumlah.text = formatRupiah(v).replaceFirst('Rp ', '');
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final now = DateTime.now().toUtc();
    final e = widget.existing;
    final payment = Payment(
      id: e?.id ?? const Uuid().v4(),
      customerId: widget.customerId,
      jumlah: parseRupiah(_jumlah.text),
      tanggalBayar: _tanggal,
      metode: _metode,
      catatan: _catatan.text.trim().isEmpty ? null : _catatan.text.trim(),
      sumber: e?.sumber ?? 'admin',
      statusVerifikasi: e?.statusVerifikasi ?? 'verified',
      buktiFotoUrl: e?.buktiFotoUrl,
      createdBy: e?.createdBy,
      createdAt: e?.createdAt ?? now,
      updatedAt: now,
    );
    await mutate(ref, () => ref.read(repoProvider).savePayment(payment));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.existing == null ? 'Tambah Pembayaran' : 'Edit Pembayaran')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          MoneyInputField(
            controller: _jumlah,
            label: 'Jumlah bayar *',
            validator: (v) =>
                parseRupiah(v ?? '') <= 0 ? 'Jumlah harus lebih dari 0' : null,
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            for (final (label, nilai) in [
              ('50rb', 50000),
              ('100rb', 100000),
              ('200rb', 200000),
              ('500rb', 500000),
            ])
              ActionChip(label: Text(label), onPressed: () => _setJumlah(nilai)),
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _metode,
            decoration: const InputDecoration(labelText: 'Metode'),
            items: const [
              DropdownMenuItem(value: 'tunai', child: Text('Tunai')),
              DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
              DropdownMenuItem(value: 'lainnya', child: Text('Lainnya')),
            ],
            onChanged: (v) => setState(() => _metode = v ?? 'tunai'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range),
            label: Text('Tanggal bayar: ${tampilTanggal(_tanggal)}'),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _tanggal,
                firstDate: DateTime(2015),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                locale: const Locale('id', 'ID'),
              );
              if (picked != null) setState(() => _tanggal = picked);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
              controller: _catatan,
              decoration: const InputDecoration(labelText: 'Catatan (opsional)')),
          const SizedBox(height: 24),
          FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Menyimpan...' : 'Simpan')),
        ]),
      ),
    );
  }
}
```

Wire di `customer_detail_page.dart` (seksi Riwayat Pembayaran, pola Row + TextButton 'Tambah' seperti Task 18; tap item → edit; long-press → hapus via confirm + mutate).

- [ ] **Step 4: Jalankan test, pastikan pass**

```bash
flutter test test/features/payment_form_test.dart
```

Expected: 3 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/payments test/features && git commit -m "feat: form pembayaran + nominal cepat"
```

---

### Task 20: Dashboard

**Files:**
- Create: `lib/features/dashboard/dashboard_page.dart` (ganti stub)

**Interfaces:**
- Consumes: `dashboardProvider`, `customersProvider`.
- Produces: `DashboardPage` — 3 StatCard (Total Piutang, Masuk Bulan Ini, Customer Berhutang), daftar "Hutang terbesar" (top 5, tap → detail), 3 shortcut (Tambah Pembayaran → pilih customer dulu via dialog sederhana berisi list customer, Tambah Customer → form, Tambah Barang → dialog pilih customer → form).

- [ ] **Step 1: Implementasi**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_providers.dart';
import '../../core/utils/money.dart';
import '../../data/models/customer.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stat_card.dart';
import '../customers/customer_form_page.dart';
import '../payments/payment_form_page.dart';
import '../purchases/purchase_form_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  Future<void> _pilihCustomerLalu(BuildContext context, WidgetRef ref,
      Widget Function(String customerId) pageBuilder) async {
    final customers = await ref.read(repoProvider).customers();
    if (!context.mounted) return;
    final chosen = await showModalBottomSheet<Customer>(
      context: context,
      builder: (ctx) => ListView(
        children: [
          for (final c in customers)
            ListTile(
              title: Text(c.customer.nama),
              subtitle: Text('Sisa: ${formatRupiah(c.sisa)}'),
              onTap: () => Navigator.pop(ctx, c.customer),
            ),
        ],
      ),
    );
    if (chosen != null && context.mounted) {
      await Navigator.push(
          context, MaterialPageRoute(builder: (_) => pageBuilder(chosen.id)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardProvider);
    return stats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(message: 'Gagal memuat: $e'),
      data: (s) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardProvider),
        child: ListView(padding: const EdgeInsets.all(12), children: [
          StatCard(label: 'Total Piutang Berjalan', value: formatRupiah(s.totalPiutang)),
          Row(children: [
            Expanded(
                child: StatCard(
                    label: 'Masuk Bulan Ini', value: formatRupiah(s.bayarBulanIni))),
            Expanded(
                child: StatCard(
                    label: 'Customer Berhutang', value: '${s.customerBerhutang}')),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            FilledButton.tonalIcon(
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Pembayaran'),
              onPressed: () => _pilihCustomerLalu(
                  context, ref, (id) => PaymentFormPage(customerId: id)),
            ),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Customer'),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CustomerFormPage())),
            ),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Barang'),
              onPressed: () => _pilihCustomerLalu(
                  context, ref, (id) => PurchaseFormPage(customerId: id)),
            ),
          ]),
          const SizedBox(height: 16),
          Text('Hutang Terbesar', style: Theme.of(context).textTheme.titleMedium),
          if (s.topHutang.isEmpty)
            const ListTile(title: Text('Tidak ada piutang berjalan.')),
          for (final c in s.topHutang)
            ListTile(
              title: Text(c.customer.nama),
              trailing: Text(formatRupiah(c.sisa)),
              onTap: () => context.push('/customers/${c.customer.id}'),
            ),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 2: Verifikasi + commit**

```bash
flutter analyze && flutter test
```

Expected: bersih & pass. Lalu:

```bash
git add lib/features/dashboard && git commit -m "feat: dashboard ringkasan piutang + shortcut aksi"
```

---

### Task 21: Laporan keuntungan (fl_chart)

**Files:**
- Create: `lib/features/reports/reports_page.dart` (ganti stub)

**Interfaces:**
- Consumes: `profitYearlyProvider`, `profitMonthlyProvider`.
- Produces: `ReportsPage` — toggle tahunan/bulanan (bila bulanan: pilih tahun dari tahun yang ada di data), BarChart keuntungan per periode + tabel (periode, qty, penjualan, modal, keuntungan). Catatan di footer: "Barang tanpa harga beli tidak dihitung."

- [ ] **Step 1: Implementasi**

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/logic/profit.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../widgets/empty_state.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});
  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  bool _bulanan = false;
  int? _tahun;

  @override
  Widget build(BuildContext context) {
    final yearly = ref.watch(profitYearlyProvider);
    return yearly.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(message: 'Gagal memuat: $e'),
      data: (years) {
        if (years.isEmpty) {
          return const EmptyState(
              message: 'Belum ada data keuntungan.\nIsi harga beli pada barang.');
        }
        final tahun = _tahun ?? years.last.year;
        if (!_bulanan) return _content(years, 'Tahunan');
        final monthlyAsync = ref.watch(profitMonthlyProvider(tahun));
        return monthlyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(message: 'Gagal memuat: $e'),
          data: (rows) => _content(rows, 'Bulanan $tahun'),
        );
      },
    );
  }

  Widget _content(List<ProfitRow> rows, String judul) {
    final tahunList = ref.read(profitYearlyProvider).value ?? [];
    return ListView(padding: const EdgeInsets.all(12), children: [
      Row(children: [
        Expanded(child: Text('Keuntungan ($judul)',
            style: Theme.of(context).textTheme.titleMedium)),
        DropdownButton<int>(
          value: _tahun ?? tahunList.last.year,
          items: [
            for (final y in tahunList)
              DropdownMenuItem(value: y.year, child: Text('${y.year}')),
          ],
          onChanged: (v) => setState(() {
            _tahun = v;
            _bulanan = true;
          }),
        ),
      ]),
      SizedBox(
        height: 220,
        child: BarChart(BarChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(
              topTitles: AxisTitles(), rightTitles: AxisTitles()),
          barGroups: [
            for (var i = 0; i < rows.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(toY: rows[i].keuntungan / 1000000, width: 18),
              ]),
          ],
        )),
      ),
      const Center(child: Text('Sumbu Y: juta rupiah')),
      const SizedBox(height: 12),
      for (final r in rows)
        ListTile(
          dense: true,
          title: Text(r.month == 0 ? '${r.year}' : bulanTahun(r.year, r.month)),
          subtitle: Text(
              '${r.qty} barang · jual ${formatRupiah(r.penjualan)} · modal ${formatRupiah(r.modal)}'),
          trailing: Text(formatRupiah(r.keuntungan),
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      const Padding(
        padding: EdgeInsets.all(8),
        child: Text('Catatan: barang tanpa harga beli tidak dihitung.'),
      ),
    ]);
  }
}
```

- [ ] **Step 2: Verifikasi + commit**

```bash
flutter analyze && flutter test
```

Expected: bersih & pass. Lalu:

```bash
git add lib/features/reports && git commit -m "feat: laporan keuntungan bulanan/tahunan + grafik"
```

---

### Task 22: Anggaran belanja bulanan

**Files:**
- Create: `lib/features/budget/budget_page.dart` (ganti stub)

**Interfaces:**
- Consumes: `budgetMonthProvider`, `repoProvider.saveBudgetEntry/deleteBudgetEntry` via `mutate`.
- Produces: `BudgetPage` — pemilih bulan (panah kiri/kanan), kartu saldo akhir, list `BudgetLine` (tanggal, nama, +/− jumlah, saldo berjalan), FAB tambah entri (modal bottom sheet: tanggal default hari ini, nama, toggle pemasukan/pengeluaran, `MoneyInputField`), long-press hapus via confirm.

- [ ] **Step 1: Implementasi**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app_providers.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../data/models/budget_entry.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/money_input_field.dart';

class BudgetPage extends ConsumerStatefulWidget {
  const BudgetPage({super.key});
  @override
  ConsumerState<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends ConsumerState<BudgetPage> {
  late DateTime _bulan = DateTime(DateTime.now().year, DateTime.now().month);

  void _geser(int delta) =>
      setState(() => _bulan = DateTime(_bulan.year, _bulan.month + delta));

  Future<void> _tambah() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: const _BudgetEntryForm(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(budgetMonthProvider((_bulan.year, _bulan.month)));
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'budget-fab',
        onPressed: _tambah,
        child: const Icon(Icons.add),
      ),
      body: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _geser(-1)),
          Text(bulanTahun(_bulan.year, _bulan.month),
              style: Theme.of(context).textTheme.titleMedium),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _geser(1)),
        ]),
        Expanded(
          child: data.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(message: 'Gagal memuat: $e'),
            data: (lines) => lines.isEmpty
                ? const EmptyState(message: 'Belum ada transaksi bulan ini.')
                : ListView(children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('Saldo: ${formatRupiah(lines.last.saldo)}',
                          style: Theme.of(context).textTheme.headlineSmall),
                    ),
                    for (final l in lines)
                      ListTile(
                        dense: true,
                        title: Text(l.entry.namaTransaksi),
                        subtitle: Text(tampilTanggal(l.entry.tanggal)),
                        leading: Icon(
                          l.entry.tipe == 'pemasukan'
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: l.entry.tipe == 'pemasukan'
                              ? Colors.green
                              : Colors.red,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                                '${l.entry.tipe == 'pemasukan' ? '+' : '-'}${formatRupiah(l.entry.jumlah)}'),
                            Text('Saldo: ${formatRupiah(l.saldo)}',
                                style: Theme.of(context).textTheme.labelSmall),
                          ],
                        ),
                        onLongPress: () async {
                          if (await confirmDialog(context,
                              title: 'Hapus transaksi?',
                              message: l.entry.namaTransaksi)) {
                            await mutate(ref, () => ref
                                .read(repoProvider)
                                .deleteBudgetEntry(l.entry.id));
                          }
                        },
                      ),
                  ]),
          ),
        ),
      ]),
    );
  }
}

class _BudgetEntryForm extends ConsumerStatefulWidget {
  const _BudgetEntryForm();
  @override
  ConsumerState<_BudgetEntryForm> createState() => _BudgetEntryFormState();
}

class _BudgetEntryFormState extends ConsumerState<_BudgetEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _jumlah = TextEditingController();
  String _tipe = 'pengeluaran';
  DateTime _tanggal = today();

  @override
  void dispose() {
    _nama.dispose();
    _jumlah.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final now = DateTime.now().toUtc();
    await mutate(ref, () => ref.read(repoProvider).saveBudgetEntry(BudgetEntry(
          id: const Uuid().v4(),
          tanggal: _tanggal,
          namaTransaksi: _nama.text.trim(),
          tipe: _tipe,
          jumlah: parseRupiah(_jumlah.text),
          createdAt: now,
          updatedAt: now,
        )));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'pengeluaran', label: Text('Pengeluaran')),
            ButtonSegment(value: 'pemasukan', label: Text('Pemasukan')),
          ],
          selected: {_tipe},
          onSelectionChanged: (s) => setState(() => _tipe = s.first),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nama,
          decoration: const InputDecoration(labelText: 'Nama transaksi *'),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
        ),
        const SizedBox(height: 12),
        MoneyInputField(
          controller: _jumlah,
          label: 'Jumlah *',
          validator: (v) =>
              parseRupiah(v ?? '') <= 0 ? 'Jumlah harus lebih dari 0' : null,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.date_range),
          label: Text('Tanggal: ${tampilTanggal(_tanggal)}'),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _tanggal,
              firstDate: DateTime(2015),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              locale: const Locale('id', 'ID'),
            );
            if (picked != null) setState(() => _tanggal = picked);
          },
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _save, child: const Text('Simpan')),
      ]),
    );
  }
}
```

- [ ] **Step 2: Verifikasi + commit**

```bash
flutter analyze && flutter test
```

Expected: bersih & pass. Lalu:

```bash
git add lib/features/budget && git commit -m "feat: anggaran belanja bulanan dengan saldo berjalan"
```

---

### Task 23: Pengaturan (profil, tema, status sync, logout)

**Files:**
- Create: `lib/features/settings/settings_page.dart` (ganti stub)
- Create: `lib/core/theme_mode.dart` — `themeModeProvider: NotifierProvider<ThemeModeNotifier, ThemeMode>` (default system; toggle light/dark; persist via shared_preferences key `theme_mode`); wire `themeMode:` di `SandiApp` (`app.dart`).

**Interfaces:**
- Produces: `SettingsPage` — email admin aktif, toggle tema, kartu status sync (terakhir sync, jumlah pending, tombol "Sinkronkan sekarang" — Android saja), tombol Keluar (confirm → `authControllerProvider.notifier.signOut()`).

- [ ] **Step 1: Implementasi `theme_mode.dart` + wire di app.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    SharedPreferences.getInstance().then((p) {
      final v = p.getString('theme_mode');
      if (v == 'light') state = ThemeMode.light;
      if (v == 'dark') state = ThemeMode.dark;
    });
    return ThemeMode.system;
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final p = await SharedPreferences.getInstance();
    await p.setString('theme_mode', mode.name);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
```

Di `SandiApp.build` (`app.dart`): tambahkan `themeMode: ref.watch(themeModeProvider),` ke `MaterialApp.router`.

- [ ] **Step 2: Implementasi `settings_page.dart`**

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme_mode.dart';
import '../../core/utils/dates.dart';
import '../../data/sync/sync_controller.dart';
import '../../widgets/confirm_dialog.dart';
import '../auth/auth_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '-';
    final themeMode = ref.watch(themeModeProvider);
    final sync = ref.watch(syncControllerProvider);
    return ListView(padding: const EdgeInsets.all(12), children: [
      ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(email),
          subtitle: const Text('Admin')),
      SwitchListTile(
        secondary: const Icon(Icons.dark_mode_outlined),
        title: const Text('Mode gelap'),
        value: themeMode == ThemeMode.dark,
        onChanged: (v) => ref
            .read(themeModeProvider.notifier)
            .setMode(v ? ThemeMode.dark : ThemeMode.light),
      ),
      if (!kIsWeb) ...[
        const Divider(),
        ListTile(
          leading: const Icon(Icons.sync),
          title: Text(sync.pending > 0
              ? '${sync.pending} data belum tersinkron'
              : 'Semua data tersinkron'),
          subtitle: Text(sync.lastSync == null
              ? 'Belum pernah sinkron'
              : 'Terakhir: ${tampilTanggal(sync.lastSync!)}'),
          trailing: TextButton(
            onPressed: () =>
                ref.read(syncControllerProvider.notifier).syncNow(),
            child: const Text('Sinkronkan'),
          ),
        ),
      ],
      const Divider(),
      ListTile(
        leading: const Icon(Icons.logout),
        title: const Text('Keluar'),
        onTap: () async {
          if (await confirmDialog(context,
              title: 'Keluar?', message: 'Anda harus login kembali untuk membuka data.')) {
            await ref.read(authControllerProvider.notifier).signOut();
          }
        },
      ),
    ]);
  }
}
```

- [ ] **Step 3: Verifikasi + commit**

```bash
flutter analyze && flutter test
```

Expected: bersih & pass. Lalu:

```bash
git add lib && git commit -m "feat: pengaturan (profil, tema, status sync, logout)"
```

---

### Task 24: Background sync periodik (workmanager, Android, best-effort)

**Files:**
- Modify: `lib/main.dart`
- Create: `lib/data/sync/background_sync.dart`

**Interfaces:**
- Produces: `registerBackgroundSync()` dipanggil dari `main()` hanya di Android (`!kIsWeb && defaultTargetPlatform == TargetPlatform.android`); task periodik ±15 menit menjalankan `SyncEngine.syncAll()` di isolate background (inisialisasi ulang Supabase + drift di callback; kegagalan diabaikan — sync utama tetap via app start/konektivitas/tulis/pull-to-refresh).

- [ ] **Step 1: Implementasi `background_sync.dart`**

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import '../local/app_database.dart';
import '../remote/remote_store.dart';
import 'sync_engine.dart';
import 'sync_state.dart';

const kSyncTask = 'sandiapp-periodic-sync';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Supabase.initialize(
        url: const String.fromEnvironment('SUPABASE_URL'),
        anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      );
      final db = AppDatabase();
      final engine = SyncEngine(db, SupabaseRemoteStore(Supabase.instance.client),
          SyncStateStore(await SharedPreferences.getInstance()));
      await engine.syncAll();
      await db.close();
      return true;
    } catch (_) {
      return false; // best-effort; retrial dijadwalkan workmanager
    }
  });
}

Future<void> registerBackgroundSync() async {
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    kSyncTask,
    kSyncTask,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
  );
}
```

Di `main.dart` tambahkan (setelah Supabase.initialize, sebelum runApp):

```dart
if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
  await registerBackgroundSync();
}
```

(import `package:flutter/foundation.dart` untuk `defaultTargetPlatform`.)

- [ ] **Step 2: Verifikasi kompilasi + commit**

```bash
flutter analyze && flutter test
```

Expected: bersih & pass. (Perilaku background diverifikasi manual di Task 25.) Lalu:

```bash
git add lib && git commit -m "feat: background sync periodik via workmanager (best-effort)"
```

---

### Task 25: Verifikasi akhir + build Android & web

**Files:**
- Tidak ada file baru (hanya perintah + checklist)

- [ ] **Step 1: Quality gate**

```bash
flutter analyze
flutter test
```

Expected: analyze bersih; semua test pass (unit + widget).

- [ ] **Step 2: Build & jalankan di AVD Android**

```bash
flutter emulators --launch Pixel_7_API_35
flutter build apk --debug \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
flutter run -d emulator-5554 \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

- [ ] **Step 3: Checklist manual offline (di AVD)**

1. Login dengan akun admin → dashboard tampil.
2. Tambah customer + barang + pembayaran → muncul di list, sisa hutang benar.
3. Aktifkan airplane mode → banner offline muncul; tambah pembayaran lagi → SyncBadge menunjukkan pending > 0.
4. Matikan airplane mode → dalam ±5 detik pending kembali 0; cek di dashboard Supabase (Table Editor) bahwa row masuk.
5. Buka web build (langkah 4) → data yang sama terlihat (bukti sync dua arah).

- [ ] **Step 4: Build & cek web**

```bash
flutter build web \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
python3 -m http.server 8080 --directory build/web
```

Buka `http://localhost:8080` di browser HP/laptop → login → data sama dengan Android. (Chrome tidak terinstall di mesin; pengujian web bisa via browser lain milik user, atau install chromium.)

- [ ] **Step 5: Commit akhir**

```bash
git add -A && git commit -m "chore: verifikasi MVP admin app"
```

---

## Catatan Self-Review Plan

- **Cakupan spec:** auth multi-admin (T13), customer CRUD (T15-17), purchases (T18), payments (T19), FIFO + saldo (T5, T16), dashboard (T20), laporan keuntungan (T7, T21), anggaran (T6, T22), settings + sync status (T23), offline-first Android + sync (T8, T10, T14, T24), web online-only (T11 RemoteBackend), RLS + placeholder client app (T2), verifikasi (T25). Migrasi Excel: sengaja tidak ada task (keputusan user — fase setelah app stabil).
- **Deviasi kecil dari spec §5:** view SQL `customer_balances` tidak dibuat — saldo dihitung di Dart oleh `AppRepository` (DRY untuk kedua backend, data volume kecil). Konsisten dengan opsi "app-level computation" di spec.
- **Ketergantungan eksternal:** Task 2 dijalankan user di dashboard Supabase; Task 25 butuh URL + anon key. Semua task 3-24 bisa dikerjakan tanpa Supabase aktual (FakeRemoteStore/FakeBackend).


