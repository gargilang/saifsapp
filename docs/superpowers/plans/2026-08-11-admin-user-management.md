# Admin User Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Admin bisa buat akun admin baru, lihat daftar admin, hapus akun admin, dan ubah password diri sendiri — semuanya dari dalam app.

**Architecture:** Operasi buat/hapus akun memakai Supabase Edge Function `admin-users` (TypeScript/Deno) yang berjalan dengan `service_role` key di server. Ubah password langsung via `supabase.auth.updateUser()` dari client. Flutter memanggil Edge Function lewat `SupabaseClient.functions.invoke()`. Semua UI ada di halaman Settings.

**Tech Stack:** Flutter/Dart, Riverpod, Supabase Auth, Supabase Edge Functions (Deno/TypeScript), Material 3.

## Global Constraints

- Teks UI: Bahasa Indonesia
- Tidak ada perubahan logika bisnis (customer, purchase, payment, budget)
- `flutter analyze` harus bersih setelah setiap task
- `flutter test` harus lulus setelah setiap task
- Ikuti pola tema premium yang sudah ada: Card, FilledButton, surfaceContainer, primary emas
- Password minimal 6 karakter
- Admin tidak bisa hapus diri sendiri
- Edge Function harus verifikasi JWT + role admin sebelum menjalankan operasi apapun

---

### Task 1: Supabase Migration + Edge Function

**Files:**
- Create: `supabase/migrations/0002_admin_read_profiles.sql`
- Create: `supabase/functions/admin-users/index.ts`

**Interfaces:**
- Produces: Edge Function `admin-users` tersedia di `https://<project>.supabase.co/functions/v1/admin-users`
  - `GET` → `{ admins: [{ id: string, email: string, display_name: string, created_at: string }] }`
  - `POST` body `{ email, password, display_name }` → `{ id: string, email: string, display_name: string }`
  - `DELETE` body `{ user_id: string }` → `{ success: true }`

- [ ] **Step 1: Buat file migration RLS**

Buat file `supabase/migrations/0002_admin_read_profiles.sql`:
```sql
-- Admin bisa baca semua profiles (untuk daftar admin)
-- Policy lama "profiles_read_own" tetap ada (OR logic di RLS)
create policy "admin_read_all_profiles" on public.profiles
  for select to authenticated
  using (exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  ));
```

- [ ] **Step 2: Pastikan direktori functions ada**

```bash
ls supabase/functions/ 2>/dev/null || mkdir -p supabase/functions/admin-users
```

- [ ] **Step 3: Buat Edge Function**

Buat file `supabase/functions/admin-users/index.ts`:
```typescript
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // ── Autentikasi caller ──────────────────────────────────────────────────
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // Client untuk verifikasi caller (pakai JWT caller)
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  const callerClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  // Ambil user dari JWT
  const { data: { user: caller }, error: userErr } = await callerClient.auth.getUser();
  if (userErr || !caller) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // Verifikasi caller adalah admin
  const { data: profile } = await callerClient
    .from("profiles")
    .select("role")
    .eq("id", caller.id)
    .single();

  if (profile?.role !== "admin") {
    return new Response(JSON.stringify({ error: "Forbidden" }), {
      status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // Admin client untuk operasi privileged
  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  // ── Router ──────────────────────────────────────────────────────────────
  try {
    if (req.method === "GET") {
      // Daftar semua user dengan role admin
      const { data: profiles, error } = await adminClient
        .from("profiles")
        .select("id, display_name, created_at")
        .eq("role", "admin");

      if (error) throw error;

      // Ambil email dari auth.users untuk setiap admin
      const admins = await Promise.all(
        (profiles ?? []).map(async (p) => {
          const { data: { user } } = await adminClient.auth.admin.getUserById(p.id);
          return {
            id: p.id,
            email: user?.email ?? "",
            display_name: p.display_name,
            created_at: p.created_at,
          };
        })
      );

      return new Response(JSON.stringify({ admins }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (req.method === "POST") {
      const { email, password, display_name } = await req.json();

      if (!email || !password || !display_name) {
        return new Response(JSON.stringify({ error: "email, password, display_name wajib diisi" }), {
          status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      if (password.length < 6) {
        return new Response(JSON.stringify({ error: "Password minimal 6 karakter" }), {
          status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const { data, error } = await adminClient.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: { display_name },
      });

      if (error) {
        const status = error.message.includes("already") ? 409 : 400;
        return new Response(JSON.stringify({ error: error.message }), {
          status, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      return new Response(
        JSON.stringify({ id: data.user.id, email: data.user.email, display_name }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (req.method === "DELETE") {
      const { user_id } = await req.json();

      if (!user_id) {
        return new Response(JSON.stringify({ error: "user_id wajib diisi" }), {
          status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      if (user_id === caller.id) {
        return new Response(JSON.stringify({ error: "Tidak bisa menghapus akun sendiri" }), {
          status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const { error } = await adminClient.auth.admin.deleteUser(user_id);
      if (error) {
        return new Response(JSON.stringify({ error: error.message }), {
          status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
```

- [ ] **Step 4: Deploy ke Supabase (manual — butuh Supabase CLI)**

```bash
# Pastikan sudah login: supabase login
# Pastikan project linked: supabase link --project-ref <your-project-ref>
supabase functions deploy admin-users
supabase db push  # deploy migration 0002
```

> **PENTING:** Jika Supabase CLI belum terinstall atau project belum di-link, lakukan ini manual via Supabase dashboard:
> - SQL Editor: jalankan isi `0002_admin_read_profiles.sql`
> - Edge Functions: create function `admin-users`, paste isi `index.ts`

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/0002_admin_read_profiles.sql supabase/functions/admin-users/index.ts
git commit -m "feat(backend): Edge Function admin-users + RLS policy admin read profiles"
```

---

### Task 2: RemoteStore — tambah callFunction

**Files:**
- Modify: `lib/data/remote/remote_store.dart`

**Interfaces:**
- Produces:
  - `abstract Future<Map<String, dynamic>> callFunction(String name, {String method, Map<String, dynamic>? body})`
  - `SupabaseRemoteStore.callFunction(name, {method, body})` — memanggil `_client.functions.invoke()`

- [ ] **Step 1: Baca file saat ini**

Baca `lib/data/remote/remote_store.dart` — pastikan strukturnya sesuai ekspektasi (abstract class `RemoteStore` + class `SupabaseRemoteStore`).

- [ ] **Step 2: Tambah method ke abstract class dan implementasi**

Edit `lib/data/remote/remote_store.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Akses generik per tabel ke Supabase (json key = nama kolom).
abstract class RemoteStore {
  /// Ambil semua row (semua kolom), atau hanya yang updated_at > [since].
  Future<List<Map<String, dynamic>>> fetchSince(String table, DateTime? since);
  Future<void> upsert(String table, List<Map<String, dynamic>> rows);

  /// Panggil Supabase Edge Function.
  /// [method] default 'POST'. Gunakan 'GET' untuk operasi baca tanpa body.
  Future<Map<String, dynamic>> callFunction(
    String name, {
    String method = 'POST',
    Map<String, dynamic>? body,
  });
}

class SupabaseRemoteStore implements RemoteStore {
  final SupabaseClient _client;
  SupabaseRemoteStore(this._client);

  @override
  Future<List<Map<String, dynamic>>> fetchSince(String table, DateTime? since) {
    final query = _client.from(table).select();
    if (since != null) {
      return query.gt('updated_at', since.toIso8601String());
    }
    return query;
  }

  @override
  Future<void> upsert(String table, List<Map<String, dynamic>> rows) =>
      _client.from(table).upsert(rows);

  @override
  Future<Map<String, dynamic>> callFunction(
    String name, {
    String method = 'POST',
    Map<String, dynamic>? body,
  }) async {
    final response = await _client.functions.invoke(
      name,
      method: HttpMethod.values.firstWhere(
        (m) => m.name.toUpperCase() == method.toUpperCase(),
        orElse: () => HttpMethod.post,
      ),
      body: body,
    );
    if (response.data == null) {
      throw Exception('Edge Function $name: response kosong');
    }
    final data = response.data as Map<String, dynamic>;
    if (data.containsKey('error')) {
      throw Exception(data['error'] as String);
    }
    return data;
  }
}
```

- [ ] **Step 3: Analyze**

```bash
flutter analyze lib/data/remote/remote_store.dart
```
Expected: `No issues found!`

- [ ] **Step 4: Test**

```bash
flutter test
```
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/data/remote/remote_store.dart
git commit -m "feat(data): RemoteStore.callFunction untuk Edge Function"
```

---

### Task 3: AuthController — tambah updatePassword

**Files:**
- Modify: `lib/features/auth/auth_controller.dart`

**Interfaces:**
- Produces: `AuthController.updatePassword({required String oldPassword, required String newPassword}) → Future<void>` — throws Exception jika password lama salah

- [ ] **Step 1: Tulis ulang auth_controller.dart**

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

  /// Ubah password diri sendiri.
  /// Re-auth dengan [oldPassword] terlebih dahulu untuk verifikasi.
  /// Throws [Exception] jika password lama salah atau update gagal.
  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email == null) throw Exception('Tidak ada sesi aktif');

    // Verifikasi password lama dengan re-auth
    await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: oldPassword,
    );

    // Update ke password baru
    final res = await Supabase.instance.client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
    if (res.user == null) {
      throw Exception('Gagal mengubah password');
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/auth/auth_controller.dart
```
Expected: `No issues found!`

- [ ] **Step 3: Test**

```bash
flutter test
```
Expected: `All tests passed!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/auth/auth_controller.dart
git commit -m "feat(auth): AuthController.updatePassword"
```

---

### Task 4: AdminRepository + AdminProviders

**Files:**
- Create: `lib/features/settings/admin_repository.dart`
- Create: `lib/features/settings/admin_providers.dart`

**Interfaces:**
- Consumes: `RemoteStore.callFunction(name, {method, body})` dari Task 2
- Produces:
  - `class AdminUser { final String id, email, displayName; final DateTime createdAt; }`
  - `class AdminRepository { Future<List<AdminUser>> listAdmins(); Future<void> createAdmin({required String email, required String password, required String displayName}); Future<void> deleteAdmin(String userId); }`
  - `final adminRepositoryProvider = Provider<AdminRepository>(...)`
  - `final adminListProvider = FutureProvider.autoDispose<List<AdminUser>>(...)`

- [ ] **Step 1: Buat admin_repository.dart**

```dart
import '../../data/remote/remote_store.dart';

class AdminUser {
  final String id;
  final String email;
  final String displayName;
  final DateTime createdAt;

  const AdminUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
        id: j['id'] as String,
        email: j['email'] as String,
        displayName: j['display_name'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class AdminRepository {
  final RemoteStore _store;
  AdminRepository(this._store);

  Future<List<AdminUser>> listAdmins() async {
    final data = await _store.callFunction('admin-users', method: 'GET');
    final list = data['admins'] as List<dynamic>;
    return list
        .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createAdmin({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await _store.callFunction(
      'admin-users',
      body: {
        'email': email.trim(),
        'password': password,
        'display_name': displayName.trim(),
      },
    );
  }

  Future<void> deleteAdmin(String userId) async {
    await _store.callFunction(
      'admin-users',
      method: 'DELETE',
      body: {'user_id': userId},
    );
  }
}
```

- [ ] **Step 2: Buat admin_providers.dart**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../data/remote/remote_store.dart';
import 'admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final store = ref.watch(remoteStoreProvider);
  return AdminRepository(store);
});

final adminListProvider = FutureProvider.autoDispose<List<AdminUser>>((ref) {
  return ref.watch(adminRepositoryProvider).listAdmins();
});
```

- [ ] **Step 3: Analyze**

```bash
flutter analyze lib/features/settings/admin_repository.dart lib/features/settings/admin_providers.dart
```
Expected: `No issues found!`

- [ ] **Step 4: Test**

```bash
flutter test
```
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/admin_repository.dart lib/features/settings/admin_providers.dart
git commit -m "feat(settings): AdminRepository + adminListProvider"
```

---

### Task 5: ChangePasswordSheet

**Files:**
- Create: `lib/features/settings/change_password_sheet.dart`

**Interfaces:**
- Consumes: `AuthController.updatePassword({oldPassword, newPassword})` dari Task 3
- Produces: `ChangePasswordSheet` — `StatefulWidget`, dipanggil via `showModalBottomSheet`

- [ ] **Step 1: Buat change_password_sheet.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';

class ChangePasswordSheet extends ConsumerStatefulWidget {
  const ChangePasswordSheet({super.key});

  @override
  ConsumerState<ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _oldPw = TextEditingController();
  final _newPw = TextEditingController();
  final _confirmPw = TextEditingController();
  bool _saving = false;
  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _oldPw.dispose();
    _newPw.dispose();
    _confirmPw.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref.read(authControllerProvider.notifier).updatePassword(
            oldPassword: _oldPw.text,
            newPassword: _newPw.text,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password berhasil diubah')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Ubah Password',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 20),
              TextFormField(
                controller: _oldPw,
                obscureText: !_showOld,
                decoration: InputDecoration(
                  labelText: 'Password lama',
                  suffixIcon: IconButton(
                    icon: Icon(_showOld ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _showOld = !_showOld),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newPw,
                obscureText: !_showNew,
                decoration: InputDecoration(
                  labelText: 'Password baru',
                  suffixIcon: IconButton(
                    icon: Icon(_showNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _showNew = !_showNew),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  if (v.length < 6) return 'Minimal 6 karakter';
                  if (v == _oldPw.text) return 'Password baru harus berbeda';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPw,
                obscureText: !_showConfirm,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi password baru',
                  suffixIcon: IconButton(
                    icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _showConfirm = !_showConfirm),
                  ),
                ),
                validator: (v) =>
                    v != _newPw.text ? 'Password tidak cocok' : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/settings/change_password_sheet.dart
```
Expected: `No issues found!`

- [ ] **Step 3: Test**

```bash
flutter test
```
Expected: `All tests passed!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/settings/change_password_sheet.dart
git commit -m "feat(settings): ChangePasswordSheet"
```

---

### Task 6: AdminFormPage

**Files:**
- Create: `lib/features/settings/admin_form_page.dart`

**Interfaces:**
- Consumes: `AdminRepository.createAdmin({email, password, displayName})` via `adminRepositoryProvider` dari Task 4
- Consumes: `adminListProvider` — di-invalidate setelah berhasil simpan
- Produces: `AdminFormPage()` — `ConsumerStatefulWidget`, dipush via `Navigator.push`

- [ ] **Step 1: Buat admin_form_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_providers.dart';

class AdminFormPage extends ConsumerStatefulWidget {
  const AdminFormPage({super.key});

  @override
  ConsumerState<AdminFormPage> createState() => _AdminFormPageState();
}

class _AdminFormPageState extends ConsumerState<AdminFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _saving = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _displayName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref.read(adminRepositoryProvider).createAdmin(
            email: _email.text,
            password: _password.text,
            displayName: _displayName.text,
          );
      ref.invalidate(adminListProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun admin berhasil dibuat')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Gagal: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Admin')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _displayName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama tampilan *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email *',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: 'Password awal *',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Wajib diisi';
                if (v.length < 6) return 'Minimal 6 karakter';
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/settings/admin_form_page.dart
```
Expected: `No issues found!`

- [ ] **Step 3: Test**

```bash
flutter test
```
Expected: `All tests passed!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/settings/admin_form_page.dart
git commit -m "feat(settings): AdminFormPage — tambah akun admin baru"
```

---

### Task 7: AdminListPage

**Files:**
- Create: `lib/features/settings/admin_list_page.dart`

**Interfaces:**
- Consumes: `adminListProvider` → `List<AdminUser>` dari Task 4
- Consumes: `AdminRepository.deleteAdmin(userId)` dari Task 4
- Consumes: `AdminFormPage()` dari Task 6
- Consumes: `confirmDialog(context, title, message)` dari `lib/widgets/confirm_dialog.dart`
- Produces: `AdminListPage()` — `ConsumerWidget`, dipush via `Navigator.push`

- [ ] **Step 1: Buat admin_list_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import 'admin_form_page.dart';
import 'admin_providers.dart';
import 'admin_repository.dart';

class AdminListPage extends ConsumerWidget {
  const AdminListPage({super.key});

  String _inisial(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id;
    final adminsAsync = ref.watch(adminListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Admin')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin-fab',
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Tambah'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminFormPage()),
        ),
      ),
      body: adminsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(message: 'Gagal memuat: $e'),
        data: (admins) => admins.isEmpty
            ? const EmptyState(message: 'Belum ada admin.')
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminListProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: admins.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 4),
                  itemBuilder: (ctx, i) {
                    final admin = admins[i];
                    final isSelf = admin.id == currentUserId;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cs.primaryContainer,
                          child: Text(
                            _inisial(admin.displayName),
                            style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13),
                          ),
                        ),
                        title: Text(
                          '${admin.displayName}${isSelf ? ' (kamu)' : ''}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(admin.email),
                        trailing: isSelf
                            ? null
                            : IconButton(
                                icon: Icon(Icons.delete_outline,
                                    size: 20, color: cs.onSurfaceVariant),
                                tooltip: 'Hapus admin',
                                onPressed: () async {
                                  if (await confirmDialog(context,
                                      title: 'Hapus admin?',
                                      message:
                                          '${admin.displayName} (${admin.email}) tidak akan bisa login lagi.')) {
                                    try {
                                      await ref
                                          .read(adminRepositoryProvider)
                                          .deleteAdmin(admin.id);
                                      ref.invalidate(adminListProvider);
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                              'Gagal: ${e.toString().replaceAll("Exception: ", "")}'),
                                        ));
                                      }
                                    }
                                  }
                                },
                              ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/settings/admin_list_page.dart
```
Expected: `No issues found!`

- [ ] **Step 3: Test**

```bash
flutter test
```
Expected: `All tests passed!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/settings/admin_list_page.dart
git commit -m "feat(settings): AdminListPage — daftar, hapus admin"
```

---

### Task 8: Update Settings Page

**Files:**
- Modify: `lib/features/settings/settings_page.dart`

**Interfaces:**
- Consumes: `ChangePasswordSheet` dari Task 5
- Consumes: `AdminListPage` dari Task 7

- [ ] **Step 1: Baca settings_page.dart saat ini**

Baca `lib/features/settings/settings_page.dart` untuk memahami struktur ListView yang ada (Card profil → Card preferensi → tombol logout).

- [ ] **Step 2: Tambah import dan Card Akun baru**

Edit `lib/features/settings/settings_page.dart`. Tambah import di atas:
```dart
import 'admin_list_page.dart';
import 'change_password_sheet.dart';
```

Tambah `Card` baru di antara Card preferensi dan tombol logout. Cari baris `const SizedBox(height: 16),` yang kedua (sebelum `// ── Logout`) dan tambahkan sebelumnya:

```dart
      // ── Akun ─────────────────────────────────────────────────────────────
      Card(
        child: Column(children: [
          ListTile(
            leading: Icon(Icons.lock_reset_outlined, color: cs.onSurfaceVariant),
            title: const Text('Ubah Password'),
            trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const ChangePasswordSheet(),
            ),
          ),
          Divider(height: 1, indent: 16, color: cs.surfaceContainerHighest),
          ListTile(
            leading: Icon(Icons.manage_accounts_outlined,
                color: cs.onSurfaceVariant),
            title: const Text('Kelola Admin'),
            trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminListPage()),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 16),
```

- [ ] **Step 3: Analyze**

```bash
flutter analyze lib/features/settings/settings_page.dart
```
Expected: `No issues found!`

- [ ] **Step 4: Test**

```bash
flutter test
```
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/settings_page.dart
git commit -m "feat(settings): tambah section Akun — Ubah Password & Kelola Admin"
```

---

### Task 9: Verifikasi Final

**Files:** Tidak ada perubahan file baru.

- [ ] **Step 1: Analyze seluruh project**

```bash
flutter analyze
```
Expected: `No issues found!` (2 warning deprecated Supabase `anonKey` di `main.dart` dan `background_sync.dart` sudah ada sebelumnya — bukan dari perubahan kita, boleh diabaikan)

- [ ] **Step 2: Jalankan semua test**

```bash
flutter test
```
Expected: `All tests passed!`

- [ ] **Step 3: Verifikasi manual checklist**

Sebelum dianggap selesai, pastikan hal-hal ini bisa dilakukan di app:
- [ ] Buka Settings → ada Card "Akun" dengan "Ubah Password" dan "Kelola Admin"
- [ ] Tap "Ubah Password" → muncul bottom sheet dengan 3 field password
- [ ] Tap "Kelola Admin" → buka halaman daftar admin
- [ ] Di halaman Kelola Admin → FAB "+ Tambah" membuka form tambah admin
- [ ] Admin yang sedang login tidak punya tombol delete di samping namanya

> **Catatan:** Fitur yang bergantung pada Edge Function (`listAdmins`, `createAdmin`, `deleteAdmin`) memerlukan Edge Function sudah di-deploy ke Supabase (Task 1 Step 4). Jika Edge Function belum di-deploy, operasi tersebut akan error dengan pesan network.

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat(settings): admin user management selesai"
```
