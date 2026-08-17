/// Menarik semua baris secara bertahap (paginasi) memakai [pageFetcher].
///
/// PostgREST/Supabase membatasi jumlah baris per request (default 1000).
/// Fungsi ini memanggil [pageFetcher] dengan rentang [from, to] inklusif
/// berulang kali sampai halaman terakhir (jumlah baris < [pageSize]).
///
/// Contoh: dengan pageSize 1000 dan 1069 baris, akan memanggil
/// pageFetcher(0, 999) lalu pageFetcher(1000, 1999).
Future<List<Map<String, dynamic>>> fetchAllPaged(
  Future<List<Map<String, dynamic>>> Function(int from, int to) pageFetcher, {
  int pageSize = 1000,
}) async {
  final all = <Map<String, dynamic>>[];
  var from = 0;
  while (true) {
    final page = await pageFetcher(from, from + pageSize - 1);
    all.addAll(page);
    if (page.length < pageSize) break; // halaman terakhir
    from += pageSize;
  }
  return all;
}
