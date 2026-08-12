# Setup Supabase

Project `sandiapp` sudah dibuat & migrasi sudah dijalankan (via psql pooler).
Dokumen ini untuk referensi / setup ulang.

## Status saat ini
- Schema (`0001_init.sql`) sudah live: profiles, customers, purchases, payments,
  budget_entries + triggers updated_at + trigger handle_new_user + RLS + bucket `bukti-bayar`.
- Akun admin test: `admin@sandiapp.local` / `admin123` (role admin, profil sudah ada).

## Setup ulang / project baru
1. Buat project di https://supabase.com/dashboard.
2. Jalankan `supabase/migrations/0001_init.sql`:
   - Via SQL Editor (paste + Run), atau
   - Via psql (pooler IPv4):
     ```bash
     PGPASSWORD='<db-password>' psql \
       "postgresql://postgres.<ref>:<db-password>@aws-0-<region>.pooler.supabase.com:5432/postgres" \
       -f supabase/migrations/0001_init.sql
     ```
3. Buat admin (Authentication → Add user, Auto Confirm). Trigger `handle_new_user`
   otomatis membuat profil dengan role `admin`.
   - Jika user dibuat SEBELUM migrasi, insert profil manual:
     ```sql
     insert into public.profiles (id, display_name, role)
     values ('<auth-user-id>', 'Admin', 'admin') on conflict (id) do nothing;
     ```
4. Salin `Project URL` + `anon public key` ke `.env` (lihat `.env` — jangan commit).

## Menjalankan app
```bash
./scripts/run_android.sh   # dart-define diambil dari .env
./scripts/run_web.sh
```
