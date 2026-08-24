class FundSource {
  final String id;
  final String nama;
  final String colorKey;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const FundSource({
    required this.id,
    required this.nama,
    required this.colorKey,
    this.isActive = true,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory FundSource.fromJson(Map<String, dynamic> json) => FundSource(
    id: json['id'] as String,
    nama: json['nama'] as String,
    colorKey: json['color_key'] as String,
    isActive: json['is_active'] as bool? ?? true,
    createdBy: json['created_by'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    deletedAt: json['deleted_at'] == null
        ? null
        : DateTime.parse(json['deleted_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'color_key': colorKey,
    'is_active': isActive,
    'created_by': createdBy,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'deleted_at': deletedAt?.toIso8601String(),
  };

  FundSource copyWith({
    String? nama,
    String? colorKey,
    bool? isActive,
    String? Function()? createdBy,
    DateTime? updatedAt,
    DateTime? Function()? deletedAt,
  }) => FundSource(
    id: id,
    nama: nama ?? this.nama,
    colorKey: colorKey ?? this.colorKey,
    isActive: isActive ?? this.isActive,
    createdBy: createdBy == null ? this.createdBy : createdBy(),
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt == null ? this.deletedAt : deletedAt(),
  );
}
