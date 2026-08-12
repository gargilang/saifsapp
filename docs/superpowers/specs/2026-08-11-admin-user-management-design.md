# Admin User Management — SandiApp

**Tanggal:** 2026-08-11
**Status:** Approved

## Latar Belakang

Saat ini akun admin hanya bisa dibuat lewat Supabase dashboard — tidak ada UI di app. Dua admin perlu bisa: membuat akun admin baru dari dalam app, melihat daftar admin aktif, menghapus akun admin, dan mengubah password diri sendiri.

## Keputusan Desain

| Aspek | Keputusan |
|-------|-----------|
| Buat akun baru | Admin isi email + password awal langsung |
| Hapus akun | Data tetap, hanya akun login dihapus |
| Ubah password | Hanya bisa ubah password diri sendiri |
| Penempatan UI | Section baru di halaman Settings |
| Backend operasi admin | Supabase Edge Function (service_role) |
| Ubah password sendiri | Langsung via `supabase.auth.updateUser()` dari client |

---

## 1. Arsitektur

Operasi buat & hapus akun memerlukan `service_role` key. Key ini **tidak boleh ada di client Flutter**. Solusi: Edge Function `admin-users` sebagai proxy yang dijalankan di server Supabase.

```
Flutter (admin login)
  │
  ├─ updatePassword()  ──────────────────► supabase.auth.updateUser()  [client SDK]
  │
  └─ listAdmins() / createAdmin() / deleteAdmin()
                        ──────────────────► Edge Function "admin-users"
                                                    │
                                                    ├─ Verifikasi JWT + role admin
                                                    ├─ supabase.auth.admin.*  [service_role]
                                                    └─ tabel public.profiles
```

---

## 2. Edge Function: `admin-users`

### Lokasi
`supabase/functions/admin-users/index.ts`

### Autentikasi & Otorisasi
- Baca JWT dari header `Authorization: Bearer <token>`
- Verifikasi caller adalah admin: query `profiles` dengan `id = auth.uid() AND role = 'admin'`
- Jika bukan admin → HTTP 403

### Endpoint

**GET** `/admin-users`
- Response: `{ admins: [{ id, email, display_name, created_at }] }`
- Ambil dari `auth.admin.listUsers()` + join `profiles` untuk display_name
- Filter hanya role `'admin'`

**POST** `/admin-users`
- Body: `{ email: string, password: string, display_name: string }`
- Validasi: email valid, password min 6 karakter, display_name tidak kosong
- `auth.admin.createUser({ email, password, email_confirm: true })`
- Trigger `on_auth_user_created` otomatis insert ke `profiles` dengan display_name dari metadata
- Response: `{ id, email, display_name }`
- Error jika email sudah terdaftar → HTTP 409

**DELETE** `/admin-users`
- Body: `{ user_id: string }`
- Validasi: tidak boleh hapus diri sendiri (bandingkan `user_id` dengan `auth.uid()` dari JWT)
- `auth.admin.deleteUser(user_id)`
- Response: `{ success: true }`
- Error jika user tidak ditemukan → HTTP 404

---

## 3. Flutter — File Baru & Diubah

### 3.1 `lib/data/remote/remote_store.dart` — tambah method

```dart
// Tambah ke abstract class RemoteStore:
Future<Map<String, dynamic>> callFunction(String name, Map<String, dynamic> body);

// Implementasi di SupabaseRemoteStore:
Future<Map<String, dynamic>> callFunction(String name, Map<String, dynamic> body) =>
    _client.functions.invoke(name, body: body).then((r) => r.data as Map<String, dynamic>);
```

### 3.2 `lib/features/auth/auth_controller.dart` — tambah updatePassword

```dart
Future<void> updatePassword({
  required String oldPassword,
  required String newPassword,
}) async {
  // Re-auth dulu untuk verifikasi password lama
  final email = Supabase.instance.client.auth.currentUser!.email!;
  await Supabase.instance.client.auth
      .signInWithPassword(email: email, password: oldPassword);
  // Jika tidak throw, password lama benar — update ke baru
  await Supabase.instance.client.auth.updateUser(
    UserAttributes(password: newPassword),
  );
}
```

### 3.3 `lib/features/settings/admin_repository.dart` — NEW

Repository untuk operasi admin user. Bergantung pada `SupabaseRemoteStore`.

```dart
class AdminUser {
  final String id, email, displayName;
  final DateTime createdAt;
}

class AdminRepository {
  Future<List<AdminUser>> listAdmins();
  Future<void> createAdmin({required String email, required String password, required String displayName});
  Future<void> deleteAdmin(String userId);
}
```

### 3.4 `lib/features/settings/admin_providers.dart` — NEW

```dart
final adminRepositoryProvider = Provider<AdminRepository>(...);
final adminListProvider = FutureProvider.autoDispose<List<AdminUser>>(...);
```

### 3.5 `lib/features/settings/admin_list_page.dart` — NEW

Halaman daftar admin:
- `AppBar` title "Kelola Admin"
- `FutureProvider` load daftar admin
- `ListView` dalam `Card` — tiap item: avatar inisial (primaryContainer), display_name (bold), email (sekunder), trailing `IconButton` delete
- Tidak tampilkan tombol delete untuk diri sendiri (`currentUser?.id == admin.id`)
- Konfirmasi `confirmDialog` sebelum hapus
- `FloatingActionButton` emas "+ Admin" → navigasi ke `AdminFormPage`
- Pull-to-refresh

### 3.6 `lib/features/settings/admin_form_page.dart` — NEW

Form tambah admin baru:
- `AppBar` title "Tambah Admin"
- Field: Display Name + Email + Password (obscure, dengan toggle show/hide)
- Validasi: semua wajib, email valid, password min 6 karakter
- `FilledButton` full-width "Simpan"
- Loading state saat menyimpan
- Tampilkan error via `ScaffoldMessenger` jika email sudah ada

### 3.7 `lib/features/settings/settings_page.dart` — diubah

Tambah 2 `ListTile` baru di section Preferensi/baru:

```
Card (section Akun):
  ├─ ListTile: "Ubah Password" (icon: lock_reset) → bottom sheet ChangePasswordSheet
  └─ ListTile: "Kelola Admin"  (icon: manage_accounts) → Navigator.push AdminListPage
```

### 3.8 `lib/features/settings/change_password_sheet.dart` — NEW

Bottom sheet ubah password:
- Field: Password Lama + Password Baru + Konfirmasi Password Baru
- Validasi: min 6 karakter, password baru ≠ password lama, konfirmasi cocok
- `FilledButton` "Simpan"
- Loading state, error via SnackBar, sukses tutup sheet + SnackBar "Password berhasil diubah"

---

## 4. Migration Supabase

Tidak ada perubahan skema tabel. Hanya perlu tambah RLS policy baru agar admin bisa baca semua profiles (untuk daftar admin):

```sql
-- supabase/migrations/0002_admin_read_profiles.sql
create policy "admin_read_all_profiles" on public.profiles
  for select to authenticated
  using (exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  ));
```

Policy lama `profiles_read_own` tetap ada (tidak konflik — OR logic).

---

## 5. File yang Dibuat / Diubah

| File | Aksi |
|------|------|
| `supabase/functions/admin-users/index.ts` | CREATE — Edge Function |
| `supabase/migrations/0002_admin_read_profiles.sql` | CREATE — RLS policy baru |
| `lib/data/remote/remote_store.dart` | MODIFY — tambah `callFunction` |
| `lib/features/auth/auth_controller.dart` | MODIFY — tambah `updatePassword` |
| `lib/features/settings/admin_repository.dart` | CREATE |
| `lib/features/settings/admin_providers.dart` | CREATE |
| `lib/features/settings/admin_list_page.dart` | CREATE |
| `lib/features/settings/admin_form_page.dart` | CREATE |
| `lib/features/settings/change_password_sheet.dart` | CREATE |
| `lib/features/settings/settings_page.dart` | MODIFY — tambah 2 ListTile |

---

## 6. Tidak Diubah

- Semua logika bisnis (customer, purchase, payment, budget)
- Sync engine
- Theme / UI halaman lain
- Model data existing

---

## 7. Kriteria Sukses

- Admin bisa buat akun admin baru dari app, akun langsung bisa login
- Admin bisa lihat daftar semua admin aktif
- Admin bisa hapus akun admin lain (bukan diri sendiri)
- Admin bisa ubah password diri sendiri
- Semua operasi gagal dengan pesan error yang jelas jika: email duplikat, password salah, network error
- `flutter analyze` bersih
- `flutter test` lulus
