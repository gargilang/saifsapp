-- Fix: infinite recursion (42P17) di policy profiles.
-- Policy "admin_read_all_profiles" (0002) query profiles dari dalam policy
-- profiles → rekursi. Solusi: cek role via fungsi SECURITY DEFINER yang
-- bypass RLS, lalu semua policy memakai fungsi itu.

create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- profiles
drop policy if exists "admin_read_all_profiles" on public.profiles;
create policy "admin_read_all_profiles" on public.profiles
  for select to authenticated
  using (public.is_admin());

-- customers
drop policy if exists "admin_all_customers" on public.customers;
create policy "admin_all_customers" on public.customers for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- purchases
drop policy if exists "admin_all_purchases" on public.purchases;
create policy "admin_all_purchases" on public.purchases for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- payments
drop policy if exists "admin_all_payments" on public.payments;
create policy "admin_all_payments" on public.payments for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- budget_entries
drop policy if exists "admin_all_budget" on public.budget_entries;
create policy "admin_all_budget" on public.budget_entries for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());
