import '../../core/utils/dates.dart';

class BudgetEntry {
  final String id;
  final DateTime tanggal; // date-only
  final String namaTransaksi;
  final String tipe; // 'pemasukan' | 'pengeluaran'
  final int jumlah;
  final String? catatan, createdBy;
  final String sourceType; // 'manual' | 'purchase' | 'payment'
  final String? sourceId; // id purchase/payment terkait
  final DateTime createdAt, updatedAt;
  final DateTime? deletedAt;

  const BudgetEntry({
    required this.id,
    required this.tanggal,
    required this.namaTransaksi,
    required this.tipe,
    required this.jumlah,
    this.catatan,
    this.createdBy,
    this.sourceType = 'manual',
    this.sourceId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isAuto => sourceType != 'manual';

  factory BudgetEntry.fromJson(Map<String, dynamic> j) => BudgetEntry(
        id: j['id'] as String,
        tanggal: DateTime.parse(j['tanggal'] as String),
        namaTransaksi: j['nama_transaksi'] as String,
        tipe: j['tipe'] as String,
        jumlah: (j['jumlah'] as num).toInt(),
        catatan: j['catatan'] as String?,
        createdBy: j['created_by'] as String?,
        sourceType: j['source_type'] as String? ?? 'manual',
        sourceId: j['source_id'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
        deletedAt: j['deleted_at'] == null ? null : DateTime.parse(j['deleted_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tanggal': dateOnly(tanggal),
        'nama_transaksi': namaTransaksi,
        'tipe': tipe,
        'jumlah': jumlah,
        'catatan': catatan,
        'created_by': createdBy,
        'source_type': sourceType,
        'source_id': sourceId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  BudgetEntry copyWith({
    DateTime? tanggal, String? namaTransaksi, String? tipe, int? jumlah,
    String? catatan, String? createdBy, String? sourceType, String? sourceId,
    DateTime? updatedAt, DateTime? deletedAt,
  }) =>
      BudgetEntry(
        id: id,
        tanggal: tanggal ?? this.tanggal,
        namaTransaksi: namaTransaksi ?? this.namaTransaksi,
        tipe: tipe ?? this.tipe,
        jumlah: jumlah ?? this.jumlah,
        catatan: catatan ?? this.catatan,
        createdBy: createdBy ?? this.createdBy,
        sourceType: sourceType ?? this.sourceType,
        sourceId: sourceId ?? this.sourceId,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );
}
