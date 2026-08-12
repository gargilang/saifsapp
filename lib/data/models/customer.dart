import '../../core/logic/collectibility.dart';

class Customer {
  final String id;
  final String nama;
  final String? noHp, alamat, catatan, authUserId, createdBy;
  final bool isArchived;
  final DateTime createdAt, updatedAt;
  final DateTime? deletedAt;

  const Customer({
    required this.id,
    required this.nama,
    this.noHp,
    this.alamat,
    this.catatan,
    this.isArchived = false,
    this.authUserId,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        id: j['id'] as String,
        nama: j['nama'] as String,
        noHp: j['no_hp'] as String?,
        alamat: j['alamat'] as String?,
        catatan: j['catatan'] as String?,
        isArchived: j['is_archived'] as bool? ?? false,
        authUserId: j['auth_user_id'] as String?,
        createdBy: j['created_by'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
        deletedAt: j['deleted_at'] == null ? null : DateTime.parse(j['deleted_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'no_hp': noHp,
        'alamat': alamat,
        'catatan': catatan,
        'is_archived': isArchived,
        'auth_user_id': authUserId,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  Customer copyWith({
    String? nama, String? noHp, String? alamat, String? catatan,
    bool? isArchived, String? createdBy, DateTime? updatedAt, DateTime? deletedAt,
  }) =>
      Customer(
        id: id,
        nama: nama ?? this.nama,
        noHp: noHp ?? this.noHp,
        alamat: alamat ?? this.alamat,
        catatan: catatan ?? this.catatan,
        isArchived: isArchived ?? this.isArchived,
        authUserId: authUserId,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );
}

class CustomerWithBalance {
  final Customer customer;
  final int totalHutang, totalBayar;
  final DateTime? lastPaymentAt;         // pembayaran verified terakhir
  final Collectibility? collectibility;  // null jika sisa <= 0 (lunas/tanpa hutang)
  const CustomerWithBalance({
    required this.customer,
    required this.totalHutang,
    required this.totalBayar,
    this.lastPaymentAt,
    this.collectibility,
  });
  int get sisa => totalHutang - totalBayar;
}
