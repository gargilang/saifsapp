-- Tambah kolom jenis ke purchases
-- Nilai: barang | pinjaman | investasi | jasa/servis | modal usaha
alter table public.purchases
  add column if not exists jenis text not null default 'barang'
    check (jenis in ('barang', 'pinjaman', 'investasi', 'jasa/servis', 'modal usaha'));
