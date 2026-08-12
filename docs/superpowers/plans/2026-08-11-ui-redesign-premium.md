# UI Redesign Premium Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign seluruh UI SandiApp menjadi tampilan premium elegan — charcoal/hitam dominan, aksen emas amber, font Inter — setara fintech/bank digital modern.

**Architecture:** Theme system Material 3 yang dikonfigurasi manual (ColorScheme eksplisit, tidak pakai colorSchemeSeed) menjadi fondasi utama — komponen global (Card, Button, Input, NavigationBar) otomatis ikut tema tanpa perlu modifikasi per-widget. Halaman-halaman kemudian dipoles satu per satu untuk struktur layout yang lebih informatif dan visual.

**Tech Stack:** Flutter Material 3, `google_fonts ^6.2.1` (Inter), `fl_chart` (sudah ada), Riverpod (tidak berubah).

## Global Constraints

- Teks UI: Bahasa Indonesia
- Uang: int rupiah, selalu format via `formatRupiah()`
- Tidak ada perubahan logika bisnis, provider, repository, sync, model data
- Tidak ada perubahan test files (kecuali jika test widget rusak karena perubahan widget signature)
- `flutter analyze` harus bersih setelah setiap task
- `flutter test` harus lulus setelah setiap task
- Warna dark: background `#111318`, surface `#1C1F26`, surfaceVariant `#252A34`, primary emas `#F5B942`, primaryContainer `#7A5C1E`, onPrimary `#1C1600`, onSurface `#E8E8E8`, onSurfaceVariant `#8A8F9E`, error `#FF6B6B`, tertiary hijau `#34D399`
- Warna light: background `#FAFAFA`, surface `#FFFFFF`, surfaceVariant `#F0F2F5`, primary `#B8860B`, onBackground `#111318`, onSurfaceVariant `#5A5F6E`
- Font: Inter via `google_fonts`, hanya dipakai di `theme.dart`

---

### Task 1: Tambah google_fonts & Bangun Theme System

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/core/theme.dart`

**Interfaces:**
- Produces: `buildTheme(Brightness brightness) → ThemeData` — dipakai di `lib/app.dart` (tidak berubah signature-nya)

- [ ] **Step 1: Tambah dependency google_fonts**

Edit `pubspec.yaml`, tambahkan di bawah baris `fl_chart: ^1.2.0`:
```yaml
  google_fonts: ^6.2.1
```

- [ ] **Step 2: Jalankan flutter pub get**

```bash
flutter pub get
```
Expected: output "Got dependencies!" tanpa error.

- [ ] **Step 3: Tulis ulang lib/core/theme.dart**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Warna dark ──────────────────────────────────────────────────────────────
const _darkBackground    = Color(0xFF111318);
const _darkSurface       = Color(0xFF1C1F26);
const _darkSurfaceVar    = Color(0xFF252A34);
const _gold              = Color(0xFFF5B942);
const _goldContainer     = Color(0xFF7A5C1E);
const _onGold            = Color(0xFF1C1600);
const _darkOnSurface     = Color(0xFFE8E8E8);
const _darkOnSurfaceVar  = Color(0xFF8A8F9E);
const _darkError         = Color(0xFFFF6B6B);
const _green             = Color(0xFF34D399);

// ── Warna light ─────────────────────────────────────────────────────────────
const _lightBackground   = Color(0xFFFAFAFA);
const _lightSurface      = Color(0xFFFFFFFF);
const _lightSurfaceVar   = Color(0xFFF0F2F5);
const _lightGold         = Color(0xFFB8860B);
const _lightOnBackground = Color(0xFF111318);
const _lightOnSurfaceVar = Color(0xFF5A5F6E);

ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  final colorScheme = isDark
      ? const ColorScheme.dark(
          brightness: Brightness.dark,
          background: _darkBackground,
          surface: _darkSurface,
          surfaceVariant: _darkSurfaceVar,
          primary: _gold,
          primaryContainer: _goldContainer,
          onPrimary: _onGold,
          onBackground: _darkOnSurface,
          onSurface: _darkOnSurface,
          onSurfaceVariant: _darkOnSurfaceVar,
          error: _darkError,
          tertiary: _green,
          onTertiary: Color(0xFF003322),
        )
      : const ColorScheme.light(
          brightness: Brightness.light,
          background: _lightBackground,
          surface: _lightSurface,
          surfaceVariant: _lightSurfaceVar,
          primary: _lightGold,
          primaryContainer: Color(0xFFFFE082),
          onPrimary: Color(0xFF1C1600),
          onBackground: _lightOnBackground,
          onSurface: _lightOnBackground,
          onSurfaceVariant: _lightOnSurfaceVar,
          error: Color(0xFFD32F2F),
          tertiary: Color(0xFF1B7A5A),
          onTertiary: Color(0xFFFFFFFF),
        );

  final base = isDark ? ThemeData.dark() : ThemeData.light();

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.inter(
          fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -1.0,
          color: colorScheme.onSurface),
      displayMedium: GoogleFonts.inter(
          fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5,
          color: colorScheme.onSurface),
      titleLarge: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
      titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
      bodyLarge: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w400, color: colorScheme.onSurface),
      bodyMedium: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w400,
          color: colorScheme.onSurfaceVariant),
      labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.3,
          color: colorScheme.onSurface),
      labelMedium: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.3,
          color: colorScheme.onSurfaceVariant),
      labelSmall: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5,
          color: colorScheme.onSurfaceVariant),
    ),
    scaffoldBackgroundColor: colorScheme.background,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w600,
          color: colorScheme.onSurface),
      iconTheme: IconThemeData(color: colorScheme.onSurface),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.primaryContainer,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: colorScheme.primary);
        }
        return IconThemeData(color: colorScheme.onSurfaceVariant);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: colorScheme.primary);
        }
        return GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w400,
            color: colorScheme.onSurfaceVariant);
      }),
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.surfaceVariant, width: 1),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      labelStyle: GoogleFonts.inter(color: colorScheme.onSurfaceVariant),
      hintStyle: GoogleFonts.inter(color: colorScheme.onSurfaceVariant),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      selectedColor: colorScheme.primaryContainer,
      labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.surfaceVariant,
      thickness: 1,
      space: 1,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? colorScheme.primary : null),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? colorScheme.primaryContainer
              : null),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: colorScheme.primaryContainer,
        selectedForegroundColor: colorScheme.primary,
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}
```

- [ ] **Step 4: Jalankan analyze dan test**

```bash
flutter analyze lib/core/theme.dart
flutter test
```
Expected: No issues, semua test pass.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/theme.dart
git commit -m "feat(ui): theme system premium — charcoal+emas+Inter"
```

---

### Task 2: Update StatCard & EmptyState

**Files:**
- Modify: `lib/widgets/stat_card.dart`
- Modify: `lib/widgets/empty_state.dart`

**Interfaces:**
- `StatCard({required String label, required String value, Color? valueColor, bool accent = false})` — parameter `accent` baru opsional; caller lama tidak perlu diubah
- `EmptyState({required String message, String? actionLabel, VoidCallback? onAction})` — signature tidak berubah

- [ ] **Step 1: Update StatCard**

Tulis ulang `lib/widgets/stat_card.dart`:
```dart
import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  /// Jika true, nilai ditampilkan dengan warna primary (emas).
  final bool accent;
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveColor = valueColor ?? (accent ? cs.primary : cs.onSurface);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: effectiveColor, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 2: Update EmptyState**

Tulis ulang `lib/widgets/empty_state.dart`:
```dart
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState(
      {super.key, required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.inbox_outlined, size: 48, color: cs.primary),
          const SizedBox(height: 12),
          Text(message,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ]),
      ),
    );
  }
}
```

- [ ] **Step 3: Analyze dan test**

```bash
flutter analyze lib/widgets/
flutter test
```
Expected: No issues, semua test pass.

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/stat_card.dart lib/widgets/empty_state.dart
git commit -m "feat(ui): StatCard accent param + EmptyState icon emas"
```

---

### Task 3: AppShell — AppBar & NavigationBar

**Files:**
- Modify: `lib/features/shell/app_shell.dart`

**Interfaces:**
- `AppShell({required Widget child})` — tidak berubah

- [ ] **Step 1: Tulis ulang app_shell.dart**

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
      appBar: AppBar(
        title: const Text('SandiApp'),
        actions: const [SyncBadge(), SizedBox(width: 8)],
      ),
      body: Column(children: [const OfflineBanner(), Expanded(child: child)]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexOf(context),
        onDestinationSelected: (i) => context.go(_tabs[i]),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Beranda'),
          NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Customer'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Laporan'),
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Anggaran'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Pengaturan'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze dan test**

```bash
flutter analyze lib/features/shell/
flutter test
```
Expected: No issues, semua test pass.

- [ ] **Step 3: Commit**

```bash
git add lib/features/shell/app_shell.dart
git commit -m "feat(ui): AppShell — AppBar & NavigationBar premium"
```

---

### Task 4: Login Page

**Files:**
- Modify: `lib/features/auth/login_page.dart`

**Interfaces:**
- `LoginPage()` — tidak berubah

- [ ] **Step 1: Tulis ulang login_page.dart**

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
    final cs = Theme.of(context).colorScheme;
    final loading = ref.watch(authControllerProvider).isLoading;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cs.background, cs.surface],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(children: [
                  const SizedBox(height: 48),
                  Text('SandiApp',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: cs.primary)),
                  const SizedBox(height: 8),
                  Text('Kelola kredit barang dengan mudah',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 48),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(children: [
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) =>
                              (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outlined),
                          ),
                          validator: (v) =>
                              (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: loading ? null : _submit,
                          child: loading
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Masuk'),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 48),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze dan test**

```bash
flutter analyze lib/features/auth/
flutter test
```
Expected: No issues, semua test pass.

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/login_page.dart
git commit -m "feat(ui): Login page — gradient bg, card form, branding"
```

---

### Task 5: Dashboard Page

**Files:**
- Modify: `lib/features/dashboard/dashboard_page.dart`

**Interfaces:**
- `DashboardPage()` — tidak berubah
- Menggunakan `StatCard` dengan parameter `accent: true` untuk hero card
- Helper `_initialAvatar(String nama) → String` — ambil 1-2 huruf inisial

- [ ] **Step 1: Tulis ulang dashboard_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

  String _inisial(String nama) {
    final parts = nama.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return nama.isNotEmpty ? nama[0].toUpperCase() : '?';
  }

  Future<void> _pilihCustomerLalu(BuildContext context, WidgetRef ref,
      Widget Function(String customerId) pageBuilder) async {
    final customers = await ref.read(repoProvider).customers();
    if (!context.mounted) return;
    if (customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belum ada customer. Tambah dulu.')));
      return;
    }
    final chosen = await showModalBottomSheet<Customer>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('Pilih Customer',
                style: Theme.of(ctx).textTheme.titleMedium),
          ),
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
    final cs = Theme.of(context).colorScheme;
    final stats = ref.watch(dashboardProvider);
    final tanggal = DateFormat('EEEE, d MMMM y', 'id_ID').format(DateTime.now());

    return stats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(message: 'Gagal memuat: $e'),
      data: (s) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardProvider),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // ── Greeting ──────────────────────────────────────────────────────
          Text('Halo, Admin 👋',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(tanggal, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),

          // ── Hero card piutang total ────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cs.surface, cs.surfaceVariant],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.surfaceVariant),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TOTAL PIUTANG AKTIF',
                  style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              Text(formatRupiah(s.totalPiutang),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: cs.primary)),
              const SizedBox(height: 4),
              Text('dari ${s.customerBerhutang} customer berhutang',
                  style: Theme.of(context).textTheme.bodyMedium),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Stat cards ────────────────────────────────────────────────────
          Row(children: [
            Expanded(
                child: StatCard(
                    label: 'Bayar Bulan Ini',
                    value: formatRupiah(s.bayarBulanIni),
                    valueColor: cs.tertiary)),
            const SizedBox(width: 8),
            Expanded(
                child: StatCard(
                    label: 'Customer Berhutang',
                    value: '${s.customerBerhutang}')),
          ]),
          const SizedBox(height: 20),

          // ── Aksi Cepat ────────────────────────────────────────────────────
          Text('AKSI CEPAT',
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: const Text('Pembayaran'),
                onPressed: () => _pilihCustomerLalu(
                    context, ref, (id) => PaymentFormPage(customerId: id)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Customer'),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CustomerFormPage())),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_shopping_cart_outlined, size: 18),
                label: const Text('Barang'),
                onPressed: () => _pilihCustomerLalu(
                    context, ref, (id) => PurchaseFormPage(customerId: id)),
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // ── Hutang Terbesar ───────────────────────────────────────────────
          Text('HUTANG TERBESAR',
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 8),
          if (s.topHutang.isEmpty)
            const EmptyState(message: 'Tidak ada piutang berjalan.')
          else
            Card(
              child: Column(
                children: [
                  for (int i = 0; i < s.topHutang.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 72),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cs.primaryContainer,
                        child: Text(_inisial(s.topHutang[i].customer.nama),
                            style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ),
                      title: Text(s.topHutang[i].customer.nama,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      trailing: Text(formatRupiah(s.topHutang[i].sisa),
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: cs.primary)),
                      onTap: () =>
                          context.push('/customers/${s.topHutang[i].customer.id}'),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze dan test**

```bash
flutter analyze lib/features/dashboard/
flutter test
```
Expected: No issues, semua test pass.

- [ ] **Step 3: Commit**

```bash
git add lib/features/dashboard/dashboard_page.dart
git commit -m "feat(ui): Dashboard — hero card piutang, greeting, aksi cepat"
```

---

### Task 6: Customers Page

**Files:**
- Modify: `lib/features/customers/customers_page.dart`

**Interfaces:**
- `CustomersPage()` — tidak berubah
- Helper `_inisial(String nama) → String` — sama seperti di DashboardPage (duplikasi disengaja, YAGNI)

- [ ] **Step 1: Tulis ulang customers_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_providers.dart';
import '../../core/utils/money.dart';
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
  bool _sortByHutang = false;

  String _inisial(String nama) {
    final parts = nama.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return nama.isNotEmpty ? nama[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final data =
        ref.watch(customersProvider((query: _query, sortByHutang: _sortByHutang)));
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'customers-fab',
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Tambah'),
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CustomerFormPage())),
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
            IconButton.outlined(
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
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (_, i) {
                        final r = rows[i];
                        final lunas = r.totalHutang > 0 && r.sisa <= 0;
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: cs.primaryContainer,
                              child: Text(_inisial(r.customer.nama),
                                  style: TextStyle(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            ),
                            title: Text(r.customer.nama,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            subtitle: lunas
                                ? Row(children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
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
                                : Text('Sisa: ${formatRupiah(r.sisa)}',
                                    style: Theme.of(context).textTheme.bodyMedium),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline,
                                  size: 20, color: cs.onSurfaceVariant),
                              tooltip: 'Hapus customer',
                              onPressed: () async {
                                if (await confirmDialog(context,
                                    title: 'Hapus customer?',
                                    message:
                                        'Data ${r.customer.nama} disembunyikan (bisa dipulihkan lewat database).')) {
                                  await mutate(
                                      ref,
                                      () => ref
                                          .read(repoProvider)
                                          .deleteCustomer(r.customer.id));
                                }
                              },
                            ),
                            onTap: () =>
                                context.push('/customers/${r.customer.id}'),
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

- [ ] **Step 2: Analyze dan test**

```bash
flutter analyze lib/features/customers/customers_page.dart
flutter test
```
Expected: No issues, semua test pass.

- [ ] **Step 3: Commit**

```bash
git add lib/features/customers/customers_page.dart
git commit -m "feat(ui): CustomersPage — avatar inisial, card list, FAB extended"
```

---

### Task 7: Customer Detail Page

**Files:**
- Modify: `lib/features/customers/customer_detail_page.dart`

**Interfaces:**
- `CustomerDetailPage({required String customerId})` — tidak berubah
- `_StatusChip({required ItemStatus status})` — dipertahankan, diperbarui tampilannya

- [ ] **Step 1: Tulis ulang customer_detail_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_providers.dart';
import '../../core/logic/fifo.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stat_card.dart';
import '../payments/payment_form_page.dart';
import '../purchases/purchase_form_page.dart';
import 'customer_form_page.dart';

class CustomerDetailPage extends ConsumerWidget {
  final String customerId;
  const CustomerDetailPage({super.key, required this.customerId});

  String _inisial(String nama) {
    final parts = nama.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return nama.isNotEmpty ? nama[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final data = ref.watch(customerDetailProvider(customerId));
    return Scaffold(
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(message: 'Gagal memuat: $e'),
        data: (d) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(customerDetailProvider(customerId)),
          child: CustomScrollView(slivers: [
            // ── SliverAppBar ───────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              backgroundColor: cs.background,
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 80, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: cs.primaryContainer,
                        child: Text(_inisial(d.customer.nama),
                            style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 22)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(d.customer.nama,
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              if (d.customer.noHp != null)
                                Text(d.customer.noHp!,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              if (d.customer.alamat != null)
                                Text(d.customer.alamat!,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                            ]),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit customer',
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              CustomerFormPage(existing: d.customer))),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Hapus customer',
                  onPressed: () async {
                    if (await confirmDialog(context,
                        title: 'Hapus customer?',
                        message:
                            'Data ${d.customer.nama} disembunyikan (bisa dipulihkan lewat database).')) {
                      await mutate(ref,
                          () => ref.read(repoProvider).deleteCustomer(customerId));
                      if (context.mounted) context.pop();
                    }
                  },
                ),
                const SizedBox(width: 4),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Stat cards ──────────────────────────────────────────
                  Row(children: [
                    Expanded(
                        child: StatCard(
                            label: 'Total Belanja',
                            value: formatRupiah(d.balance.totalHutang))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: StatCard(
                            label: 'Total Bayar',
                            value: formatRupiah(d.balance.totalBayar),
                            valueColor: cs.tertiary)),
                  ]),
                  const SizedBox(height: 8),
                  StatCard(
                    label: 'Sisa Hutang',
                    value: formatRupiah(d.balance.sisa),
                    valueColor: d.balance.sisa > 0 ? cs.error : cs.tertiary,
                    accent: false,
                  ),
                  const SizedBox(height: 24),

                  // ── Section Barang ───────────────────────────────────────
                  _SectionHeader(
                    title: 'Barang',
                    actionLabel: '+ Tambah',
                    onAction: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                PurchaseFormPage(customerId: customerId))),
                  ),
                  const SizedBox(height: 8),
                  if (d.items.isEmpty)
                    const EmptyState(message: 'Belum ada barang.')
                  else
                    Card(
                      child: Column(children: [
                        for (int i = 0; i < d.items.length; i++) ...[
                          if (i > 0) const Divider(height: 1, indent: 16),
                          ListTile(
                            title: Text(d.items[i].purchase.namaBarang,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                '${tampilTanggal(d.items[i].purchase.tanggalBeli)} · ${formatRupiah(d.items[i].purchase.hargaJual)}'
                                '${d.items[i].status == ItemStatus.sebagian ? ' · sisa ${formatRupiah(d.items[i].sisa)}' : ''}'),
                            trailing: _StatusChip(status: d.items[i].status),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => PurchaseFormPage(
                                        customerId: customerId,
                                        existing: d.items[i].purchase))),
                            onLongPress: () async {
                              if (await confirmDialog(context,
                                  title: 'Hapus barang?',
                                  message: d.items[i].purchase.namaBarang)) {
                                await mutate(
                                    ref,
                                    () => ref
                                        .read(repoProvider)
                                        .deletePurchase(d.items[i].purchase.id));
                              }
                            },
                          ),
                        ],
                      ]),
                    ),
                  const SizedBox(height: 24),

                  // ── Section Pembayaran ───────────────────────────────────
                  _SectionHeader(
                    title: 'Riwayat Pembayaran',
                    actionLabel: '+ Bayar',
                    onAction: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                PaymentFormPage(customerId: customerId))),
                  ),
                  const SizedBox(height: 8),
                  if (d.payments.isEmpty)
                    const EmptyState(message: 'Belum ada pembayaran.')
                  else
                    Card(
                      child: Column(children: [
                        for (int i = 0; i < d.payments.length; i++) ...[
                          if (i > 0) const Divider(height: 1, indent: 16),
                          ListTile(
                            dense: true,
                            title: Text(formatRupiah(d.payments[i].jumlah),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                '${tampilTanggal(d.payments[i].tanggalBayar)} · ${d.payments[i].metode}'),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => PaymentFormPage(
                                        customerId: customerId,
                                        existing: d.payments[i]))),
                            onLongPress: () async {
                              if (await confirmDialog(context,
                                  title: 'Hapus pembayaran?',
                                  message:
                                      formatRupiah(d.payments[i].jumlah))) {
                                await mutate(
                                    ref,
                                    () => ref
                                        .read(repoProvider)
                                        .deletePayment(d.payments[i].id));
                              }
                            },
                          ),
                        ],
                      ]),
                    ),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title, actionLabel;
  final VoidCallback onAction;
  const _SectionHeader(
      {required this.title, required this.actionLabel, required this.onAction});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
              child: Text(title.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall)),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      );
}

class _StatusChip extends StatelessWidget {
  final ItemStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      ItemStatus.lunas => ('LUNAS', cs.tertiary),
      ItemStatus.sebagian => ('SEBAGIAN', const Color(0xFFF59E0B)),
      ItemStatus.belum => ('BELUM', cs.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
```

- [ ] **Step 2: Analyze dan test**

```bash
flutter analyze lib/features/customers/customer_detail_page.dart
flutter test
```
Expected: No issues, semua test pass.

- [ ] **Step 3: Commit**

```bash
git add lib/features/customers/customer_detail_page.dart
git commit -m "feat(ui): CustomerDetail — SliverAppBar avatar, stat cards, section headers"
```

---

### Task 8: Form Pages (Customer, Purchase, Payment)

**Files:**
- Modify: `lib/features/customers/customer_form_page.dart`
- Modify: `lib/features/purchases/purchase_form_page.dart`
- Modify: `lib/features/payments/payment_form_page.dart`

**Interfaces:** Semua signature tidak berubah — hanya perubahan visual (full-width button sudah diset global di theme, tombol tanggal jadi `OutlinedButton` yang konsisten).

- [ ] **Step 1: Update customer_form_page.dart — tambah SizedBox wrapper pada FilledButton**

Di `customer_form_page.dart` baris 84, `FilledButton` sudah ada. Karena theme sudah set `minimumSize: Size(double.infinity, 48)`, tidak ada kode yang perlu diubah di form ini — theme sudah menghandle full-width. Verifikasi saja dengan analyze:

```bash
flutter analyze lib/features/customers/customer_form_page.dart
```

- [ ] **Step 2: Update purchase_form_page.dart — tombol tanggal jadi FilledButton.tonal**

Edit baris 88-101 di `lib/features/purchases/purchase_form_page.dart`, ganti `OutlinedButton.icon` dengan `FilledButton.tonal` untuk tombol tanggal:

```dart
          FilledButton.tonal(
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
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.date_range, size: 18),
              const SizedBox(width: 8),
              Text('Tanggal beli: ${tampilTanggal(_tanggal)}'),
            ]),
          ),
```

- [ ] **Step 3: Update payment_form_page.dart — chip nominal + tombol tanggal**

Edit `lib/features/payments/payment_form_page.dart`. Ganti `ActionChip` dengan `FilterChip` agar terintegrasi dengan ChipTheme, dan ganti `OutlinedButton.icon` tanggal menjadi `FilledButton.tonal`:

Ubah baris 80-88 (chip nominal):
```dart
          Wrap(spacing: 8, children: [
            for (final (label, nilai) in [
              ('50rb', 50000),
              ('100rb', 100000),
              ('200rb', 200000),
              ('500rb', 500000),
            ])
              ActionChip(
                label: Text(label),
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                onPressed: () => _setJumlah(nilai),
              ),
          ]),
```

Ubah baris 101-114 (tombol tanggal):
```dart
          FilledButton.tonal(
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
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.date_range, size: 18),
              const SizedBox(width: 8),
              Text('Tanggal bayar: ${tampilTanggal(_tanggal)}'),
            ]),
          ),
```

- [ ] **Step 4: Analyze dan test**

```bash
flutter analyze lib/features/customers/customer_form_page.dart lib/features/purchases/purchase_form_page.dart lib/features/payments/payment_form_page.dart
flutter test
```
Expected: No issues, semua test pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/customers/customer_form_page.dart lib/features/purchases/purchase_form_page.dart lib/features/payments/payment_form_page.dart
git commit -m "feat(ui): form pages — tombol tanggal FilledButton.tonal"
```

---

### Task 9: Reports Page

**Files:**
- Modify: `lib/features/reports/reports_page.dart`

**Interfaces:**
- `ReportsPage()` — tidak berubah

- [ ] **Step 1: Tulis ulang reports_page.dart**

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
        if (!_bulanan) return _content(years, 'Tahunan', years);
        final monthlyAsync = ref.watch(profitMonthlyProvider(tahun));
        return monthlyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(message: 'Gagal memuat: $e'),
          data: (rows) => _content(rows, 'Bulanan $tahun', years),
        );
      },
    );
  }

  Widget _content(List<ProfitRow> rows, String judul, List<ProfitRow> tahunList) {
    final cs = Theme.of(context).colorScheme;
    return ListView(padding: const EdgeInsets.all(16), children: [
      // ── Header ──────────────────────────────────────────────────────────
      Row(children: [
        Expanded(
            child: Text('Keuntungan',
                style: Theme.of(context).textTheme.titleLarge)),
        DropdownButton<int>(
          value: _tahun ?? tahunList.last.year,
          underline: const SizedBox(),
          borderRadius: BorderRadius.circular(12),
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
      const SizedBox(height: 12),
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, label: Text('Tahunan')),
          ButtonSegment(value: true, label: Text('Bulanan')),
        ],
        selected: {_bulanan},
        onSelectionChanged: (s) => setState(() => _bulanan = s.first),
      ),
      const SizedBox(height: 20),

      // ── Bar Chart ─────────────────────────────────────────────────────
      if (rows.isEmpty)
        const Center(
            child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Tidak ada data pada periode ini.'),
        ))
      else ...[
        SizedBox(
          height: 220,
          child: BarChart(BarChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: cs.surfaceVariant, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: const AxisTitles(),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= rows.length) return const SizedBox();
                    final label = rows[i].month == 0
                        ? '${rows[i].year}'
                        : '${rows[i].month}';
                    return Text(label,
                        style: TextStyle(
                            fontSize: 10, color: cs.onSurfaceVariant));
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < rows.length; i++)
                BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: rows[i].keuntungan / 1000000,
                    width: 18,
                    color: cs.primary,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6)),
                  ),
                ]),
            ],
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => cs.surface,
                getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                  formatRupiah((rod.toY * 1000000).toInt()),
                  TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ),
            ),
          )),
        ),
        const SizedBox(height: 4),
        Center(
            child: Text('Sumbu Y: juta rupiah',
                style: Theme.of(context).textTheme.labelSmall)),
        const SizedBox(height: 16),
      ],

      // ── List detail ──────────────────────────────────────────────────
      Card(
        child: Column(children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 16),
            ListTile(
              dense: true,
              title: Text(
                  rows[i].month == 0
                      ? '${rows[i].year}'
                      : bulanTahun(rows[i].year, rows[i].month),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                  '${rows[i].qty} barang · modal ${formatRupiah(rows[i].modal)}'),
              trailing: Text(formatRupiah(rows[i].keuntungan),
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: cs.primary)),
            ),
          ],
        ]),
      ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.all(8),
        child: Text('Catatan: barang tanpa harga beli tidak dihitung.',
            style: Theme.of(context).textTheme.labelSmall),
      ),
    ]);
  }
}
```

- [ ] **Step 2: Analyze dan test**

```bash
flutter analyze lib/features/reports/reports_page.dart
flutter test
```
Expected: No issues, semua test pass.

- [ ] **Step 3: Commit**

```bash
git add lib/features/reports/reports_page.dart
git commit -m "feat(ui): ReportsPage — bar chart emas, SegmentedButton, card list"
```

---

### Task 10: Budget Page

**Files:**
- Modify: `lib/features/budget/budget_page.dart`

**Interfaces:**
- `BudgetPage()` — tidak berubah

- [ ] **Step 1: Update bagian build() BudgetPage — saldo display & navigator bulan**

Di `lib/features/budget/budget_page.dart`, ganti method `build()` di `_BudgetPageState` (baris 37-106):

```dart
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final data = ref.watch(budgetMonthProvider((_bulan.year, _bulan.month)));
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'budget-fab',
        onPressed: _tambah,
        child: const Icon(Icons.add),
      ),
      body: Column(children: [
        // ── Navigator bulan ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: cs.surface,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _geser(-1)),
            Text(bulanTahun(_bulan.year, _bulan.month),
                style: Theme.of(context).textTheme.titleMedium),
            IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _geser(1)),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: data.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(message: 'Gagal memuat: $e'),
            data: (lines) => lines.isEmpty
                ? const EmptyState(message: 'Belum ada transaksi bulan ini.')
                : ListView(children: [
                    // ── Saldo besar ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SALDO',
                                style: Theme.of(context).textTheme.labelSmall),
                            const SizedBox(height: 4),
                            Text(formatRupiah(lines.last.saldo),
                                style: Theme.of(context)
                                    .textTheme
                                    .displayMedium
                                    ?.copyWith(
                                        color: lines.last.saldo >= 0
                                            ? cs.primary
                                            : cs.error)),
                          ]),
                    ),
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(children: [
                        for (int i = 0; i < lines.length; i++) ...[
                          if (i > 0) const Divider(height: 1, indent: 16),
                          ListTile(
                            dense: true,
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: (lines[i].entry.tipe == 'pemasukan'
                                        ? cs.tertiary
                                        : cs.error)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                lines[i].entry.tipe == 'pemasukan'
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                size: 18,
                                color: lines[i].entry.tipe == 'pemasukan'
                                    ? cs.tertiary
                                    : cs.error,
                              ),
                            ),
                            title: Text(lines[i].entry.namaTransaksi,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(tampilTanggal(lines[i].entry.tanggal)),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                    '${lines[i].entry.tipe == 'pemasukan' ? '+' : '-'}${formatRupiah(lines[i].entry.jumlah)}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: lines[i].entry.tipe == 'pemasukan'
                                            ? cs.tertiary
                                            : cs.error)),
                                Text('Saldo: ${formatRupiah(lines[i].saldo)}',
                                    style:
                                        Theme.of(context).textTheme.labelSmall),
                              ],
                            ),
                            onLongPress: () async {
                              if (await confirmDialog(context,
                                  title: 'Hapus transaksi?',
                                  message: lines[i].entry.namaTransaksi)) {
                                await mutate(
                                    ref,
                                    () => ref
                                        .read(repoProvider)
                                        .deleteBudgetEntry(lines[i].entry.id));
                              }
                            },
                          ),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 80),
                  ]),
          ),
        ),
      ]),
    );
  }
```

- [ ] **Step 2: Analyze dan test**

```bash
flutter analyze lib/features/budget/budget_page.dart
flutter test
```
Expected: No issues, semua test pass.

- [ ] **Step 3: Commit**

```bash
git add lib/features/budget/budget_page.dart
git commit -m "feat(ui): BudgetPage — saldo display besar, icon tipe transaksi"
```

---

### Task 11: Settings Page

**Files:**
- Modify: `lib/features/settings/settings_page.dart`

**Interfaces:**
- `SettingsPage()` — tidak berubah

- [ ] **Step 1: Tulis ulang settings_page.dart**

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

  String _inisial(String email) {
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final email = Supabase.instance.client.auth.currentUser?.email ?? '-';
    final themeMode = ref.watch(themeModeProvider);
    final sync = ref.watch(syncControllerProvider);
    return ListView(padding: const EdgeInsets.all(16), children: [
      // ── Profil ────────────────────────────────────────────────────────
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: cs.primaryContainer,
              child: Text(_inisial(email),
                  style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 20)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(email,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600)),
                Text('Admin',
                    style: Theme.of(context).textTheme.bodyMedium),
              ]),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 16),

      // ── Preferensi ───────────────────────────────────────────────────
      Card(
        child: Column(children: [
          SwitchListTile(
            secondary: Icon(Icons.dark_mode_outlined, color: cs.onSurfaceVariant),
            title: const Text('Mode gelap'),
            value: themeMode == ThemeMode.dark,
            onChanged: (v) => ref
                .read(themeModeProvider.notifier)
                .setMode(v ? ThemeMode.dark : ThemeMode.light),
          ),
          if (!kIsWeb) ...[
            const Divider(height: 1, indent: 16),
            ListTile(
              leading: Icon(Icons.sync, color: cs.onSurfaceVariant),
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
        ]),
      ),
      const SizedBox(height: 16),

      // ── Logout ──────────────────────────────────────────────────────
      OutlinedButton.icon(
        icon: const Icon(Icons.logout),
        label: const Text('Keluar'),
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.error,
          side: BorderSide(color: cs.error),
        ),
        onPressed: () async {
          if (await confirmDialog(context,
              title: 'Keluar?',
              message: 'Anda harus login kembali untuk membuka data.')) {
            await ref.read(authControllerProvider.notifier).signOut();
          }
        },
      ),
    ]);
  }
}
```

- [ ] **Step 2: Analyze dan test**

```bash
flutter analyze lib/features/settings/settings_page.dart
flutter test
```
Expected: No issues, semua test pass.

- [ ] **Step 3: Commit**

```bash
git add lib/features/settings/settings_page.dart
git commit -m "feat(ui): SettingsPage — avatar profil, card preferences, tombol logout merah"
```

---

### Task 12: Verifikasi Final

**Files:** Tidak ada perubahan file baru — verifikasi keseluruhan.

- [ ] **Step 1: Analyze seluruh project**

```bash
flutter analyze
```
Expected: `No issues found!`

- [ ] **Step 2: Jalankan semua test**

```bash
flutter test
```
Expected: `All tests passed!`

- [ ] **Step 3: Cek tidak ada warna hardcoded di luar theme.dart**

```bash
grep -r "Colors\." lib/features/ lib/widgets/ --include="*.dart" | grep -v "// ok"
```
Tinjau output — warna yang di-hardcode (misal `Colors.green`, `Colors.red`) harus diganti dengan `cs.tertiary` / `cs.error`. Jika ada, fix di file yang bersangkutan.

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat(ui): UI redesign premium selesai — charcoal+emas+Inter"
```
