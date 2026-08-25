-- Atomic, service-role-only reset and reseed for the reviewed r2 dataset.

create or replace function public.reseed_business_data_v2(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_customers integer;
  v_purchases integer;
  v_payments integer;
  v_sources integer;
  v_ledger integer;
  v_harga_beli bigint;
  v_harga_jual bigint;
  v_payments_total bigint;
  v_outstanding bigint;
  v_fund_total bigint;
  v_orphans integer;
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'service role required' using errcode = '42501';
  end if;
  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    raise exception 'invalid reseed payload';
  end if;
  if jsonb_typeof(p_payload -> 'controls') is distinct from 'object'
      or jsonb_typeof(p_payload -> 'customers') is distinct from 'array'
      or jsonb_typeof(p_payload -> 'purchases') is distinct from 'array'
      or jsonb_typeof(p_payload -> 'payments') is distinct from 'array'
      or jsonb_typeof(p_payload -> 'fund_sources') is distinct from 'array'
      or jsonb_typeof(p_payload -> 'fund_ledger_entries') is distinct from 'array'
      or jsonb_typeof(p_payload -> 'budget_entries') is distinct from 'array' then
    raise exception 'reseed payload arrays are required';
  end if;

  select count(*)::integer
    into v_customers
  from jsonb_to_recordset(p_payload -> 'customers') as x(id uuid);
  select count(*)::integer, coalesce(sum(harga_beli), 0)::bigint,
      coalesce(sum(harga_jual), 0)::bigint
    into v_purchases, v_harga_beli, v_harga_jual
  from jsonb_to_recordset(p_payload -> 'purchases')
    as x(harga_beli bigint, harga_jual bigint);
  select count(*)::integer, coalesce(sum(jumlah), 0)::bigint
    into v_payments, v_payments_total
  from jsonb_to_recordset(p_payload -> 'payments') as x(jumlah bigint);
  select count(*)::integer
    into v_sources
  from jsonb_to_recordset(p_payload -> 'fund_sources') as x(id uuid);
  select count(*)::integer, coalesce(sum(jumlah_delta), 0)::bigint
    into v_ledger, v_fund_total
  from jsonb_to_recordset(p_payload -> 'fund_ledger_entries')
    as x(jumlah_delta bigint);
  v_outstanding := v_harga_jual - v_payments_total;

  if v_customers <> 46 or v_purchases <> 249 or v_payments <> 1069
      or v_sources <> 2 or v_ledger <> 2
      or jsonb_array_length(p_payload -> 'budget_entries') <> 0
      or v_harga_beli <> 877769000 or v_harga_jual <> 971417500
      or v_payments_total <> 854692500 or v_outstanding <> 116725000
      or v_fund_total <> v_outstanding then
    raise exception 'reseed payload control totals do not match r2 target';
  end if;
  if (p_payload -> 'controls' ->> 'customers')::integer is distinct from v_customers
      or (p_payload -> 'controls' ->> 'purchases')::integer is distinct from v_purchases
      or (p_payload -> 'controls' ->> 'payments')::integer is distinct from v_payments
      or (p_payload -> 'controls' ->> 'harga_beli')::bigint is distinct from v_harga_beli
      or (p_payload -> 'controls' ->> 'harga_jual')::bigint is distinct from v_harga_jual
      or (p_payload -> 'controls' ->> 'payments_total')::bigint is distinct from v_payments_total
      or (p_payload -> 'controls' ->> 'outstanding')::bigint is distinct from v_outstanding
      or (p_payload -> 'controls' ->> 'fund_balance_total')::bigint is distinct from v_fund_total then
    raise exception 'declared controls differ from payload contents';
  end if;
  if exists (
    select 1
    from jsonb_to_recordset(p_payload -> 'purchases')
      as p(customer_id uuid, fund_source_id uuid)
    where not exists (
      select 1 from jsonb_to_recordset(p_payload -> 'customers') as c(id uuid)
      where c.id = p.customer_id
    ) or (p.fund_source_id is not null and not exists (
      select 1 from jsonb_to_recordset(p_payload -> 'fund_sources') as f(id uuid)
      where f.id = p.fund_source_id
    ))
  ) or exists (
    select 1
    from jsonb_to_recordset(p_payload -> 'payments')
      as p(customer_id uuid, fund_source_id uuid)
    where not exists (
      select 1 from jsonb_to_recordset(p_payload -> 'customers') as c(id uuid)
      where c.id = p.customer_id
    ) or (p.fund_source_id is not null and not exists (
      select 1 from jsonb_to_recordset(p_payload -> 'fund_sources') as f(id uuid)
      where f.id = p.fund_source_id
    ))
  ) or exists (
    select 1
    from jsonb_to_recordset(p_payload -> 'fund_ledger_entries')
      as e(fund_source_id uuid)
    where not exists (
      select 1 from jsonb_to_recordset(p_payload -> 'fund_sources') as f(id uuid)
      where f.id = e.fund_source_id
    )
  ) then
    raise exception 'reseed payload contains orphan references';
  end if;

  -- This order respects all business foreign keys. Auth and profiles remain intact.
  delete from public.fund_ledger_entries;
  delete from public.budget_entries;
  delete from public.payments;
  delete from public.purchases;
  delete from public.customers;
  delete from public.fund_sources;

  insert into public.fund_sources (
    id, nama, color_key, is_active, created_by, created_at, updated_at, deleted_at
  )
  select id, nama, color_key, is_active, created_by, created_at, updated_at, deleted_at
  from jsonb_to_recordset(p_payload -> 'fund_sources') as x(
    id uuid, nama text, color_key text, is_active boolean, created_by uuid,
    created_at timestamptz, updated_at timestamptz, deleted_at timestamptz
  );

  insert into public.customers (
    id, nama, no_hp, alamat, catatan, is_archived, auth_user_id, created_by,
    created_at, updated_at, deleted_at
  )
  select id, nama, no_hp, alamat, catatan, is_archived, auth_user_id, created_by,
    created_at, updated_at, deleted_at
  from jsonb_to_recordset(p_payload -> 'customers') as x(
    id uuid, nama text, no_hp text, alamat text, catatan text,
    is_archived boolean, auth_user_id uuid, created_by uuid,
    created_at timestamptz, updated_at timestamptz, deleted_at timestamptz
  );

  insert into public.purchases (
    id, customer_id, nama_barang, jenis, harga_jual, harga_beli, tanggal_beli,
    catatan, fund_source_id, created_by, created_at, updated_at, deleted_at
  )
  select id, customer_id, nama_barang, jenis, harga_jual, harga_beli, tanggal_beli,
    catatan, fund_source_id, created_by, created_at, updated_at, deleted_at
  from jsonb_to_recordset(p_payload -> 'purchases') as x(
    id uuid, customer_id uuid, nama_barang text, jenis text, harga_jual bigint,
    harga_beli bigint, tanggal_beli date, catatan text, fund_source_id uuid,
    created_by uuid, created_at timestamptz, updated_at timestamptz,
    deleted_at timestamptz
  );

  insert into public.payments (
    id, customer_id, jumlah, tanggal_bayar, metode, catatan, sumber,
    status_verifikasi, bukti_foto_url, fund_source_id, created_by, created_at,
    updated_at, deleted_at
  )
  select id, customer_id, jumlah, tanggal_bayar, metode, catatan, sumber,
    status_verifikasi, bukti_foto_url, fund_source_id, created_by, created_at,
    updated_at, deleted_at
  from jsonb_to_recordset(p_payload -> 'payments') as x(
    id uuid, customer_id uuid, jumlah bigint, tanggal_bayar date, metode text,
    catatan text, sumber text, status_verifikasi text, bukti_foto_url text,
    fund_source_id uuid, created_by uuid, created_at timestamptz,
    updated_at timestamptz, deleted_at timestamptz
  );

  insert into public.fund_ledger_entries (
    id, fund_source_id, tanggal, tipe, jumlah_delta, reference_type,
    reference_id, transfer_group_id, catatan, created_by, created_at,
    updated_at, deleted_at
  )
  select id, fund_source_id, tanggal, tipe, jumlah_delta, reference_type,
    reference_id, transfer_group_id, catatan, created_by, created_at,
    updated_at, deleted_at
  from jsonb_to_recordset(p_payload -> 'fund_ledger_entries') as x(
    id uuid, fund_source_id uuid, tanggal date, tipe text, jumlah_delta bigint,
    reference_type text, reference_id uuid, transfer_group_id uuid, catatan text,
    created_by uuid, created_at timestamptz, updated_at timestamptz,
    deleted_at timestamptz
  );

  select count(*)::integer into v_customers from public.customers;
  select count(*)::integer, coalesce(sum(harga_beli), 0)::bigint,
      coalesce(sum(harga_jual), 0)::bigint
    into v_purchases, v_harga_beli, v_harga_jual from public.purchases;
  select count(*)::integer, coalesce(sum(jumlah), 0)::bigint
    into v_payments, v_payments_total from public.payments
    where status_verifikasi = 'verified';
  select count(*)::integer into v_sources from public.fund_sources;
  select count(*)::integer into v_ledger from public.fund_ledger_entries;
  select coalesce(sum(public.fund_source_balance(id)), 0)::bigint
    into v_fund_total from public.fund_sources;
  v_outstanding := v_harga_jual - v_payments_total;
  select
    (select count(*) from public.purchases p
      where not exists (select 1 from public.customers c where c.id = p.customer_id))
    + (select count(*) from public.payments p
      where not exists (select 1 from public.customers c where c.id = p.customer_id))
    + (select count(*) from public.fund_ledger_entries e
      where not exists (select 1 from public.fund_sources f where f.id = e.fund_source_id))
    into v_orphans;

  if v_customers <> 46 or v_purchases <> 249 or v_payments <> 1069
      or v_sources <> 2 or v_ledger <> 2
      or v_harga_beli <> 877769000 or v_harga_jual <> 971417500
      or v_payments_total <> 854692500 or v_outstanding <> 116725000
      or v_fund_total <> v_outstanding or v_orphans <> 0
      or exists (select 1 from public.budget_entries) then
    raise exception 'post-insert reconciliation failed; transaction rolled back';
  end if;
  if public.fund_source_balance('00000000-0000-4000-8000-000000000001') <> 36100000
      or public.fund_source_balance('00000000-0000-4000-8000-000000000002') <> 80625000
      or not exists (
        select 1 from public.fund_sources
        where id = '00000000-0000-4000-8000-000000000001'
          and nama = 'Sandi' and color_key = 'green'
      ) or not exists (
        select 1 from public.fund_sources
        where id = '00000000-0000-4000-8000-000000000002'
          and nama = 'Ika' and color_key = 'gold'
      ) then
    raise exception 'source balances do not match reviewed opening balances';
  end if;

  return jsonb_build_object(
    'customers', v_customers,
    'purchases', v_purchases,
    'payments', v_payments,
    'fund_sources', v_sources,
    'fund_ledger_entries', v_ledger,
    'harga_beli', v_harga_beli,
    'harga_jual', v_harga_jual,
    'payments_total', v_payments_total,
    'outstanding', v_outstanding,
    'fund_balance_total', v_fund_total,
    'orphans', v_orphans
  );
end;
$$;

revoke all on function public.reseed_business_data_v2(jsonb) from public;
revoke all on function public.reseed_business_data_v2(jsonb) from anon;
revoke all on function public.reseed_business_data_v2(jsonb) from authenticated;
grant execute on function public.reseed_business_data_v2(jsonb) to service_role;
