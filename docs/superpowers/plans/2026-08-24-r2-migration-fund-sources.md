# Migrasi r2 dan Sumber Dana Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mengganti dataset r1 dengan preview r2 yang tervalidasi dan menambahkan pelacakan kepemilikan piutang Sandi/Ika yang konsisten pada web maupun Android offline-first.

**Architecture:** Saldo sumber dana tidak disimpan sebagai angka mutable. Saldo dihitung dari ledger saldo awal/alih modal/penyesuaian, ditambah `harga_jual` transaksi baru, lalu dikurangi pembayaran verified; transaksi dan pembayaran menyimpan `fund_source_id` langsung agar edit, soft-delete, dan retry sync hanya berpengaruh sekali. Preview dan reseed dipisahkan dari cutover production: generator bersifat deterministik, migrator default dry-run, dan penghapusan production hanya lewat RPC transaksional setelah approval eksplisit.

**Tech Stack:** Flutter 3.44.2, Dart 3.12.2, Riverpod, drift/SQLite, Supabase/Postgres/PostgREST, Python 3 + openpyxl melalui `uv`.

**Spec:** `docs/superpowers/specs/2026-08-24-r2-migration-fund-sources-design.md`

## Global Constraints

- Teks UI Bahasa Indonesia; uang selalu integer rupiah; ID baru UUIDv4 client-side.
- Terminologi UI: Nasabah, Transaksi, Pembayaran, Sumber dana, dan Alih modal.
- `jenis`: `barang | pinjaman | investasi | jasa/servis | modal usaha`.
- Soft delete dengan `deleted_at`; Android offline-first drift + sync; web langsung Supabase.
- Invariant: saldo Sandi + saldo Ika = total piutang aktif.
- Dataset kontrol: 46 nasabah, 249 transaksi, 1.069 pembayaran, harga beli Rp877.769.000, harga jual Rp971.417.500, pembayaran Rp854.692.500, piutang Rp116.725.000.
- Saldo pembuka: Sandi Rp36.100.000 dan Ika Rp80.625.000.
- Data historis tidak diberi sumber per transaksi; `fund_source_id` historis tetap null dan diwakili dua ledger saldo awal.
- Production tidak boleh dimutasi sebelum dry-run, backup, review preview, dan approval cutover eksplisit.

---

## File Map

**Migrasi data**

- Create `scripts/migration_r2.py`: parser workbook, normalisasi timeline tanggal, pembentukan dataset, dan validasi murni.
- Create `scripts/prepare_migration_r2.py`: CLI pembuat `PREVIEW_MIGRASI_R2.xlsx`.
- Create `scripts/reseed_data.py`: dry-run, backup, pemanggilan RPC reseed, dan rekonsiliasi.
- Create `test/scripts/test_migration_r2.py`: unit test parser/normalisasi/validasi.
- Create `test/scripts/test_reseed_data.py`: unit test payload dan safety gate tanpa network.
- Generate `ref/PREVIEW_MIGRASI_R2.xlsx`: artefak final yang ditinjau manusia.

**Domain sumber dana**

- Create `lib/data/models/fund_source.dart`: model sumber dana tersinkron.
- Create `lib/data/models/fund_ledger_entry.dart`: model saldo awal, alih modal, dan penyesuaian.
- Create `lib/core/logic/funds.dart`: kalkulasi saldo, invariant, dan saran sumber pembayaran FIFO.
- Create `test/core/logic/funds_test.dart`: TDD seluruh aturan murni.
- Modify `lib/data/models/purchase.dart`: tambah `fundSourceId` nullable.
- Modify `lib/data/models/payment.dart`: tambah `fundSourceId` nullable; jangan mengganti field lama `sumber = admin|client`.
- Modify `test/data/models/models_test.dart`: JSON roundtrip kolom baru dan model baru.

**Persistence dan sync**

- Create `supabase/migrations/0005_fund_sources.sql`: tabel, kolom FK, RLS, trigger, fungsi saldo, dan RPC alih modal.
- Create `supabase/migrations/0006_reseed_business_data.sql`: RPC service-role-only untuk reset + reseed atomik.
- Modify `lib/data/local/app_database.dart`: tabel drift baru, kolom baru, schema version, DAO, dan transaksi alih modal.
- Regenerate `lib/data/local/app_database.g.dart` dengan build_runner.
- Modify `lib/data/repositories/backend.dart`, `lib/data/local/drift_backend.dart`, `lib/data/remote/remote_backend.dart`: kontrak baca sumber/ledger dan tulis pasangan ledger atomik.
- Modify `lib/data/remote/remote_store.dart`: tambah RPC generik.
- Modify `lib/data/sync/sync_engine.dart`: push/pull dua tabel baru sesuai urutan FK.
- Modify `test/fakes/fake_backend.dart`, `test/fakes/fake_remote_store.dart`: dukungan model dan RPC baru.
- Modify `test/data/local/app_database_test.dart`, `test/data/sync/sync_engine_test.dart`: persistence, atomic pair, dirty count, retry, dan resync.

**Repository dan UI**

- Modify `lib/data/repositories/app_repository.dart`: ringkasan sumber, validasi, default FIFO, transfer, dan penyesuaian.
- Modify `lib/app_providers.dart`: provider sumber dana dan invalidation.
- Modify `test/data/repositories/app_repository_test.dart`: perilaku end-to-end repository.
- Modify `lib/features/purchases/purchase_form_page.dart`: segmented control Sandi/Ika untuk transaksi baru.
- Modify `lib/features/payments/payment_form_page.dart`: segmented control sumber yang dikurangi.
- Create `test/features/purchase_form_test.dart`; modify `test/features/payment_form_test.dart`.
- Create `lib/features/budget/fund_summary_section.dart`: ringkasan Sandi/Ika dan indikator konsistensi.
- Create `lib/features/budget/fund_transfer_sheet.dart`: alih modal/penyesuaian.
- Create `lib/features/budget/fund_history_sheet.dart`: riwayat ledger manual.
- Modify `lib/features/budget/budget_page.dart`: integrasi tiga komponen sumber dana.
- Create `test/features/budget_funds_test.dart`: widget tests ringkasan dan sheet.

---

### Task 1: Parser dan Normalisasi Tanggal r2

**Files:**
- Create: `scripts/migration_r2.py`
- Create: `test/scripts/test_migration_r2.py`

**Interfaces:**
- Consumes: sheet `UPDATE` dari r2 dan sheet `TRANSAKSI`/`CICILAN` preview lama.
- Produces: `date_candidates(value) -> tuple[date, ...]`, `normalize_timeline(order, payments, cutoff) -> NormalizedTimeline`, dan `validate_dataset(dataset) -> ValidationReport`.

- [ ] **Step 1: Tulis failing tests kandidat tanggal dan timeline**

```python
class DateNormalizationTest(unittest.TestCase):
    def test_ambiguous_excel_date_has_stored_and_swapped_candidates(self):
        self.assertEqual(
            date_candidates(datetime(2021, 8, 1)),
            (date(2021, 8, 1), date(2021, 1, 8)),
        )

    def test_order_is_swapped_when_installments_would_precede_it(self):
        result = normalize_timeline(
            datetime(2021, 8, 1),
            [datetime(2021, 2, 24), datetime(2021, 3, 29)],
            cutoff=date(2026, 8, 24),
        )
        self.assertEqual(result.order, date(2021, 1, 8))
        self.assertEqual(result.payments, (date(2021, 2, 24), date(2021, 3, 29)))

    def test_late_ambiguous_installment_prefers_fewer_sequence_inversions(self):
        result = normalize_timeline(
            datetime(2020, 12, 30),
            [datetime(2021, 5, 31), datetime(2021, 1, 7)],
            cutoff=date(2026, 8, 24),
        )
        self.assertEqual(result.payments[-1], date(2021, 7, 1))

    def test_future_us_dates_offer_9_and_11_june_candidates(self):
        self.assertIn(date(2026, 6, 9), date_candidates(datetime(2026, 9, 6)))
        self.assertIn(date(2026, 6, 11), date_candidates(datetime(2026, 11, 6)))
```

- [ ] **Step 2: Jalankan tests dan pastikan merah**

Run: `uv run --with openpyxl python -m unittest discover -s test/scripts -p 'test_migration_r2.py' -v`

Expected: FAIL karena modul/fungsi belum ada.

- [ ] **Step 3: Implementasikan normalisasi sebagai pencarian kandidat deterministik**

```python
def date_candidates(value: object) -> tuple[date, ...]:
    stored = coerce_excel_date(value)
    candidates = [stored]
    if stored.day <= 12 and stored.month <= 12 and stored.day != stored.month:
        swapped = date(stored.year, stored.day, stored.month)
        candidates.append(swapped)
    return tuple(dict.fromkeys(candidates))

def normalize_timeline(order, payments, cutoff):
    raw = (coerce_excel_date(order), *(coerce_excel_date(p) for p in payments))
    paths = product(date_candidates(order), *(date_candidates(p) for p in payments))

    def score(path):
        purchase_date, *payment_dates = path
        future = sum(value > cutoff for value in path)
        before_order = sum(value < purchase_date for value in payment_dates)
        inversions = sum(a > b for a, b in pairwise(payment_dates))
        swaps = sum(chosen != original for chosen, original in zip(path, raw))
        return future, before_order, inversions, swaps, path

    chosen = min(paths, key=score)
    metrics = score(chosen)[:4]
    return NormalizedTimeline(
        order=chosen[0],
        payments=tuple(chosen[1:]),
        issues=issues_from_metrics(metrics),
        corrections=corrections_from(raw, chosen),
    )
```

Implementasi harus mempertahankan semua kandidat, skor, dan alasan koreksi untuk
sheet `VALIDASI`; tidak boleh membuat fallback 1 Januari. Urutan kolom cicilan
adalah sinyal, bukan syarat keras, karena workbook mempunyai cicilan yang tidak
selalu dimasukkan berurutan.

- [ ] **Step 4: Tambahkan test anomali yang tidak boleh ditebak diam-diam**

```python
def test_payment_still_before_order_is_reported(self):
    result = normalize_timeline(
        datetime(2026, 8, 20),
        [datetime(2025, 12, 31)],
        cutoff=date(2026, 8, 24),
    )
    self.assertIn('payment_before_order', result.issues)

def test_missing_date_raises_instead_of_using_january_fallback(self):
    with self.assertRaises(DateNormalizationError):
        normalize_timeline(None, [], cutoff=date(2026, 8, 24))
```

- [ ] **Step 5: Jalankan tests sampai hijau**

Run: `uv run --with openpyxl python -m unittest discover -s test/scripts -p 'test_migration_r2.py' -v`

Expected: seluruh test PASS.

- [ ] **Step 6: Commit task**

```bash
git add scripts/migration_r2.py test/scripts/test_migration_r2.py
git commit -m "feat: normalisasi tanggal migrasi r2"
```

### Task 2: Dataset dan Preview Migrasi r2

**Files:**
- Modify: `scripts/migration_r2.py`
- Create: `scripts/prepare_migration_r2.py`
- Modify: `test/scripts/test_migration_r2.py`
- Generate: `ref/PREVIEW_MIGRASI_R2.xlsx`

**Interfaces:**
- Consumes: API Task 1 dan mapping `jenis` dari preview lama berdasarkan `NO`.
- Produces: `MigrationDataset`, `build_dataset(r2_path, legacy_preview_path, cutoff)`, `write_preview(dataset, output_path)`, dan CLI non-network.

- [ ] **Step 1: Tulis failing integration test terhadap workbook nyata**

```python
def test_real_r2_control_totals(self):
    ds = build_dataset(R2, LEGACY, cutoff=date(2026, 8, 24))
    self.assertEqual(len(ds.customers), 46)
    self.assertEqual(len(ds.transactions), 249)
    self.assertEqual(len(ds.payments), 1069)
    self.assertEqual(sum(t.harga_beli for t in ds.transactions), 877_769_000)
    self.assertEqual(sum(t.harga_jual for t in ds.transactions), 971_417_500)
    self.assertEqual(sum(p.jumlah for p in ds.payments), 854_692_500)
    self.assertEqual(sum(t.sisa for t in ds.transactions), 116_725_000)
    self.assertEqual(ds.validation.future_payment_count, 0)
    self.assertEqual(ds.validation.payment_before_order_count, 19)
    self.assertEqual(ds.validation.transactions_with_date_warnings, 17)
```

Tambahkan assertions item final No. 10, 46, 78, 89, 145, 146, dan 245 serta `jenis` selalu termasuk enum yang diperbolehkan.

- [ ] **Step 2: Jalankan test dan pastikan merah**

Run: `uv run --with openpyxl python -m unittest discover -s test/scripts -p 'test_migration_r2.py' -v`

Expected: FAIL karena `build_dataset` belum ada.

- [ ] **Step 3: Implementasikan parser row dan koreksi item eksplisit**

```python
ITEM_FIXES = {
    10: "AC Mobil",
    46: "Pinjaman",
    78: "Freezer",
    89: "Spare Part Mobil",
    145: "Lain-lain",
    146: "Lain-lain",
    245: "Shockbreaker",
}
ALLOWED_JENIS = {"barang", "pinjaman", "investasi", "jasa/servis", "modal usaha"}
OPENING_FUNDS = {"Sandi": 36_100_000, "Ika": 80_625_000}
```

Gunakan nomor transaksi 1-249 sebagai join key. Nominal cicilan harus dibaca dari pasangan kolom tanggal/nominal tanpa mengubah urutan.

- [ ] **Step 4: Implementasikan validasi keras dan CLI**

```python
def main() -> int:
    args = parser.parse_args()
    dataset = build_dataset(args.input, args.legacy_preview, args.cutoff)
    report = validate_dataset(dataset)
    if not report.ok:
        for error in report.errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    write_preview(dataset, args.output)
    print(report.summary)
    return 0
```

CLI default input/output mengikuti path repo, tetapi menerima override agar test memakai temporary directory.

- [ ] **Step 5: Jalankan generator dan inspeksi workbook**

Run:

```bash
uv run --with openpyxl python scripts/prepare_migration_r2.py \
  --input "ref/DAFTAR KREDIT BARANG r2.xlsx" \
  --legacy-preview ref/PREVIEW_MIGRASI.xlsx \
  --output ref/PREVIEW_MIGRASI_R2.xlsx \
  --cutoff 2026-08-24
```

Expected: exit 0, lima sheet dibuat, semua nilai kontrol tercetak, tidak ada
tanggal kosong/fallback/future, dan 19 pembayaran pada 17 transaksi dicatat
sebagai warning `payment_before_order` untuk pemeriksaan manual.

- [ ] **Step 6: Verifikasi artefak dengan load ulang**

Run: `uv run --with openpyxl python scripts/prepare_migration_r2.py --verify-only --output ref/PREVIEW_MIGRASI_R2.xlsx`

Expected: `VALID WITH 19 DATE WARNINGS: 46 nasabah, 249 transaksi, 1069 pembayaran, piutang Rp116.725.000`.

- [ ] **Step 7: Commit task**

```bash
git add scripts/migration_r2.py scripts/prepare_migration_r2.py test/scripts/test_migration_r2.py ref/PREVIEW_MIGRASI_R2.xlsx
git commit -m "feat: buat preview migrasi r2 tervalidasi"
```

### Task 3: Model dan Logika Murni Sumber Dana

**Files:**
- Create: `lib/data/models/fund_source.dart`
- Create: `lib/data/models/fund_ledger_entry.dart`
- Create: `lib/core/logic/funds.dart`
- Create: `test/core/logic/funds_test.dart`
- Modify: `lib/data/models/purchase.dart`
- Modify: `lib/data/models/payment.dart`
- Modify: `test/data/models/models_test.dart`

**Interfaces:**
- Produces: `FundSource`, `FundLedgerEntry`, `FundTransfer`, `FundBalance`, `FundSummary`, `calculateFundSummary({sources, ledger, purchases, payments, totalPiutang})`, dan nullable `Purchase.fundSourceId`/`Payment.fundSourceId`.
- Consumes later: repository, drift, sync, providers, dan UI.

- [ ] **Step 1: Tulis failing tests model JSON dan kalkulasi saldo**

```dart
test('saldo sumber = ledger + transaksi - pembayaran verified', () {
  final result = calculateFundSummary(
    sources: [sandi, ika],
    ledger: [opening(sandi.id, 36100000), opening(ika.id, 80625000)],
    purchases: [purchase(jual: 2000000, fundSourceId: sandi.id)],
    payments: [payment(jumlah: 500000, fundSourceId: sandi.id)],
    totalPiutang: 118225000,
  );
  expect(result.bySourceId(sandi.id).saldo, 37600000);
  expect(result.total, 118225000);
  expect(result.isConsistent, isTrue);
});

test('payment pending tidak mengurangi sumber', () {
  final pending = payment(
      jumlah: 500000, fundSourceId: sandi.id, status: 'pending');
  final result = calculateFundSummary(
    sources: [sandi, ika],
    ledger: [opening(sandi.id, 36100000), opening(ika.id, 80625000)],
    purchases: const [],
    payments: [pending],
    totalPiutang: 116725000,
  );
  expect(result.bySourceId(sandi.id).saldo, 36100000);
});

test('soft-deleted rows tidak masuk kalkulasi', () {
  final deletedPurchase = purchase(
      jual: 2000000, fundSourceId: sandi.id, deletedAt: t0);
  final result = calculateFundSummary(
    sources: [sandi, ika],
    ledger: [opening(sandi.id, 36100000), opening(ika.id, 80625000)],
    purchases: [deletedPurchase],
    payments: const [],
    totalPiutang: 116725000,
  );
  expect(result.total, 116725000);
});

test('transfer berpasangan menjaga total nol', () {
  final transfer = fundTransfer(
      from: sandi.id, to: ika.id, amount: 1000000);
  expect(transfer.keluar.jumlahDelta, -1000000);
  expect(transfer.masuk.jumlahDelta, 1000000);
  expect(transfer.keluar.jumlahDelta + transfer.masuk.jumlahDelta, 0);
});
```

- [ ] **Step 2: Jalankan test dan pastikan merah**

Run: `flutter test test/core/logic/funds_test.dart test/data/models/models_test.dart`

Expected: FAIL karena types dan fields belum ada.

- [ ] **Step 3: Implementasikan model immutable dan JSON keys**

```dart
class FundSource {
  final String id, nama, colorKey;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt, updatedAt;
  final DateTime? deletedAt;
  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'color_key': colorKey,
    'is_active': isActive,
    'created_by': createdBy,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'deleted_at': deletedAt?.toIso8601String(),
  };
}

class FundLedgerEntry {
  final String id, fundSourceId, tipe, referenceType;
  final int jumlahDelta;
  final DateTime tanggal, createdAt, updatedAt;
  final String? referenceId, transferGroupId, catatan, createdBy;
  final DateTime? deletedAt;
}

class FundTransfer {
  final FundLedgerEntry keluar;
  final FundLedgerEntry masuk;
  const FundTransfer({required this.keluar, required this.masuk});
}

class FundBalance {
  final FundSource source;
  final int saldo;
  const FundBalance({required this.source, required this.saldo});
}

class FundSummary {
  final List<FundBalance> balances;
  final int totalPiutang;
  const FundSummary({required this.balances, required this.totalPiutang});
  factory FundSummary.fromBalances(
      List<FundSource> sources, Map<String, int> values,
      {required int totalPiutang}) => FundSummary(
        balances: [
          for (final source in sources)
            FundBalance(source: source, saldo: values[source.id] ?? 0),
        ],
        totalPiutang: totalPiutang,
      );
  int get total => balances.fold(0, (sum, row) => sum + row.saldo);
  bool get isConsistent => total == totalPiutang;
  FundBalance bySourceId(String id) =>
      balances.singleWhere((row) => row.source.id == id);
  FundBalance bySourceName(String name) =>
      balances.singleWhere((row) => row.source.nama == name);
}
```

Tambahkan key `fund_source_id` nullable pada `Purchase.toJson/fromJson/copyWith` dan `Payment.toJson/fromJson/copyWith`. Field `Payment.sumber` lama tetap utuh.

- [ ] **Step 4: Implementasikan kalkulasi murni**

```dart
FundSummary calculateFundSummary({
  required List<FundSource> sources,
  required List<FundLedgerEntry> ledger,
  required List<Purchase> purchases,
  required List<Payment> payments,
  required int totalPiutang,
}) {
  final saldo = {for (final s in sources) s.id: 0};
  for (final e in ledger.where((e) => e.deletedAt == null)) {
    saldo.update(e.fundSourceId, (v) => v + e.jumlahDelta);
  }
  for (final p in purchases.where((p) => p.deletedAt == null && p.fundSourceId != null)) {
    saldo.update(p.fundSourceId!, (v) => v + p.hargaJual);
  }
  for (final p in payments.where((p) =>
      p.deletedAt == null && p.statusVerifikasi == 'verified' && p.fundSourceId != null)) {
    saldo.update(p.fundSourceId!, (v) => v - p.jumlah);
  }
  return FundSummary.fromBalances(sources, saldo, totalPiutang: totalPiutang);
}
```

- [ ] **Step 5: Jalankan tests sampai hijau**

Run: `flutter test test/core/logic/funds_test.dart test/data/models/models_test.dart`

Expected: PASS.

- [ ] **Step 6: Commit task**

```bash
git add lib/core/logic/funds.dart lib/data/models/fund_source.dart lib/data/models/fund_ledger_entry.dart lib/data/models/purchase.dart lib/data/models/payment.dart test/core/logic/funds_test.dart test/data/models/models_test.dart
git commit -m "feat: tambah domain sumber dana"
```

### Task 4: Schema Supabase dan Drift

**Files:**
- Create: `supabase/migrations/0005_fund_sources.sql`
- Modify: `lib/data/local/app_database.dart`
- Regenerate: `lib/data/local/app_database.g.dart`
- Modify: `test/data/local/app_database_test.dart`

**Interfaces:**
- Consumes: model Task 3.
- Produces: tabel `fund_sources`, `fund_ledger_entries`, kolom `fund_source_id`, DAO aktif/dirty/apply remote, dan `writeFundTransferAtomic(FundTransfer)`.

- [ ] **Step 1: Tulis failing Drift tests**

```dart
test('fund source dan ledger roundtrip + dirty count', () async {
  await db.upsertFundSourceRow(sandi.toCompanion(dirty: true));
  await db.upsertFundLedgerEntryRow(opening.toCompanion(dirty: true));
  expect((await db.activeFundSources()).single.nama, 'Sandi');
  expect((await db.activeFundLedgerEntries()).single.jumlahDelta, 36100000);
  expect(await db.dirtyCount(), 2);
});

test('writeFundTransferAtomic menulis dua delta satu group', () async {
  await db.writeFundTransferAtomic(transfer);
  final rows = await db.activeFundLedgerEntries();
  expect(rows.map((r) => r.jumlahDelta), containsAll([-1000000, 1000000]));
  expect(rows.map((r) => r.transferGroupId).toSet(), {transfer.keluar.transferGroupId});
});
```

- [ ] **Step 2: Jalankan test dan pastikan merah**

Run: `flutter test test/data/local/app_database_test.dart`

Expected: compile FAIL karena tabel/DAO belum ada.

- [ ] **Step 3: Tambahkan migration SQL**

`0005_fund_sources.sql` harus:

```sql
alter table public.purchases add column if not exists fund_source_id uuid null;
alter table public.payments add column if not exists fund_source_id uuid null;

create table if not exists public.fund_sources (
  id uuid primary key,
  nama text not null unique,
  color_key text not null check (color_key in ('green', 'gold')),
  is_active boolean not null default true,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.fund_ledger_entries (
  id uuid primary key,
  fund_source_id uuid not null references public.fund_sources(id),
  tanggal date not null,
  tipe text not null check (tipe in
    ('saldo_awal', 'alih_masuk', 'alih_keluar', 'penyesuaian')),
  jumlah_delta bigint not null check (jumlah_delta <> 0),
  reference_type text not null check (reference_type in
    ('migration', 'transfer', 'adjustment')),
  reference_id uuid,
  transfer_group_id uuid,
  catatan text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

alter table public.purchases
  add constraint purchases_fund_source_fk foreign key (fund_source_id)
  references public.fund_sources(id);
alter table public.payments
  add constraint payments_fund_source_fk foreign key (fund_source_id)
  references public.fund_sources(id);

alter table public.fund_sources enable row level security;
alter table public.fund_ledger_entries enable row level security;
create policy "admin_all_fund_sources" on public.fund_sources
  for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admin_all_fund_ledger" on public.fund_ledger_entries
  for all to authenticated using (public.is_admin()) with check (public.is_admin());
```

Tambahkan check constraints enum, index FK/`updated_at`, trigger `set_updated_at`, dan seed Sandi/Ika dengan UUID tetap. Gunakan blok `DO` untuk FK/policy agar migration aman dijalankan ulang.

Gunakan seed IDs tetap agar preview, web, dan Android merujuk sumber yang sama:

```sql
insert into public.fund_sources (id, nama, color_key)
values
  ('00000000-0000-4000-8000-000000000001', 'Sandi', 'green'),
  ('00000000-0000-4000-8000-000000000002', 'Ika', 'gold')
on conflict (id) do update
set nama = excluded.nama, color_key = excluded.color_key, deleted_at = null;
```

Tambahkan fungsi `public.fund_source_balance(uuid)` yang menjumlah ledger aktif,
purchase aktif, dan payment verified aktif. Tambahkan RPC atomik dengan signature:

```sql
public.record_fund_transfer(
  p_group_id uuid,
  p_out_id uuid,
  p_in_id uuid,
  p_from_source_id uuid,
  p_to_source_id uuid,
  p_amount bigint,
  p_tanggal date,
  p_kind text,
  p_catatan text
) returns jsonb
```

RPC menolak sumber sama, nominal `<= 0`, saldo asal kurang, `p_kind` selain
`transfer|adjustment`, dan adjustment tanpa catatan. Bila `p_group_id` sudah ada,
RPC mengembalikan pasangan existing tanpa insert ulang. Selain itu RPC memasukkan
dua row `-p_amount/+p_amount` dalam satu transaksi statement dan mengembalikan
`{"transfer_group_id": p_group_id, "amount": p_amount}`.

- [ ] **Step 4: Tambahkan tabel Drift dan upgrade v4**

```dart
@DriftDatabase(tables: [Customers, Purchases, Payments, BudgetEntries,
  FundSources, FundLedgerEntries])
class AppDatabase extends _$AppDatabase {
  @override
  int get schemaVersion => 4;
}
```

Pada `from < 4`, buat dua tabel baru dan tambah kolom `fundSourceId` pada purchases/payments. Implementasi transaksi lokal:

```dart
Future<void> writeFundTransferAtomic(FundTransfer transfer) => transaction(() async {
  await into(fundLedgerEntries)
      .insertOnConflictUpdate(transfer.keluar.toCompanion(dirty: true));
  await into(fundLedgerEntries)
      .insertOnConflictUpdate(transfer.masuk.toCompanion(dirty: true));
});
```

- [ ] **Step 5: Jalankan codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`

Expected: exit 0 dan `app_database.g.dart` mencakup dua tabel/dua kolom baru.

- [ ] **Step 6: Jalankan tests**

Run: `flutter test test/data/local/app_database_test.dart test/data/models/models_test.dart`

Expected: PASS.

- [ ] **Step 7: Commit task**

```bash
git add supabase/migrations/0005_fund_sources.sql lib/data/local/app_database.dart lib/data/local/app_database.g.dart test/data/local/app_database_test.dart
git commit -m "feat: tambah penyimpanan sumber dana"
```

### Task 5: Backend dan Sinkronisasi Sumber Dana

**Files:**
- Modify: `lib/data/repositories/backend.dart`
- Modify: `lib/data/local/drift_backend.dart`
- Modify: `lib/data/remote/remote_backend.dart`
- Modify: `lib/data/remote/remote_store.dart`
- Modify: `lib/data/sync/sync_engine.dart`
- Modify: `test/fakes/fake_backend.dart`
- Modify: `test/fakes/fake_remote_store.dart`
- Modify: `test/data/sync/sync_engine_test.dart`

**Interfaces:**
- Produces backend methods `readFundSources()`, `readFundLedgerEntries()`, dan `writeFundTransfer(FundTransfer transfer)`.
- Produces `RemoteStore.rpc(String name, Map<String, dynamic> params)`.

- [ ] **Step 1: Tulis failing sync tests**

```dart
test('sync fund source sebelum purchase dan ledger sesudah payment', () async {
  await db.upsertFundSourceRow(sandi.toCompanion(dirty: true));
  await db.upsertFundLedgerEntryRow(opening.toCompanion(dirty: true));
  await engine.syncAll();
  expect(remote.tableOrder, containsAllInOrder([
    'fund_sources', 'customers', 'purchases', 'payments', 'fund_ledger_entries'
  ]));
  expect(await db.dirtyCount(), 0);
});

test('resyncAll membersihkan watermark tabel sumber dana', () async {
  await engine.resyncAll();
  expect(await state.lastPull('fund_sources'), isNotNull);
});
```

- [ ] **Step 2: Jalankan test dan pastikan merah**

Run: `flutter test test/data/sync/sync_engine_test.dart`

Expected: compile/test FAIL karena kontrak belum ditambah.

- [ ] **Step 3: Perluas Backend dan implementasi platform**

```dart
abstract class Backend {
  Future<List<FundSource>> readFundSources();
  Future<List<FundLedgerEntry>> readFundLedgerEntries();
  Future<void> writeFundTransfer(FundTransfer transfer);
}
```

`DriftBackend.writeFundTransfer` memanggil transaksi database Task 4. `RemoteBackend.writeFundTransfer` memanggil RPC `record_fund_transfer` dengan ID group/row stabil, tanggal, nominal, jenis, dan catatan.

- [ ] **Step 4: Implementasikan RPC store dan fake**

```dart
Future<Map<String, dynamic>> rpc(String name, Map<String, dynamic> params);

@override
Future<Map<String, dynamic>> rpc(String name, Map<String, dynamic> params) async {
  final result = await _client.rpc(name, params: params);
  return Map<String, dynamic>.from(result as Map);
}
```

Fake menyimpan dua entry dengan `transfer_group_id` sama dan mengabaikan retry group yang sudah ada.

- [ ] **Step 5: Tambahkan push/pull dua tabel**

Set `SyncEngine.tables` menjadi:

```dart
[
  'fund_sources',
  'customers',
  'purchases',
  'payments',
  'fund_ledger_entries',
  'budget_entries',
]
```

Implementasikan `_syncFundSources` dan `_syncFundLedgerEntries` dengan kontrak konkret berikut:

```dart
Future<void> _syncFundSources() async {
  final dirty = await db.dirtyFundSourceRows();
  if (dirty.isNotEmpty) {
    await remote.upsert('fund_sources',
        [for (final row in dirty) row.toModel().toJson()]);
    await db.clearFundSourcesDirty([for (final row in dirty) row.id]);
  }
  await _pull('fund_sources', (rows) => db.applyRemoteFundSources(
      [for (final json in rows) FundSource.fromJson(json)]));
}

Future<void> _syncFundLedgerEntries() async {
  final dirty = await db.dirtyFundLedgerEntryRows();
  if (dirty.isNotEmpty) {
    await remote.upsert('fund_ledger_entries',
        [for (final row in dirty) row.toModel().toJson()]);
    await db.clearFundLedgerEntriesDirty([for (final row in dirty) row.id]);
  }
  await _pull('fund_ledger_entries', (rows) => db.applyRemoteFundLedgerEntries(
      [for (final json in rows) FundLedgerEntry.fromJson(json)]));
}
```

- [ ] **Step 6: Jalankan tests sync dan backend**

Run: `flutter test test/data/sync/sync_engine_test.dart test/data/local/app_database_test.dart`

Expected: PASS dan dirty count kembali nol.

- [ ] **Step 7: Commit task**

```bash
git add lib/data/repositories/backend.dart lib/data/local/drift_backend.dart lib/data/remote/remote_backend.dart lib/data/remote/remote_store.dart lib/data/sync/sync_engine.dart test/fakes/fake_backend.dart test/fakes/fake_remote_store.dart test/data/sync/sync_engine_test.dart
git commit -m "feat: sinkronkan sumber dana offline"
```

### Task 6: Repository, Invariant, dan Alih Modal

**Files:**
- Modify: `lib/data/repositories/app_repository.dart`
- Modify: `lib/app_providers.dart`
- Modify: `test/data/repositories/app_repository_test.dart`

**Interfaces:**
- Produces `Future<List<FundSource>> fundSources()`, `Future<FundSummary> fundSummary()`, `Future<List<FundLedgerEntry>> fundHistory()`, `Future<String?> suggestedPaymentFundSource(String customerId)`, `Future<void> transferFund(FundTransfer transfer)`, dan `Future<void> adjustFund(FundTransfer adjustment)`.

- [ ] **Step 1: Tulis failing repository tests**

```dart
test('fundSummary cocok dengan total piutang', () async {
  final summary = await repo.fundSummary();
  expect(summary.total, summary.totalPiutang);
  expect(summary.isConsistent, isTrue);
});

test('transaksi baru tanpa sumber ditolak, edit historis null tetap boleh', () async {
  expect(() => repo.savePurchase(newPurchaseWithoutSource), throwsArgumentError);
  await repo.savePurchase(existingHistoricalPurchase.copyWith(namaBarang: 'Edit'));
});

test('pembayaran ditolak jika membuat saldo sumber negatif', () async {
  expect(() => repo.savePayment(paymentOverSandiBalance), throwsStateError);
});

test('alih modal Sandi ke Ika menjaga total', () async {
  await repo.transferFund(transfer1000000);
  final summary = await repo.fundSummary();
  expect(summary.bySourceName('Sandi').saldo, 35100000);
  expect(summary.bySourceName('Ika').saldo, 81625000);
  expect(summary.total, 116725000);
});
```

- [ ] **Step 2: Jalankan tests dan pastikan merah**

Run: `flutter test test/data/repositories/app_repository_test.dart`

Expected: compile/test FAIL pada methods baru.

- [ ] **Step 3: Implementasikan summary dan validasi write**

`fundSummary()` membaca semua sumber/ledger/purchase/payment dan memakai `balanceOf` untuk total piutang. `savePurchase`/`savePayment` memeriksa apakah ID sudah ada: row baru wajib punya sumber, sedangkan row historis existing dengan null boleh diedit tanpa mengarang atribusi.

Sebelum pembayaran baru, hitung saldo sumber dan tolak bila `jumlah > saldo`. Pembayaran pending/rejected tidak memengaruhi validasi saldo.

- [ ] **Step 4: Implementasikan saran FIFO**

```dart
Future<String?> suggestedPaymentFundSource(String customerId) async {
  final purchases = (await backend.readPurchases())
      .where((p) => p.customerId == customerId).toList();
  final payments = (await backend.readPayments())
      .where((p) => p.customerId == customerId && p.statusVerifikasi == 'verified')
      .toList();
  final totalPaid = payments.fold<int>(0, (sum, payment) => sum + payment.jumlah);
  final statuses = allocateFifo(purchases, totalPaid);
  return statuses
      .where((s) => s.sisa > 0)
      .map((s) => s.purchase.fundSourceId)
      .firstOrNull;
}
```

Jika purchase FIFO aktif masih historis (`null`), hasil null agar admin memilih sendiri.

- [ ] **Step 5: Implementasikan transfer/adjustment**

Validasi sumber berbeda, nominal positif, saldo asal cukup, dua delta berlawanan, group sama, dan catatan wajib untuk `penyesuaian`. Panggil satu `backend.writeFundTransfer` lalu satu `onLocalWrite`.

- [ ] **Step 6: Tambahkan providers dan invalidation**

```dart
final fundSummaryProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(repoProvider).fundSummary());
final fundHistoryProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(repoProvider).fundHistory());
final fundSourcesProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(repoProvider).fundSources());
```

Tambahkan ketiganya ke `invalidateAllData`.

- [ ] **Step 7: Jalankan tests**

Run: `flutter test test/data/repositories/app_repository_test.dart test/core/logic/funds_test.dart`

Expected: PASS.

- [ ] **Step 8: Commit task**

```bash
git add lib/data/repositories/app_repository.dart lib/app_providers.dart test/data/repositories/app_repository_test.dart
git commit -m "feat: kelola saldo dan alih modal"
```

### Task 7: Input Sumber pada Transaksi dan Pembayaran

**Files:**
- Modify: `lib/features/purchases/purchase_form_page.dart`
- Modify: `lib/features/payments/payment_form_page.dart`
- Create: `test/features/purchase_form_test.dart`
- Modify: `test/features/payment_form_test.dart`

**Interfaces:**
- Consumes: `fundSourcesProvider`, `suggestedPaymentFundSource`, dan fields Task 3.
- Produces: transaksi/pembayaran baru yang selalu memiliki `fundSourceId`.

- [ ] **Step 1: Tulis failing widget tests transaksi**

```dart
testWidgets('transaksi baru wajib memilih sumber dana', (tester) async {
  await pumpPurchaseForm(tester, backendWithSandiIka);
  await fillRequiredPurchaseFields(tester);
  await tester.tap(find.text('Simpan'));
  await tester.pump();
  expect(find.text('Pilih sumber dana'), findsOneWidget);
});

testWidgets('pilihan Sandi tersimpan pada transaksi', (tester) async {
  await pumpPurchaseForm(tester, backendWithSandiIka);
  await tester.tap(find.text('Sandi'));
  await fillRequiredPurchaseFields(tester);
  await tester.tap(find.text('Simpan'));
  await tester.pumpAndSettle();
  expect(backend.purchases.single.fundSourceId, sandi.id);
});
```

- [ ] **Step 2: Tulis failing widget tests pembayaran**

```dart
testWidgets('pembayaran menampilkan Mengurangi dana', (tester) async {
  await pumpPaymentForm(tester, backendWithSandiIka);
  expect(find.text('Mengurangi dana'), findsOneWidget);
  expect(find.text('Sandi'), findsOneWidget);
  expect(find.text('Ika'), findsOneWidget);
});
```

Tambahkan test default FIFO dan kasus historis tanpa default.

- [ ] **Step 3: Jalankan tests dan pastikan merah**

Run: `flutter test test/features/purchase_form_test.dart test/features/payment_form_test.dart`

Expected: FAIL karena control belum ada.

- [ ] **Step 4: Implementasikan source selector reusable secara lokal**

Gunakan `SegmentedButton<String>` dengan label teks, indikator hijau untuk Sandi dan emas untuk Ika. Jangan memakai warna sebagai satu-satunya pembeda. Saat sources loading, tombol Simpan disabled; saat error tampil pesan Bahasa Indonesia.

Transaksi baru wajib memilih; transaksi historis existing dengan null menampilkan `Saldo awal` dan tetap boleh disimpan. Pembayaran baru memuat default repository, tetapi admin dapat mengganti sebelum Simpan.

- [ ] **Step 5: Jalankan widget tests**

Run: `flutter test test/features/purchase_form_test.dart test/features/payment_form_test.dart`

Expected: PASS tanpa overflow/exceptions.

- [ ] **Step 6: Commit task**

```bash
git add lib/features/purchases/purchase_form_page.dart lib/features/payments/payment_form_page.dart test/features/purchase_form_test.dart test/features/payment_form_test.dart
git commit -m "feat: pilih sumber pada transaksi dan pembayaran"
```

### Task 8: Ringkasan, Riwayat, dan Alih Modal di Anggaran

**Files:**
- Create: `lib/features/budget/fund_summary_section.dart`
- Create: `lib/features/budget/fund_transfer_sheet.dart`
- Create: `lib/features/budget/fund_history_sheet.dart`
- Modify: `lib/features/budget/budget_page.dart`
- Create: `test/features/budget_funds_test.dart`

**Interfaces:**
- Consumes: fund providers dan repository Task 6.
- Produces: UI Anggaran sumber dana lengkap.

- [ ] **Step 1: Tulis failing widget test ringkasan**

```dart
testWidgets('menampilkan Sandi, Ika, total piutang, dan saldo', (tester) async {
  await pumpBudget(tester, seededBackend);
  expect(find.text('Sumber dana'), findsOneWidget);
  expect(find.text('Sandi'), findsOneWidget);
  expect(find.text('Rp 36.100.000'), findsOneWidget);
  expect(find.text('Ika'), findsOneWidget);
  expect(find.text('Rp 80.625.000'), findsOneWidget);
  expect(find.text('Rp 116.725.000'), findsWidgets);
});
```

Tambahkan test warning saat invariant salah dan semantics label tetap ada tanpa bergantung warna.

- [ ] **Step 2: Tulis failing test alih modal**

```dart
testWidgets('alih modal mengurangi Sandi dan menambah Ika', (tester) async {
  await pumpBudget(tester, seededBackend);
  await tester.tap(find.byTooltip('Alih modal'));
  await tester.enterText(find.byKey(const Key('fund-transfer-amount')), '1.000.000');
  await tester.tap(find.text('Simpan'));
  await tester.pumpAndSettle();
  expect(find.text('Rp 35.100.000'), findsOneWidget);
  expect(find.text('Rp 81.625.000'), findsOneWidget);
});
```

- [ ] **Step 3: Jalankan test dan pastikan merah**

Run: `flutter test test/features/budget_funds_test.dart`

Expected: compile/test FAIL karena widgets belum ada.

- [ ] **Step 4: Implementasikan summary section**

Gunakan band penuh dengan dua kolom responsif, swatch kecil, label, nominal, total piutang, serta icon buttons `swap_horiz`, `history`, dan `edit` dengan tooltip. Sandi memakai `colorScheme.tertiary`; Ika memakai `colorScheme.primary`. Jangan menaruh card di dalam card.

- [ ] **Step 5: Implementasikan transfer dan penyesuaian sheet**

Transfer sheet berisi sumber asal/tujuan, `MoneyInputField`, tanggal, catatan opsional, dan validasi saldo. Penyesuaian memakai alur sama tetapi catatan wajib. Simpan membuat `FundTransfer` dengan tiga UUIDv4 stabil untuk group/keluar/masuk sebelum memanggil repository.

- [ ] **Step 6: Implementasikan history sheet**

Urutkan ledger terbaru dahulu. Tampilkan tanggal, jenis, sumber, delta bertanda, dan catatan. Group transfer ditampilkan sebagai satu baris `Sandi -> Ika` agar klien tidak melihat dua row teknis terpisah.

- [ ] **Step 7: Integrasikan ke BudgetPage dan jalankan tests**

Run: `flutter test test/features/budget_funds_test.dart test/core/logic/budget_test.dart`

Expected: PASS.

- [ ] **Step 8: Commit task**

```bash
git add lib/features/budget/fund_summary_section.dart lib/features/budget/fund_transfer_sheet.dart lib/features/budget/fund_history_sheet.dart lib/features/budget/budget_page.dart test/features/budget_funds_test.dart
git commit -m "feat: tampilkan sumber dana di anggaran"
```

### Task 9: Migrator Dry-run, Backup, dan Reseed Atomik

**Files:**
- Create: `supabase/migrations/0006_reseed_business_data.sql`
- Create: `scripts/reseed_data.py`
- Create: `test/scripts/test_reseed_data.py`
- Modify: `.gitignore`
- Modify: `README.md`

**Interfaces:**
- Consumes: `PREVIEW_MIGRASI_R2.xlsx` dan schema Task 4.
- Produces: `build_reseed_payload`, `backup_tables`, `reconcile_remote`, CLI default dry-run, dan RPC `reseed_business_data_v2(jsonb)` service-role-only.

- [ ] **Step 1: Tulis failing safety tests**

```python
class ReseedSafetyTest(unittest.TestCase):
    def test_default_mode_never_calls_network_write(self):
        client = FakeClient()
        run_reseed(PREVIEW, client=client, apply=False)
        self.assertEqual(client.write_calls, [])

    def test_apply_requires_exact_confirmation_phrase(self):
        with self.assertRaises(SafetyError):
            run_reseed(PREVIEW, client=FakeClient(), apply=True, confirmation="yes")

    def test_payload_has_control_counts_and_opening_balances(self):
        payload = build_reseed_payload(PREVIEW)
        self.assertEqual(len(payload["customers"]), 46)
        self.assertEqual(len(payload["purchases"]), 249)
        self.assertEqual(len(payload["payments"]), 1069)
        self.assertEqual(sum(x["jumlah_delta"] for x in payload["fund_ledger_entries"]), 116_725_000)
```

- [ ] **Step 2: Jalankan tests dan pastikan merah**

Run: `uv run --with openpyxl,requests python -m unittest discover -s test/scripts -p 'test_reseed_data.py' -v`

Expected: FAIL karena script belum ada.

- [ ] **Step 3: Implementasikan RPC transaksional service-role-only**

Function SQL harus memvalidasi count dan total dari JSON sebelum delete. Di dalam satu function transaction:

```sql
delete from public.fund_ledger_entries;
delete from public.budget_entries;
delete from public.payments;
delete from public.purchases;
delete from public.customers;
delete from public.fund_sources;
-- jsonb_to_recordset inserts untuk sources, customers, purchases, payments, ledger.
```

Revoke dari `public`, `anon`, dan `authenticated`; grant hanya `service_role`. Function mengembalikan JSON count/total hasil insert dan melempar exception bila rekonsiliasi gagal agar seluruh transaksi rollback.

- [ ] **Step 4: Implementasikan CLI dengan backup wajib**

```text
python scripts/reseed_data.py                     # dry-run lokal
python scripts/reseed_data.py --remote-check      # read-only Supabase
python scripts/reseed_data.py --apply \
  --confirm-reset RESET-BUSINESS-DATA             # backup lalu RPC
```

Sebelum RPC apply, baca semua row business termasuk soft-delete secara paginated dan tulis JSON ke `backups/reseed-<UTC timestamp>/`. Jangan log service role key. Tambahkan `backups/` ke `.gitignore`.

- [ ] **Step 5: Implementasikan rekonsiliasi read-only**

Setelah RPC, fetch semua tabel dan assert count, total finansial, dua saldo, nol orphan, dan invariant. Exit nonzero bila satu nilai berbeda.

- [ ] **Step 6: Jalankan unit tests dan dry-run**

Run:

```bash
uv run --with openpyxl,requests python -m unittest discover -s test/scripts -p 'test_*.py' -v
uv run --with openpyxl,requests python scripts/reseed_data.py --preview ref/PREVIEW_MIGRASI_R2.xlsx
```

Expected: tests PASS; dry-run mencetak seluruh nilai kontrol dan `Tidak ada perubahan Supabase`.

- [ ] **Step 7: Update README command tanpa menjalankan apply**

Dokumentasikan generate preview, dry-run, remote-check, backup path, apply phrase, urutan reset Android, dan larangan menghapus Auth/profiles.

- [ ] **Step 8: Commit task**

```bash
git add supabase/migrations/0006_reseed_business_data.sql scripts/reseed_data.py test/scripts/test_reseed_data.py .gitignore README.md
git commit -m "feat: siapkan reseed r2 transaksional"
```

### Task 10: Full Verification dan Static Web Release

**Files:**
- Modify generated: `build/web/**`

**Interfaces:**
- Consumes seluruh task implementasi.
- Produces build web yang siap direview/deploy; tidak melakukan push atau cutover.

- [ ] **Step 1: Jalankan seluruh Python tests**

Run: `uv run --with openpyxl,requests python -m unittest discover -s test/scripts -p 'test_*.py' -v`

Expected: semua PASS.

- [ ] **Step 2: Jalankan codegen bersih dan cek diff**

Run: `dart run build_runner build --delete-conflicting-outputs`

Expected: exit 0; generated drift konsisten.

- [ ] **Step 3: Jalankan seluruh Flutter tests**

Run: `flutter test`

Expected: exit 0, nol test gagal.

- [ ] **Step 4: Jalankan analyzer**

Run: `flutter analyze`

Expected: `No issues found!`.

- [ ] **Step 5: Build web static**

Run: `bash scripts/build_web.sh`

Expected: exit 0 dan `build/web/index.html` tersedia.

- [ ] **Step 6: Verifikasi UI desktop/mobile dengan Playwright**

Serve `build/web`, login dengan akun test/admin yang tersedia, lalu ambil screenshot halaman Anggaran dan form Transaksi/Pembayaran pada 1440x900 dan 390x844. Pastikan tidak ada overflow, label Sandi/Ika terbaca, hijau/emas benar, sheet dapat dibuka, dan console tidak memiliki exception.

- [ ] **Step 7: Review diff dan commit build**

Run: `git diff --check && git status --short`

Pastikan `.env`, backup, dan workbook r2 mentah tidak ikut staged.

```bash
git add build/web
git commit -m "build: perbarui web sumber dana"
```

### Task 11: Production Cutover (Explicit Approval Gate)

**Files:**
- No source edits expected.
- Creates local ignored backup under `backups/`.

**Interfaces:**
- Consumes: release terverifikasi dan preview final.
- Produces: production dengan 46 nasabah, dataset r2, dan saldo awal sumber dana.

- [ ] **Step 1: STOP dan minta approval cutover production**

Laporkan hasil tests/build, preview path, commit IDs, dan dampak: data bisnis production akan dihapus lalu diganti; Auth/profiles dipertahankan. Jangan lanjut tanpa jawaban eksplisit user.

- [ ] **Step 2: Bekukan input dan push schema**

Run: `npx supabase db push`

Expected: migration 0005 dan 0006 applied tanpa error.

- [ ] **Step 3: Jalankan remote read-only check**

Run: `uv run --with openpyxl,requests python scripts/reseed_data.py --preview ref/PREVIEW_MIGRASI_R2.xlsx --remote-check`

Expected: current production masih 58 aktif/249/1069 dan dry-run target 46/249/1069.

- [ ] **Step 4: Jalankan backup + reseed atomik**

Run:

```bash
uv run --with openpyxl,requests python scripts/reseed_data.py \
  --preview ref/PREVIEW_MIGRASI_R2.xlsx \
  --apply --confirm-reset RESET-BUSINESS-DATA
```

Expected: backup JSON selesai sebelum RPC; RPC commit; rekonsiliasi otomatis PASS.

- [ ] **Step 5: Jalankan rekonsiliasi kedua secara read-only**

Run: `uv run --with openpyxl,requests python scripts/reseed_data.py --preview ref/PREVIEW_MIGRASI_R2.xlsx --remote-check`

Expected: 46 nasabah, 249 transaksi, 1.069 pembayaran, piutang dan sumber masing-masing sesuai nilai kontrol.

- [ ] **Step 6: Reset Android lama dan smoke test**

Hapus data aplikasi/reinstall pada perangkat yang pernah sync, login, lakukan full sync, dan cocokkan dashboard/Anggaran dengan web. Tambahkan satu transaksi dan satu pembayaran test hanya bila user menyetujui data test production; bila tidak, lakukan smoke test baca saja.

- [ ] **Step 7: Deploy hanya setelah approval terpisah**

Tampilkan status commit dan build kepada user. Jalankan `git push origin master` hanya setelah user menyetujui deploy. Verifikasi URL live dan hapus pembekuan input.
