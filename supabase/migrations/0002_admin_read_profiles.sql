-- Admin bisa baca semua profiles (untuk daftar admin)
-- Policy lama "profiles_read_own" tetap ada (OR logic di RLS)
create policy "admin_read_all_profiles" on public.profiles
  for select to authenticated
  using (exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  ));
