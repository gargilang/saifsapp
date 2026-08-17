import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/data/remote/paginate.dart';

void main() {
  // pageFetcher palsu: mengembalikan potongan dari [data] sesuai range [from,to].
  List<Map<String, dynamic>> Function(int, int) fetcherFor(
      List<Map<String, dynamic>> data) {
    return (from, to) {
      if (from >= data.length) return [];
      final end = (to + 1) < data.length ? (to + 1) : data.length;
      return data.sublist(from, end);
    };
  }

  test('menarik semua baris ketika total < pageSize (satu halaman)', () async {
    final data = [for (var i = 0; i < 5; i++) {'id': '$i'}];
    final result = await fetchAllPaged(
      (from, to) async => fetcherFor(data)(from, to),
      pageSize: 1000,
    );
    expect(result.length, 5);
  });

  test('menarik semua baris melewati batas satu halaman (1069 > 1000)',
      () async {
    final data = [for (var i = 0; i < 1069; i++) {'id': '$i'}];
    final result = await fetchAllPaged(
      (from, to) async => fetcherFor(data)(from, to),
      pageSize: 1000,
    );
    expect(result.length, 1069,
        reason: 'harus menarik SEMUA 1069 baris, bukan terpotong di 1000');
  });

  test('menarik tepat kelipatan pageSize tanpa duplikat/terlewat (2000)',
      () async {
    final data = [for (var i = 0; i < 2000; i++) {'id': '$i'}];
    final result = await fetchAllPaged(
      (from, to) async => fetcherFor(data)(from, to),
      pageSize: 1000,
    );
    expect(result.length, 2000);
    // pastikan unik & urut lengkap
    final ids = result.map((r) => int.parse(r['id'] as String)).toList();
    expect(ids.toSet().length, 2000, reason: 'tidak boleh ada duplikat');
    expect(ids.first, 0);
    expect(ids.last, 1999);
  });

  test('mengembalikan kosong ketika tidak ada data', () async {
    final result = await fetchAllPaged(
      (from, to) async => <Map<String, dynamic>>[],
      pageSize: 1000,
    );
    expect(result, isEmpty);
  });
}
