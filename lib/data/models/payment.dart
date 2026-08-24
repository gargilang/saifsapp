import '../../core/utils/dates.dart';

class Payment {
  final String id, customerId;
  final int jumlah;
  final DateTime tanggalBayar; // date-only
  final String metode; // 'tunai' | 'transfer' | 'lainnya'
  final String? catatan, buktiFotoUrl, fundSourceId, createdBy;
  final String sumber; // 'admin' | 'client' (client = masa depan)
  final String statusVerifikasi; // 'pending' | 'verified' | 'rejected'
  final DateTime createdAt, updatedAt;
  final DateTime? deletedAt;

  const Payment({
    required this.id,
    required this.customerId,
    required this.jumlah,
    required this.tanggalBayar,
    this.metode = 'tunai',
    this.catatan,
    this.sumber = 'admin',
    this.statusVerifikasi = 'verified',
    this.buktiFotoUrl,
    this.fundSourceId,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
    id: j['id'] as String,
    customerId: j['customer_id'] as String,
    jumlah: (j['jumlah'] as num).toInt(),
    tanggalBayar: DateTime.parse(j['tanggal_bayar'] as String),
    metode: j['metode'] as String? ?? 'tunai',
    catatan: j['catatan'] as String?,
    sumber: j['sumber'] as String? ?? 'admin',
    statusVerifikasi: j['status_verifikasi'] as String? ?? 'verified',
    buktiFotoUrl: j['bukti_foto_url'] as String?,
    fundSourceId: j['fund_source_id'] as String?,
    createdBy: j['created_by'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
    updatedAt: DateTime.parse(j['updated_at'] as String),
    deletedAt: j['deleted_at'] == null
        ? null
        : DateTime.parse(j['deleted_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer_id': customerId,
    'jumlah': jumlah,
    'tanggal_bayar': dateOnly(tanggalBayar),
    'metode': metode,
    'catatan': catatan,
    'sumber': sumber,
    'status_verifikasi': statusVerifikasi,
    'bukti_foto_url': buktiFotoUrl,
    'fund_source_id': fundSourceId,
    'created_by': createdBy,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'deleted_at': deletedAt?.toIso8601String(),
  };

  Payment copyWith({
    int? jumlah,
    DateTime? tanggalBayar,
    String? metode,
    String? catatan,
    String? statusVerifikasi,
    String? Function()? fundSourceId,
    String? createdBy,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) => Payment(
    id: id,
    customerId: customerId,
    jumlah: jumlah ?? this.jumlah,
    tanggalBayar: tanggalBayar ?? this.tanggalBayar,
    metode: metode ?? this.metode,
    catatan: catatan ?? this.catatan,
    sumber: sumber,
    statusVerifikasi: statusVerifikasi ?? this.statusVerifikasi,
    buktiFotoUrl: buktiFotoUrl,
    fundSourceId: fundSourceId == null ? this.fundSourceId : fundSourceId(),
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt ?? this.deletedAt,
  );
}
