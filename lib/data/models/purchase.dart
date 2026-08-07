import '../../core/utils/dates.dart';

class Purchase {
  final String id, customerId, namaBarang;
  final int hargaJual;
  final int? hargaBeli;
  final DateTime tanggalBeli; // date-only
  final String? catatan, createdBy;
  final DateTime createdAt, updatedAt;
  final DateTime? deletedAt;

  const Purchase({
    required this.id,
    required this.customerId,
    required this.namaBarang,
    required this.hargaJual,
    this.hargaBeli,
    required this.tanggalBeli,
    this.catatan,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Purchase.fromJson(Map<String, dynamic> j) => Purchase(
        id: j['id'] as String,
        customerId: j['customer_id'] as String,
        namaBarang: j['nama_barang'] as String,
        hargaJual: (j['harga_jual'] as num).toInt(),
        hargaBeli: (j['harga_beli'] as num?)?.toInt(),
        tanggalBeli: DateTime.parse(j['tanggal_beli'] as String),
        catatan: j['catatan'] as String?,
        createdBy: j['created_by'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
        deletedAt: j['deleted_at'] == null ? null : DateTime.parse(j['deleted_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'nama_barang': namaBarang,
        'harga_jual': hargaJual,
        'harga_beli': hargaBeli,
        'tanggal_beli': dateOnly(tanggalBeli),
        'catatan': catatan,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  Purchase copyWith({
    String? namaBarang, int? hargaJual, int? Function()? hargaBeli,
    DateTime? tanggalBeli, String? catatan, String? createdBy,
    DateTime? updatedAt, DateTime? deletedAt,
  }) =>
      Purchase(
        id: id,
        customerId: customerId,
        namaBarang: namaBarang ?? this.namaBarang,
        hargaJual: hargaJual ?? this.hargaJual,
        hargaBeli: hargaBeli != null ? hargaBeli() : this.hargaBeli,
        tanggalBeli: tanggalBeli ?? this.tanggalBeli,
        catatan: catatan ?? this.catatan,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );
}
