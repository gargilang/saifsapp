import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/data/models/fund_ledger_entry.dart';
import 'package:sandiapp/data/remote/remote_backend.dart';

import '../../fakes/fake_remote_store.dart';

void main() {
  test('writeFundTransfer memakai RPC idempotent', () async {
    final now = DateTime.utc(2026, 8, 24, 10);
    final remote = FakeRemoteStore()..clock = () => now;
    final backend = RemoteBackend(remote);
    final transfer = FundTransfer(
      keluar: FundLedgerEntry(
        id: 'out',
        fundSourceId: 'sandi',
        tanggal: DateTime(2026, 8, 24),
        tipe: 'alih_keluar',
        jumlahDelta: -1000000,
        referenceType: 'transfer',
        transferGroupId: 'group-1',
        createdAt: now,
        updatedAt: now,
      ),
      masuk: FundLedgerEntry(
        id: 'in',
        fundSourceId: 'ika',
        tanggal: DateTime(2026, 8, 24),
        tipe: 'alih_masuk',
        jumlahDelta: 1000000,
        referenceType: 'transfer',
        transferGroupId: 'group-1',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await backend.writeFundTransfer(transfer);
    await backend.writeFundTransfer(transfer);

    final rows = await backend.readFundLedgerEntries();
    expect(rows, hasLength(2));
    expect(
      rows.map((entry) => entry.jumlahDelta),
      containsAll([-1000000, 1000000]),
    );
    expect(rows.map((entry) => entry.transferGroupId).toSet(), {'group-1'});
  });
}
