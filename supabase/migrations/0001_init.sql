-- SandiApp — skema awal
-- Dieksekusi via psql atau Supabase SQL Editor.

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
  harga_beli bigint check (harga_beli >= 0),
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

-- updated_at kanonik di server (LWW sync)
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
