# UI Redesign Premium — SandiApp

**Tanggal:** 2026-08-11
**Status:** Approved

## Latar Belakang

UI saat ini terasa generik dan kuno meski sudah menggunakan Material 3. App ini akan berkembang untuk dilihat customer juga (bukan hanya admin internal), sehingga perlu kesan **profesional, branded, dan premium** — setara fintech/bank digital modern Indonesia.

## Keputusan Desain

| Aspek | Keputusan |
|-------|-----------|
| Karakter visual | Elegan & premium (ala Blu/Jago/bank digital) |
| Palet warna | Charcoal/hitam dominan + aksen emas amber |
| Font | Inter (Google Fonts) |
| Cakupan | Total redesign — semua halaman |

---

## 1. Theme System

### Color Palette

**Dark mode (default utama):**
| Token | Hex | Peran |
|-------|-----|-------|
| `background` | `#111318` | Background utama app |
| `surface` | `#1C1F26` | Kartu, panel, bottom sheet |
| `surfaceVariant` | `#252A34` | Input field, chip, divider |
| `primary` (emas) | `#F5B942` | Tombol utama, angka penting, icon aktif nav |
| `primaryContainer` | `#7A5C1E` | Background chip emas, badge |
| `onPrimary` | `#1C1600` | Teks di atas tombol emas |
| `onBackground` | `#F0F0F0` | Teks utama |
| `onSurface` | `#E8E8E8` | Teks di atas kartu |
| `onSurfaceVariant` | `#8A8F9E` | Teks sekunder, placeholder |
| `error` | `#FF6B6B` | Sisa hutang, pesan error |
| `tertiary` (hijau) | `#34D399` | Badge LUNAS |

**Light mode:**
| Token | Hex | Peran |
|-------|-----|-------|
| `background` | `#FAFAFA` | Background putih bersih |
| `surface` | `#FFFFFF` | Kartu |
| `surfaceVariant` | `#F0F2F5` | Input, chip |
| `primary` (emas gelap) | `#B8860B` | Emas lebih gelap agar kontras di light |
| `onBackground` | `#111318` | Teks utama (charcoal) |
| `onSurfaceVariant` | `#5A5F6E` | Teks sekunder |

### Typography — Inter

Tambah `google_fonts` package, konfigurasi di `buildTheme()`:

```dart
textTheme: GoogleFonts.interTextTheme(brightness == Brightness.dark
    ? ThemeData.dark().textTheme
    : ThemeData.light().textTheme).copyWith(
  displayLarge: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -1.0),
  displayMedium: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
  titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
  titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
  bodyLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400),
  bodyMedium: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400),
  labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.3),
  labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
)
```

### Component Styles (global via ThemeData)

| Komponen | Style |
|----------|-------|
| `CardTheme` | `borderRadius: 16`, elevation 0, border `1px` surfaceVariant |
| `FilledButton` | background emas, teks `onPrimary`, borderRadius 12 |
| `InputDecorationTheme` | `filled: true`, `fillColor: surfaceVariant`, `focusedBorder` emas, borderRadius 12, border none default |
| `ChipTheme` | borderRadius 20 (pill), selected = primaryContainer |
| `NavigationBarTheme` | background surface, `indicatorColor` primaryContainer, icon aktif emas |
| `AppBarTheme` | background background, elevation 0, title Inter 600 |
| `ListTileTheme` | `contentPadding` horizontal 16, tileColor transparent |
| `DividerTheme` | warna surfaceVariant, thickness 1 |

---

## 2. Halaman per Halaman

### 2.1 AppShell (`app_shell.dart`)

- `AppBar`: background = background color, title "SandiApp" Inter 600, elevation 0
- `NavigationBar`: background = surface, indikator warna primaryContainer, icon & label aktif warna emas
- `OfflineBanner`: sudah ada, sesuaikan warna ke error color

### 2.2 Login Page (`login_page.dart`)

- Background: gradient subtle dari background ke surface (charcoal ke sedikit lebih terang)
- Logo/brand: nama "SandiApp" dengan Inter 700 display, di bawahnya tagline kecil onSurfaceVariant
- Form: kartu surface, padding 24, input filled style
- Tombol login: full-width FilledButton emas

### 2.3 Dashboard (`dashboard_page.dart`)

**Struktur baru:**

1. **Greeting header** — "Halo, Admin" (titleLarge) + tanggal hari ini (bodyMedium, onSurfaceVariant). Tidak ada AppBar title di halaman ini (AppBar tetap ada tapi title kosong atau "SandiApp").

2. **Hero card piutang total** — `Card` full-width, padding 24, gradient internal (surface → surfaceVariant via `BoxDecoration`). Isi:
   - Label "Total Piutang Aktif" — labelSmall, onSurfaceVariant, uppercase
   - Angka rupiah — displayMedium, warna emas
   - Subtext "dari X customer aktif" — bodyMedium, onSurfaceVariant

3. **Row stat cards (2 kartu sejajar):**
   - "Bayar Bulan Ini" — nilai hijau tertiary
   - "Customer Berhutang" — nilai onSurface

4. **Aksi Cepat** — judul section "Aksi Cepat" (labelLarge, onSurfaceVariant). Row 3 tombol:
   - `OutlinedButton` pill dengan icon + teks: "+ Pembayaran", "+ Customer", "+ Barang"
   - Border emas 1px, teks emas, background transparent

5. **Hutang Terbesar** — judul section + `ListView` max 5 item:
   - `ListTile`: leading = avatar bulat (background primaryContainer, teks inisial emas), title = nama customer (bodyLarge bold), trailing = sisa hutang (labelLarge, emas)

### 2.4 Customers Page (`customers_page.dart`)

- Search bar: filled style, prefixIcon emas subtle
- Sort toggle: `IconButton` emas outline
- `ListView` item:
  - Leading: avatar bulat inisial (primaryContainer bg, emas text)
  - Title: nama customer, Inter 600
  - Subtitle: "Sisa: Rp X" atau chip "LUNAS" kecil hijau
  - Trailing: `Row` — icon check hijau (jika lunas) + `IconButton` delete (onSurfaceVariant, subtle)
- FAB: emas, icon `+`, label "Tambah"

### 2.5 Customer Detail (`customer_detail_page.dart`)

- **Header section** (bukan AppBar standar — custom `SliverAppBar` atau `Column`):
  - Avatar besar (56px) inisial, nama titleLarge, HP & alamat bodyMedium onSurfaceVariant
  - Row action: `IconButton` edit + `IconButton` delete (di kanan)

- **3 stat cards sejajar:**
  - "Total Belanja", "Total Bayar", "Sisa Hutang"
  - Sisa: merah jika > 0, hijau jika lunas

- **Section Barang:** judul + tombol "Tambah" kecil di kanan
  - `ListTile` tiap item: nama barang (bold), tanggal + harga (sekunder), trailing = status chip pill
  - Status chip: LUNAS (hijau), SEBAGIAN (amber), BELUM (merah)
  - Long press = hapus (pertahankan behavior existing)

- **Section Pembayaran:** judul + tombol "Bayar" kecil
  - `ListTile` dense: jumlah (bold), tanggal + metode (sekunder)
  - Long press = hapus

### 2.6 Customer Form (`customer_form_page.dart`)

- AppBar minimal: judul "Tambah Customer" / "Edit Customer", elevation 0
- Semua input: filled style (sudah global via theme)
- Tombol Simpan: full-width FilledButton emas, di bagian bawah dengan padding 16

### 2.7 Purchase Form (`purchase_form_page.dart`)

- Sama dengan Customer Form — filled inputs, full-width FilledButton emas
- Field harga beli diberi label "Harga Beli (opsional)" dengan hint text

### 2.8 Payment Form (`payment_form_page.dart`)

- Quick-chip nominal: chip pills di-restyle, selected = primaryContainer (emas redup)
- Input jumlah: `MoneyInputField` dengan prefix "Rp " emas
- Tombol Bayar: full-width emas

### 2.9 Reports Page (`reports_page.dart`)

- Toggle Tahunan/Bulanan: `SegmentedButton` di-restyle — selected segment background primaryContainer, teks emas
- Dropdown tahun: filled style
- Bar chart (`fl_chart`):
  - Bar color: emas `#F5B942`
  - Background: transparent (mengikuti surface)
  - Grid: garis horizontal tipis surfaceVariant
  - Tooltip: background surface, teks onSurface

### 2.10 Budget Page (`budget_page.dart`)

- Navigator bulan: row dengan `IconButton` chevron kiri/kanan + judul bulan Inter 600 tengah
- Running balance: angka saldo di atas list, besar, warna emas jika positif / merah jika negatif
- List entry: tipe (pemasukan/pengeluaran) dibedakan dengan icon + warna (hijau/merah)
- Bottom sheet form: kartu surface, filled inputs, tombol simpan emas

### 2.11 Settings Page (`settings_page.dart`)

- Info user: avatar inisial besar + email onSurfaceVariant
- Toggle dark mode: `SwitchListTile` dengan thumb warna emas saat aktif
- Sync status (Android): `ListTile` dengan icon `SyncBadge` di leading
- Tombol logout: `OutlinedButton` merah (error color), full-width di bawah

---

## 3. Widget Reusable — Perubahan

### `StatCard` (`stat_card.dart`)
- Tambah parameter `accent: bool` — jika true, nilai pakai warna emas
- Border tipis 1px surfaceVariant
- Padding internal 16, borderRadius 16

### `EmptyState` (`empty_state.dart`)
- Icon placeholder: emas, ukuran 48
- Teks pesan: onSurfaceVariant

### `ConfirmDialog` (`confirm_dialog.dart`)
- Tidak ada perubahan struktural — ikut theme global otomatis

### `OfflineBanner` (`offline_banner.dart`)
- Ikut theme error color otomatis

---

## 4. Dependencies Baru

```yaml
# pubspec.yaml
google_fonts: ^6.2.1
```

Hanya satu dependency tambahan. Tidak ada package UI lain — semua dari Material 3 + custom theme.

---

## 5. File yang Diubah

| File | Jenis Perubahan |
|------|----------------|
| `pubspec.yaml` | Tambah `google_fonts` |
| `lib/core/theme.dart` | Rombak total — ColorScheme manual, Inter typography, semua component theme |
| `lib/features/auth/login_page.dart` | Redesign layout & style |
| `lib/features/dashboard/dashboard_page.dart` | Redesign total — hero card, greeting, aksi cepat |
| `lib/features/customers/customers_page.dart` | Avatar inisial, polish list tile |
| `lib/features/customers/customer_detail_page.dart` | Header avatar, stat cards, section style |
| `lib/features/customers/customer_form_page.dart` | Tombol full-width |
| `lib/features/payments/payment_form_page.dart` | Chip restyle, tombol full-width |
| `lib/features/purchases/purchase_form_page.dart` | Tombol full-width |
| `lib/features/reports/reports_page.dart` | Chart warna emas, toggle restyle |
| `lib/features/budget/budget_page.dart` | Navigator bulan, saldo display |
| `lib/features/settings/settings_page.dart` | Avatar, switch thumb, tombol logout |
| `lib/features/shell/app_shell.dart` | AppBar & NavigationBar polish |
| `lib/widgets/stat_card.dart` | Parameter `accent`, border, radius |
| `lib/widgets/empty_state.dart` | Icon color |

---

## 6. Tidak Diubah

- Semua logika bisnis, provider, repository, sync engine
- Struktur navigasi GoRouter
- Model data
- Test files

---

## Kriteria Sukses

- Semua halaman terasa konsisten — satu visual language
- Angka rupiah terbaca jelas di semua ukuran layar
- Dark mode & light mode keduanya enak dilihat
- Tidak ada regression pada fungsionalitas existing
- `flutter analyze` bersih
- Semua test lulus
