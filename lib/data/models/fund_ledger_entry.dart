import '../../core/utils/dates.dart';

class FundLedgerEntry {
  final String id;
  final String fundSourceId;
  final DateTime tanggal;
  final String tipe;
  final int jumlahDelta;
  final String referenceType;
  final String? referenceId;
  final String? transferGroupId;
  final String? catatan;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const FundLedgerEntry({
    required this.id,
    required this.fundSourceId,
    required this.tanggal,
    required this.tipe,
    required this.jumlahDelta,
    required this.referenceType,
    this.referenceId,
    this.transferGroupId,
    this.catatan,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory FundLedgerEntry.fromJson(Map<String, dynamic> json) =>
      FundLedgerEntry(
        id: json['id'] as String,
        fundSourceId: json['fund_source_id'] as String,
        tanggal: DateTime.parse(json['tanggal'] as String),
        tipe: json['tipe'] as String,
        jumlahDelta: (json['jumlah_delta'] as num).toInt(),
        referenceType: json['reference_type'] as String,
        referenceId: json['reference_id'] as String?,
        transferGroupId: json['transfer_group_id'] as String?,
        catatan: json['catatan'] as String?,
        createdBy: json['created_by'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        deletedAt: json['deleted_at'] == null
            ? null
            : DateTime.parse(json['deleted_at'] as String),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fund_source_id': fundSourceId,
    'tanggal': dateOnly(tanggal),
    'tipe': tipe,
    'jumlah_delta': jumlahDelta,
    'reference_type': referenceType,
    'reference_id': referenceId,
    'transfer_group_id': transferGroupId,
    'catatan': catatan,
    'created_by': createdBy,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'deleted_at': deletedAt?.toIso8601String(),
  };

  FundLedgerEntry copyWith({
    String? fundSourceId,
    DateTime? tanggal,
    String? tipe,
    int? jumlahDelta,
    String? referenceType,
    String? Function()? referenceId,
    String? Function()? transferGroupId,
    String? Function()? catatan,
    String? Function()? createdBy,
    DateTime? updatedAt,
    DateTime? Function()? deletedAt,
  }) => FundLedgerEntry(
    id: id,
    fundSourceId: fundSourceId ?? this.fundSourceId,
    tanggal: tanggal ?? this.tanggal,
    tipe: tipe ?? this.tipe,
    jumlahDelta: jumlahDelta ?? this.jumlahDelta,
    referenceType: referenceType ?? this.referenceType,
    referenceId: referenceId == null ? this.referenceId : referenceId(),
    transferGroupId: transferGroupId == null
        ? this.transferGroupId
        : transferGroupId(),
    catatan: catatan == null ? this.catatan : catatan(),
    createdBy: createdBy == null ? this.createdBy : createdBy(),
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt == null ? this.deletedAt : deletedAt(),
  );
}

class FundTransfer {
  final FundLedgerEntry keluar;
  final FundLedgerEntry masuk;

  const FundTransfer({required this.keluar, required this.masuk});
}
