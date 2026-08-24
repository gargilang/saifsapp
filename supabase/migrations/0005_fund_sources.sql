-- Kepemilikan ekonomis piutang per sumber dana.

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
  tipe text not null check (
    tipe in ('saldo_awal', 'alih_masuk', 'alih_keluar', 'penyesuaian')
  ),
  jumlah_delta bigint not null check (jumlah_delta <> 0),
  reference_type text not null check (
    reference_type in ('migration', 'transfer', 'adjustment')
  ),
  reference_id uuid,
  transfer_group_id uuid,
  catatan text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint fund_ledger_transfer_shape check (
    (tipe = 'saldo_awal' and reference_type = 'migration') or
    (tipe in ('alih_masuk', 'alih_keluar') and reference_type = 'transfer'
      and transfer_group_id is not null) or
    (tipe = 'penyesuaian' and reference_type = 'adjustment'
      and transfer_group_id is not null and nullif(btrim(catatan), '') is not null)
  )
);

alter table public.purchases add column if not exists fund_source_id uuid;
alter table public.payments add column if not exists fund_source_id uuid;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'purchases_fund_source_fk'
      and conrelid = 'public.purchases'::regclass
  ) then
    alter table public.purchases
      add constraint purchases_fund_source_fk foreign key (fund_source_id)
      references public.fund_sources(id);
  end if;
  if not exists (
    select 1 from pg_constraint
    where conname = 'payments_fund_source_fk'
      and conrelid = 'public.payments'::regclass
  ) then
    alter table public.payments
      add constraint payments_fund_source_fk foreign key (fund_source_id)
      references public.fund_sources(id);
  end if;
end $$;

create index if not exists idx_purchases_fund_source
  on public.purchases(fund_source_id) where deleted_at is null;
create index if not exists idx_payments_fund_source
  on public.payments(fund_source_id) where deleted_at is null;
create index if not exists idx_fund_sources_updated_at
  on public.fund_sources(updated_at);
create index if not exists idx_fund_ledger_source
  on public.fund_ledger_entries(fund_source_id) where deleted_at is null;
create index if not exists idx_fund_ledger_updated_at
  on public.fund_ledger_entries(updated_at);
create index if not exists idx_fund_ledger_transfer_group
  on public.fund_ledger_entries(transfer_group_id)
  where transfer_group_id is not null;

drop trigger if exists trg_fund_sources_updated on public.fund_sources;
create trigger trg_fund_sources_updated
  before insert or update on public.fund_sources
  for each row execute function public.set_updated_at();

drop trigger if exists trg_fund_ledger_updated on public.fund_ledger_entries;
create trigger trg_fund_ledger_updated
  before insert or update on public.fund_ledger_entries
  for each row execute function public.set_updated_at();

alter table public.fund_sources enable row level security;
alter table public.fund_ledger_entries enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'fund_sources'
      and policyname = 'admin_all_fund_sources'
  ) then
    create policy "admin_all_fund_sources" on public.fund_sources
      for all to authenticated
      using (public.is_admin()) with check (public.is_admin());
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'fund_ledger_entries'
      and policyname = 'admin_all_fund_ledger'
  ) then
    create policy "admin_all_fund_ledger" on public.fund_ledger_entries
      for all to authenticated
      using (public.is_admin()) with check (public.is_admin());
  end if;
end $$;

insert into public.fund_sources (id, nama, color_key)
values
  ('00000000-0000-4000-8000-000000000001', 'Sandi', 'green'),
  ('00000000-0000-4000-8000-000000000002', 'Ika', 'gold')
on conflict (id) do update
set nama = excluded.nama,
    color_key = excluded.color_key,
    is_active = true,
    deleted_at = null;

create or replace function public.fund_source_balance(p_source_id uuid)
returns bigint
language sql
stable
set search_path = public
as $$
  select
    coalesce((
      select sum(e.jumlah_delta)
      from public.fund_ledger_entries e
      where e.fund_source_id = p_source_id and e.deleted_at is null
    ), 0)::bigint
    + coalesce((
      select sum(p.harga_jual)
      from public.purchases p
      where p.fund_source_id = p_source_id and p.deleted_at is null
    ), 0)::bigint
    - coalesce((
      select sum(p.jumlah)
      from public.payments p
      where p.fund_source_id = p_source_id
        and p.status_verifikasi = 'verified' and p.deleted_at is null
    ), 0)::bigint;
$$;

create or replace function public.record_fund_transfer(
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
language plpgsql
set search_path = public
as $$
declare
  v_existing_count integer;
  v_out_type text;
  v_in_type text;
  v_reference_type text;
begin
  if not public.is_admin() then
    raise exception 'admin access required' using errcode = '42501';
  end if;
  if p_group_id is null or p_out_id is null or p_in_id is null
      or p_out_id = p_in_id then
    raise exception 'transfer ids are required';
  end if;
  if p_from_source_id is null or p_to_source_id is null
      or p_from_source_id = p_to_source_id then
    raise exception 'fund sources must differ';
  end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'amount must be greater than zero';
  end if;
  if p_tanggal is null then
    raise exception 'transfer date is required';
  end if;
  if p_kind not in ('transfer', 'adjustment') then
    raise exception 'invalid transfer kind';
  end if;
  if p_kind = 'adjustment' and nullif(btrim(p_catatan), '') is null then
    raise exception 'adjustment note is required';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(p_group_id::text, 0));
  select count(*) into v_existing_count
  from public.fund_ledger_entries
  where transfer_group_id = p_group_id;
  if v_existing_count > 0 then
    if v_existing_count <> 2 or not exists (
      select 1 from public.fund_ledger_entries
      where id = p_out_id and fund_source_id = p_from_source_id
        and jumlah_delta = -p_amount and transfer_group_id = p_group_id
    ) or not exists (
      select 1 from public.fund_ledger_entries
      where id = p_in_id and fund_source_id = p_to_source_id
        and jumlah_delta = p_amount and transfer_group_id = p_group_id
    ) then
      raise exception 'transfer group conflicts with existing rows';
    end if;
    return jsonb_build_object('transfer_group_id', p_group_id, 'amount', p_amount);
  end if;

  -- Serialize all withdrawals from one source so concurrent groups cannot
  -- both pass the balance check.
  perform pg_advisory_xact_lock(
    hashtextextended('fund-source:' || p_from_source_id::text, 0)
  );

  if not exists (
    select 1 from public.fund_sources
    where id = p_from_source_id and is_active and deleted_at is null
  ) or not exists (
    select 1 from public.fund_sources
    where id = p_to_source_id and is_active and deleted_at is null
  ) then
    raise exception 'active fund source not found';
  end if;
  if public.fund_source_balance(p_from_source_id) < p_amount then
    raise exception 'insufficient source balance';
  end if;

  if p_kind = 'transfer' then
    v_out_type := 'alih_keluar';
    v_in_type := 'alih_masuk';
    v_reference_type := 'transfer';
  else
    v_out_type := 'penyesuaian';
    v_in_type := 'penyesuaian';
    v_reference_type := 'adjustment';
  end if;

  insert into public.fund_ledger_entries (
    id, fund_source_id, tanggal, tipe, jumlah_delta, reference_type,
    reference_id, transfer_group_id, catatan, created_by
  ) values
    (p_out_id, p_from_source_id, p_tanggal, v_out_type, -p_amount,
      v_reference_type, p_group_id, p_group_id, p_catatan, auth.uid()),
    (p_in_id, p_to_source_id, p_tanggal, v_in_type, p_amount,
      v_reference_type, p_group_id, p_group_id, p_catatan, auth.uid());

  return jsonb_build_object('transfer_group_id', p_group_id, 'amount', p_amount);
end $$;

revoke all on function public.record_fund_transfer(
  uuid, uuid, uuid, uuid, uuid, bigint, date, text, text
) from public;
grant execute on function public.record_fund_transfer(
  uuid, uuid, uuid, uuid, uuid, bigint, date, text, text
) to authenticated;
