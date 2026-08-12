// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CustomersTable extends Customers
    with TableInfo<$CustomersTable, CustomerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _namaMeta = const VerificationMeta('nama');
  @override
  late final GeneratedColumn<String> nama = GeneratedColumn<String>(
    'nama',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noHpMeta = const VerificationMeta('noHp');
  @override
  late final GeneratedColumn<String> noHp = GeneratedColumn<String>(
    'no_hp',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _alamatMeta = const VerificationMeta('alamat');
  @override
  late final GeneratedColumn<String> alamat = GeneratedColumn<String>(
    'alamat',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _catatanMeta = const VerificationMeta(
    'catatan',
  );
  @override
  late final GeneratedColumn<String> catatan = GeneratedColumn<String>(
    'catatan',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _authUserIdMeta = const VerificationMeta(
    'authUserId',
  );
  @override
  late final GeneratedColumn<String> authUserId = GeneratedColumn<String>(
    'auth_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nama,
    noHp,
    alamat,
    catatan,
    isArchived,
    authUserId,
    createdBy,
    createdAt,
    updatedAt,
    deletedAt,
    isDirty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nama')) {
      context.handle(
        _namaMeta,
        nama.isAcceptableOrUnknown(data['nama']!, _namaMeta),
      );
    } else if (isInserting) {
      context.missing(_namaMeta);
    }
    if (data.containsKey('no_hp')) {
      context.handle(
        _noHpMeta,
        noHp.isAcceptableOrUnknown(data['no_hp']!, _noHpMeta),
      );
    }
    if (data.containsKey('alamat')) {
      context.handle(
        _alamatMeta,
        alamat.isAcceptableOrUnknown(data['alamat']!, _alamatMeta),
      );
    }
    if (data.containsKey('catatan')) {
      context.handle(
        _catatanMeta,
        catatan.isAcceptableOrUnknown(data['catatan']!, _catatanMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('auth_user_id')) {
      context.handle(
        _authUserIdMeta,
        authUserId.isAcceptableOrUnknown(
          data['auth_user_id']!,
          _authUserIdMeta,
        ),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nama: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nama'],
      )!,
      noHp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}no_hp'],
      ),
      alamat: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alamat'],
      ),
      catatan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catatan'],
      ),
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      authUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auth_user_id'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
    );
  }

  @override
  $CustomersTable createAlias(String alias) {
    return $CustomersTable(attachedDatabase, alias);
  }
}

class CustomerRow extends DataClass implements Insertable<CustomerRow> {
  final String id;
  final String nama;
  final String? noHp;
  final String? alamat;
  final String? catatan;
  final bool isArchived;
  final String? authUserId;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool isDirty;
  const CustomerRow({
    required this.id,
    required this.nama,
    this.noHp,
    this.alamat,
    this.catatan,
    required this.isArchived,
    this.authUserId,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.isDirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nama'] = Variable<String>(nama);
    if (!nullToAbsent || noHp != null) {
      map['no_hp'] = Variable<String>(noHp);
    }
    if (!nullToAbsent || alamat != null) {
      map['alamat'] = Variable<String>(alamat);
    }
    if (!nullToAbsent || catatan != null) {
      map['catatan'] = Variable<String>(catatan);
    }
    map['is_archived'] = Variable<bool>(isArchived);
    if (!nullToAbsent || authUserId != null) {
      map['auth_user_id'] = Variable<String>(authUserId);
    }
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['is_dirty'] = Variable<bool>(isDirty);
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      nama: Value(nama),
      noHp: noHp == null && nullToAbsent ? const Value.absent() : Value(noHp),
      alamat: alamat == null && nullToAbsent
          ? const Value.absent()
          : Value(alamat),
      catatan: catatan == null && nullToAbsent
          ? const Value.absent()
          : Value(catatan),
      isArchived: Value(isArchived),
      authUserId: authUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(authUserId),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      isDirty: Value(isDirty),
    );
  }

  factory CustomerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerRow(
      id: serializer.fromJson<String>(json['id']),
      nama: serializer.fromJson<String>(json['nama']),
      noHp: serializer.fromJson<String?>(json['noHp']),
      alamat: serializer.fromJson<String?>(json['alamat']),
      catatan: serializer.fromJson<String?>(json['catatan']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      authUserId: serializer.fromJson<String?>(json['authUserId']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nama': serializer.toJson<String>(nama),
      'noHp': serializer.toJson<String?>(noHp),
      'alamat': serializer.toJson<String?>(alamat),
      'catatan': serializer.toJson<String?>(catatan),
      'isArchived': serializer.toJson<bool>(isArchived),
      'authUserId': serializer.toJson<String?>(authUserId),
      'createdBy': serializer.toJson<String?>(createdBy),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'isDirty': serializer.toJson<bool>(isDirty),
    };
  }

  CustomerRow copyWith({
    String? id,
    String? nama,
    Value<String?> noHp = const Value.absent(),
    Value<String?> alamat = const Value.absent(),
    Value<String?> catatan = const Value.absent(),
    bool? isArchived,
    Value<String?> authUserId = const Value.absent(),
    Value<String?> createdBy = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? isDirty,
  }) => CustomerRow(
    id: id ?? this.id,
    nama: nama ?? this.nama,
    noHp: noHp.present ? noHp.value : this.noHp,
    alamat: alamat.present ? alamat.value : this.alamat,
    catatan: catatan.present ? catatan.value : this.catatan,
    isArchived: isArchived ?? this.isArchived,
    authUserId: authUserId.present ? authUserId.value : this.authUserId,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    isDirty: isDirty ?? this.isDirty,
  );
  CustomerRow copyWithCompanion(CustomersCompanion data) {
    return CustomerRow(
      id: data.id.present ? data.id.value : this.id,
      nama: data.nama.present ? data.nama.value : this.nama,
      noHp: data.noHp.present ? data.noHp.value : this.noHp,
      alamat: data.alamat.present ? data.alamat.value : this.alamat,
      catatan: data.catatan.present ? data.catatan.value : this.catatan,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      authUserId: data.authUserId.present
          ? data.authUserId.value
          : this.authUserId,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerRow(')
          ..write('id: $id, ')
          ..write('nama: $nama, ')
          ..write('noHp: $noHp, ')
          ..write('alamat: $alamat, ')
          ..write('catatan: $catatan, ')
          ..write('isArchived: $isArchived, ')
          ..write('authUserId: $authUserId, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('isDirty: $isDirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nama,
    noHp,
    alamat,
    catatan,
    isArchived,
    authUserId,
    createdBy,
    createdAt,
    updatedAt,
    deletedAt,
    isDirty,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerRow &&
          other.id == this.id &&
          other.nama == this.nama &&
          other.noHp == this.noHp &&
          other.alamat == this.alamat &&
          other.catatan == this.catatan &&
          other.isArchived == this.isArchived &&
          other.authUserId == this.authUserId &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.isDirty == this.isDirty);
}

class CustomersCompanion extends UpdateCompanion<CustomerRow> {
  final Value<String> id;
  final Value<String> nama;
  final Value<String?> noHp;
  final Value<String?> alamat;
  final Value<String?> catatan;
  final Value<bool> isArchived;
  final Value<String?> authUserId;
  final Value<String?> createdBy;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> isDirty;
  final Value<int> rowid;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.nama = const Value.absent(),
    this.noHp = const Value.absent(),
    this.alamat = const Value.absent(),
    this.catatan = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.authUserId = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomersCompanion.insert({
    required String id,
    required String nama,
    this.noHp = const Value.absent(),
    this.alamat = const Value.absent(),
    this.catatan = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.authUserId = const Value.absent(),
    this.createdBy = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nama = Value(nama),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CustomerRow> custom({
    Expression<String>? id,
    Expression<String>? nama,
    Expression<String>? noHp,
    Expression<String>? alamat,
    Expression<String>? catatan,
    Expression<bool>? isArchived,
    Expression<String>? authUserId,
    Expression<String>? createdBy,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? isDirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nama != null) 'nama': nama,
      if (noHp != null) 'no_hp': noHp,
      if (alamat != null) 'alamat': alamat,
      if (catatan != null) 'catatan': catatan,
      if (isArchived != null) 'is_archived': isArchived,
      if (authUserId != null) 'auth_user_id': authUserId,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (isDirty != null) 'is_dirty': isDirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomersCompanion copyWith({
    Value<String>? id,
    Value<String>? nama,
    Value<String?>? noHp,
    Value<String?>? alamat,
    Value<String?>? catatan,
    Value<bool>? isArchived,
    Value<String?>? authUserId,
    Value<String?>? createdBy,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? isDirty,
    Value<int>? rowid,
  }) {
    return CustomersCompanion(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      noHp: noHp ?? this.noHp,
      alamat: alamat ?? this.alamat,
      catatan: catatan ?? this.catatan,
      isArchived: isArchived ?? this.isArchived,
      authUserId: authUserId ?? this.authUserId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isDirty: isDirty ?? this.isDirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nama.present) {
      map['nama'] = Variable<String>(nama.value);
    }
    if (noHp.present) {
      map['no_hp'] = Variable<String>(noHp.value);
    }
    if (alamat.present) {
      map['alamat'] = Variable<String>(alamat.value);
    }
    if (catatan.present) {
      map['catatan'] = Variable<String>(catatan.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (authUserId.present) {
      map['auth_user_id'] = Variable<String>(authUserId.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersCompanion(')
          ..write('id: $id, ')
          ..write('nama: $nama, ')
          ..write('noHp: $noHp, ')
          ..write('alamat: $alamat, ')
          ..write('catatan: $catatan, ')
          ..write('isArchived: $isArchived, ')
          ..write('authUserId: $authUserId, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('isDirty: $isDirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PurchasesTable extends Purchases
    with TableInfo<$PurchasesTable, PurchaseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PurchasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _namaBarangMeta = const VerificationMeta(
    'namaBarang',
  );
  @override
  late final GeneratedColumn<String> namaBarang = GeneratedColumn<String>(
    'nama_barang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hargaJualMeta = const VerificationMeta(
    'hargaJual',
  );
  @override
  late final GeneratedColumn<int> hargaJual = GeneratedColumn<int>(
    'harga_jual',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hargaBeliMeta = const VerificationMeta(
    'hargaBeli',
  );
  @override
  late final GeneratedColumn<int> hargaBeli = GeneratedColumn<int>(
    'harga_beli',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tanggalBeliMeta = const VerificationMeta(
    'tanggalBeli',
  );
  @override
  late final GeneratedColumn<DateTime> tanggalBeli = GeneratedColumn<DateTime>(
    'tanggal_beli',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _catatanMeta = const VerificationMeta(
    'catatan',
  );
  @override
  late final GeneratedColumn<String> catatan = GeneratedColumn<String>(
    'catatan',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    customerId,
    namaBarang,
    hargaJual,
    hargaBeli,
    tanggalBeli,
    catatan,
    createdBy,
    createdAt,
    updatedAt,
    deletedAt,
    isDirty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchases';
  @override
  VerificationContext validateIntegrity(
    Insertable<PurchaseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('nama_barang')) {
      context.handle(
        _namaBarangMeta,
        namaBarang.isAcceptableOrUnknown(data['nama_barang']!, _namaBarangMeta),
      );
    } else if (isInserting) {
      context.missing(_namaBarangMeta);
    }
    if (data.containsKey('harga_jual')) {
      context.handle(
        _hargaJualMeta,
        hargaJual.isAcceptableOrUnknown(data['harga_jual']!, _hargaJualMeta),
      );
    } else if (isInserting) {
      context.missing(_hargaJualMeta);
    }
    if (data.containsKey('harga_beli')) {
      context.handle(
        _hargaBeliMeta,
        hargaBeli.isAcceptableOrUnknown(data['harga_beli']!, _hargaBeliMeta),
      );
    }
    if (data.containsKey('tanggal_beli')) {
      context.handle(
        _tanggalBeliMeta,
        tanggalBeli.isAcceptableOrUnknown(
          data['tanggal_beli']!,
          _tanggalBeliMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tanggalBeliMeta);
    }
    if (data.containsKey('catatan')) {
      context.handle(
        _catatanMeta,
        catatan.isAcceptableOrUnknown(data['catatan']!, _catatanMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PurchaseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PurchaseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      namaBarang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nama_barang'],
      )!,
      hargaJual: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}harga_jual'],
      )!,
      hargaBeli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}harga_beli'],
      ),
      tanggalBeli: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}tanggal_beli'],
      )!,
      catatan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catatan'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
    );
  }

  @override
  $PurchasesTable createAlias(String alias) {
    return $PurchasesTable(attachedDatabase, alias);
  }
}

class PurchaseRow extends DataClass implements Insertable<PurchaseRow> {
  final String id;
  final String customerId;
  final String namaBarang;
  final int hargaJual;
  final int? hargaBeli;
  final DateTime tanggalBeli;
  final String? catatan;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool isDirty;
  const PurchaseRow({
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
    required this.isDirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['customer_id'] = Variable<String>(customerId);
    map['nama_barang'] = Variable<String>(namaBarang);
    map['harga_jual'] = Variable<int>(hargaJual);
    if (!nullToAbsent || hargaBeli != null) {
      map['harga_beli'] = Variable<int>(hargaBeli);
    }
    map['tanggal_beli'] = Variable<DateTime>(tanggalBeli);
    if (!nullToAbsent || catatan != null) {
      map['catatan'] = Variable<String>(catatan);
    }
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['is_dirty'] = Variable<bool>(isDirty);
    return map;
  }

  PurchasesCompanion toCompanion(bool nullToAbsent) {
    return PurchasesCompanion(
      id: Value(id),
      customerId: Value(customerId),
      namaBarang: Value(namaBarang),
      hargaJual: Value(hargaJual),
      hargaBeli: hargaBeli == null && nullToAbsent
          ? const Value.absent()
          : Value(hargaBeli),
      tanggalBeli: Value(tanggalBeli),
      catatan: catatan == null && nullToAbsent
          ? const Value.absent()
          : Value(catatan),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      isDirty: Value(isDirty),
    );
  }

  factory PurchaseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PurchaseRow(
      id: serializer.fromJson<String>(json['id']),
      customerId: serializer.fromJson<String>(json['customerId']),
      namaBarang: serializer.fromJson<String>(json['namaBarang']),
      hargaJual: serializer.fromJson<int>(json['hargaJual']),
      hargaBeli: serializer.fromJson<int?>(json['hargaBeli']),
      tanggalBeli: serializer.fromJson<DateTime>(json['tanggalBeli']),
      catatan: serializer.fromJson<String?>(json['catatan']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'customerId': serializer.toJson<String>(customerId),
      'namaBarang': serializer.toJson<String>(namaBarang),
      'hargaJual': serializer.toJson<int>(hargaJual),
      'hargaBeli': serializer.toJson<int?>(hargaBeli),
      'tanggalBeli': serializer.toJson<DateTime>(tanggalBeli),
      'catatan': serializer.toJson<String?>(catatan),
      'createdBy': serializer.toJson<String?>(createdBy),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'isDirty': serializer.toJson<bool>(isDirty),
    };
  }

  PurchaseRow copyWith({
    String? id,
    String? customerId,
    String? namaBarang,
    int? hargaJual,
    Value<int?> hargaBeli = const Value.absent(),
    DateTime? tanggalBeli,
    Value<String?> catatan = const Value.absent(),
    Value<String?> createdBy = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? isDirty,
  }) => PurchaseRow(
    id: id ?? this.id,
    customerId: customerId ?? this.customerId,
    namaBarang: namaBarang ?? this.namaBarang,
    hargaJual: hargaJual ?? this.hargaJual,
    hargaBeli: hargaBeli.present ? hargaBeli.value : this.hargaBeli,
    tanggalBeli: tanggalBeli ?? this.tanggalBeli,
    catatan: catatan.present ? catatan.value : this.catatan,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    isDirty: isDirty ?? this.isDirty,
  );
  PurchaseRow copyWithCompanion(PurchasesCompanion data) {
    return PurchaseRow(
      id: data.id.present ? data.id.value : this.id,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      namaBarang: data.namaBarang.present
          ? data.namaBarang.value
          : this.namaBarang,
      hargaJual: data.hargaJual.present ? data.hargaJual.value : this.hargaJual,
      hargaBeli: data.hargaBeli.present ? data.hargaBeli.value : this.hargaBeli,
      tanggalBeli: data.tanggalBeli.present
          ? data.tanggalBeli.value
          : this.tanggalBeli,
      catatan: data.catatan.present ? data.catatan.value : this.catatan,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseRow(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('namaBarang: $namaBarang, ')
          ..write('hargaJual: $hargaJual, ')
          ..write('hargaBeli: $hargaBeli, ')
          ..write('tanggalBeli: $tanggalBeli, ')
          ..write('catatan: $catatan, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('isDirty: $isDirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    customerId,
    namaBarang,
    hargaJual,
    hargaBeli,
    tanggalBeli,
    catatan,
    createdBy,
    createdAt,
    updatedAt,
    deletedAt,
    isDirty,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PurchaseRow &&
          other.id == this.id &&
          other.customerId == this.customerId &&
          other.namaBarang == this.namaBarang &&
          other.hargaJual == this.hargaJual &&
          other.hargaBeli == this.hargaBeli &&
          other.tanggalBeli == this.tanggalBeli &&
          other.catatan == this.catatan &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.isDirty == this.isDirty);
}

class PurchasesCompanion extends UpdateCompanion<PurchaseRow> {
  final Value<String> id;
  final Value<String> customerId;
  final Value<String> namaBarang;
  final Value<int> hargaJual;
  final Value<int?> hargaBeli;
  final Value<DateTime> tanggalBeli;
  final Value<String?> catatan;
  final Value<String?> createdBy;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> isDirty;
  final Value<int> rowid;
  const PurchasesCompanion({
    this.id = const Value.absent(),
    this.customerId = const Value.absent(),
    this.namaBarang = const Value.absent(),
    this.hargaJual = const Value.absent(),
    this.hargaBeli = const Value.absent(),
    this.tanggalBeli = const Value.absent(),
    this.catatan = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PurchasesCompanion.insert({
    required String id,
    required String customerId,
    required String namaBarang,
    required int hargaJual,
    this.hargaBeli = const Value.absent(),
    required DateTime tanggalBeli,
    this.catatan = const Value.absent(),
    this.createdBy = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       customerId = Value(customerId),
       namaBarang = Value(namaBarang),
       hargaJual = Value(hargaJual),
       tanggalBeli = Value(tanggalBeli),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PurchaseRow> custom({
    Expression<String>? id,
    Expression<String>? customerId,
    Expression<String>? namaBarang,
    Expression<int>? hargaJual,
    Expression<int>? hargaBeli,
    Expression<DateTime>? tanggalBeli,
    Expression<String>? catatan,
    Expression<String>? createdBy,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? isDirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (customerId != null) 'customer_id': customerId,
      if (namaBarang != null) 'nama_barang': namaBarang,
      if (hargaJual != null) 'harga_jual': hargaJual,
      if (hargaBeli != null) 'harga_beli': hargaBeli,
      if (tanggalBeli != null) 'tanggal_beli': tanggalBeli,
      if (catatan != null) 'catatan': catatan,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (isDirty != null) 'is_dirty': isDirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PurchasesCompanion copyWith({
    Value<String>? id,
    Value<String>? customerId,
    Value<String>? namaBarang,
    Value<int>? hargaJual,
    Value<int?>? hargaBeli,
    Value<DateTime>? tanggalBeli,
    Value<String?>? catatan,
    Value<String?>? createdBy,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? isDirty,
    Value<int>? rowid,
  }) {
    return PurchasesCompanion(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      namaBarang: namaBarang ?? this.namaBarang,
      hargaJual: hargaJual ?? this.hargaJual,
      hargaBeli: hargaBeli ?? this.hargaBeli,
      tanggalBeli: tanggalBeli ?? this.tanggalBeli,
      catatan: catatan ?? this.catatan,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isDirty: isDirty ?? this.isDirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (namaBarang.present) {
      map['nama_barang'] = Variable<String>(namaBarang.value);
    }
    if (hargaJual.present) {
      map['harga_jual'] = Variable<int>(hargaJual.value);
    }
    if (hargaBeli.present) {
      map['harga_beli'] = Variable<int>(hargaBeli.value);
    }
    if (tanggalBeli.present) {
      map['tanggal_beli'] = Variable<DateTime>(tanggalBeli.value);
    }
    if (catatan.present) {
      map['catatan'] = Variable<String>(catatan.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PurchasesCompanion(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('namaBarang: $namaBarang, ')
          ..write('hargaJual: $hargaJual, ')
          ..write('hargaBeli: $hargaBeli, ')
          ..write('tanggalBeli: $tanggalBeli, ')
          ..write('catatan: $catatan, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('isDirty: $isDirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaymentsTable extends Payments
    with TableInfo<$PaymentsTable, PaymentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jumlahMeta = const VerificationMeta('jumlah');
  @override
  late final GeneratedColumn<int> jumlah = GeneratedColumn<int>(
    'jumlah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tanggalBayarMeta = const VerificationMeta(
    'tanggalBayar',
  );
  @override
  late final GeneratedColumn<DateTime> tanggalBayar = GeneratedColumn<DateTime>(
    'tanggal_bayar',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metodeMeta = const VerificationMeta('metode');
  @override
  late final GeneratedColumn<String> metode = GeneratedColumn<String>(
    'metode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('tunai'),
  );
  static const VerificationMeta _catatanMeta = const VerificationMeta(
    'catatan',
  );
  @override
  late final GeneratedColumn<String> catatan = GeneratedColumn<String>(
    'catatan',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sumberMeta = const VerificationMeta('sumber');
  @override
  late final GeneratedColumn<String> sumber = GeneratedColumn<String>(
    'sumber',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('admin'),
  );
  static const VerificationMeta _statusVerifikasiMeta = const VerificationMeta(
    'statusVerifikasi',
  );
  @override
  late final GeneratedColumn<String> statusVerifikasi = GeneratedColumn<String>(
    'status_verifikasi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('verified'),
  );
  static const VerificationMeta _buktiFotoUrlMeta = const VerificationMeta(
    'buktiFotoUrl',
  );
  @override
  late final GeneratedColumn<String> buktiFotoUrl = GeneratedColumn<String>(
    'bukti_foto_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    customerId,
    jumlah,
    tanggalBayar,
    metode,
    catatan,
    sumber,
    statusVerifikasi,
    buktiFotoUrl,
    createdBy,
    createdAt,
    updatedAt,
    deletedAt,
    isDirty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaymentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('jumlah')) {
      context.handle(
        _jumlahMeta,
        jumlah.isAcceptableOrUnknown(data['jumlah']!, _jumlahMeta),
      );
    } else if (isInserting) {
      context.missing(_jumlahMeta);
    }
    if (data.containsKey('tanggal_bayar')) {
      context.handle(
        _tanggalBayarMeta,
        tanggalBayar.isAcceptableOrUnknown(
          data['tanggal_bayar']!,
          _tanggalBayarMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tanggalBayarMeta);
    }
    if (data.containsKey('metode')) {
      context.handle(
        _metodeMeta,
        metode.isAcceptableOrUnknown(data['metode']!, _metodeMeta),
      );
    }
    if (data.containsKey('catatan')) {
      context.handle(
        _catatanMeta,
        catatan.isAcceptableOrUnknown(data['catatan']!, _catatanMeta),
      );
    }
    if (data.containsKey('sumber')) {
      context.handle(
        _sumberMeta,
        sumber.isAcceptableOrUnknown(data['sumber']!, _sumberMeta),
      );
    }
    if (data.containsKey('status_verifikasi')) {
      context.handle(
        _statusVerifikasiMeta,
        statusVerifikasi.isAcceptableOrUnknown(
          data['status_verifikasi']!,
          _statusVerifikasiMeta,
        ),
      );
    }
    if (data.containsKey('bukti_foto_url')) {
      context.handle(
        _buktiFotoUrlMeta,
        buktiFotoUrl.isAcceptableOrUnknown(
          data['bukti_foto_url']!,
          _buktiFotoUrlMeta,
        ),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PaymentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      jumlah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}jumlah'],
      )!,
      tanggalBayar: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}tanggal_bayar'],
      )!,
      metode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metode'],
      )!,
      catatan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catatan'],
      ),
      sumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sumber'],
      )!,
      statusVerifikasi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status_verifikasi'],
      )!,
      buktiFotoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bukti_foto_url'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
    );
  }

  @override
  $PaymentsTable createAlias(String alias) {
    return $PaymentsTable(attachedDatabase, alias);
  }
}

class PaymentRow extends DataClass implements Insertable<PaymentRow> {
  final String id;
  final String customerId;
  final int jumlah;
  final DateTime tanggalBayar;
  final String metode;
  final String? catatan;
  final String sumber;
  final String statusVerifikasi;
  final String? buktiFotoUrl;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool isDirty;
  const PaymentRow({
    required this.id,
    required this.customerId,
    required this.jumlah,
    required this.tanggalBayar,
    required this.metode,
    this.catatan,
    required this.sumber,
    required this.statusVerifikasi,
    this.buktiFotoUrl,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.isDirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['customer_id'] = Variable<String>(customerId);
    map['jumlah'] = Variable<int>(jumlah);
    map['tanggal_bayar'] = Variable<DateTime>(tanggalBayar);
    map['metode'] = Variable<String>(metode);
    if (!nullToAbsent || catatan != null) {
      map['catatan'] = Variable<String>(catatan);
    }
    map['sumber'] = Variable<String>(sumber);
    map['status_verifikasi'] = Variable<String>(statusVerifikasi);
    if (!nullToAbsent || buktiFotoUrl != null) {
      map['bukti_foto_url'] = Variable<String>(buktiFotoUrl);
    }
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['is_dirty'] = Variable<bool>(isDirty);
    return map;
  }

  PaymentsCompanion toCompanion(bool nullToAbsent) {
    return PaymentsCompanion(
      id: Value(id),
      customerId: Value(customerId),
      jumlah: Value(jumlah),
      tanggalBayar: Value(tanggalBayar),
      metode: Value(metode),
      catatan: catatan == null && nullToAbsent
          ? const Value.absent()
          : Value(catatan),
      sumber: Value(sumber),
      statusVerifikasi: Value(statusVerifikasi),
      buktiFotoUrl: buktiFotoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(buktiFotoUrl),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      isDirty: Value(isDirty),
    );
  }

  factory PaymentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentRow(
      id: serializer.fromJson<String>(json['id']),
      customerId: serializer.fromJson<String>(json['customerId']),
      jumlah: serializer.fromJson<int>(json['jumlah']),
      tanggalBayar: serializer.fromJson<DateTime>(json['tanggalBayar']),
      metode: serializer.fromJson<String>(json['metode']),
      catatan: serializer.fromJson<String?>(json['catatan']),
      sumber: serializer.fromJson<String>(json['sumber']),
      statusVerifikasi: serializer.fromJson<String>(json['statusVerifikasi']),
      buktiFotoUrl: serializer.fromJson<String?>(json['buktiFotoUrl']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'customerId': serializer.toJson<String>(customerId),
      'jumlah': serializer.toJson<int>(jumlah),
      'tanggalBayar': serializer.toJson<DateTime>(tanggalBayar),
      'metode': serializer.toJson<String>(metode),
      'catatan': serializer.toJson<String?>(catatan),
      'sumber': serializer.toJson<String>(sumber),
      'statusVerifikasi': serializer.toJson<String>(statusVerifikasi),
      'buktiFotoUrl': serializer.toJson<String?>(buktiFotoUrl),
      'createdBy': serializer.toJson<String?>(createdBy),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'isDirty': serializer.toJson<bool>(isDirty),
    };
  }

  PaymentRow copyWith({
    String? id,
    String? customerId,
    int? jumlah,
    DateTime? tanggalBayar,
    String? metode,
    Value<String?> catatan = const Value.absent(),
    String? sumber,
    String? statusVerifikasi,
    Value<String?> buktiFotoUrl = const Value.absent(),
    Value<String?> createdBy = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? isDirty,
  }) => PaymentRow(
    id: id ?? this.id,
    customerId: customerId ?? this.customerId,
    jumlah: jumlah ?? this.jumlah,
    tanggalBayar: tanggalBayar ?? this.tanggalBayar,
    metode: metode ?? this.metode,
    catatan: catatan.present ? catatan.value : this.catatan,
    sumber: sumber ?? this.sumber,
    statusVerifikasi: statusVerifikasi ?? this.statusVerifikasi,
    buktiFotoUrl: buktiFotoUrl.present ? buktiFotoUrl.value : this.buktiFotoUrl,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    isDirty: isDirty ?? this.isDirty,
  );
  PaymentRow copyWithCompanion(PaymentsCompanion data) {
    return PaymentRow(
      id: data.id.present ? data.id.value : this.id,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      jumlah: data.jumlah.present ? data.jumlah.value : this.jumlah,
      tanggalBayar: data.tanggalBayar.present
          ? data.tanggalBayar.value
          : this.tanggalBayar,
      metode: data.metode.present ? data.metode.value : this.metode,
      catatan: data.catatan.present ? data.catatan.value : this.catatan,
      sumber: data.sumber.present ? data.sumber.value : this.sumber,
      statusVerifikasi: data.statusVerifikasi.present
          ? data.statusVerifikasi.value
          : this.statusVerifikasi,
      buktiFotoUrl: data.buktiFotoUrl.present
          ? data.buktiFotoUrl.value
          : this.buktiFotoUrl,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentRow(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('jumlah: $jumlah, ')
          ..write('tanggalBayar: $tanggalBayar, ')
          ..write('metode: $metode, ')
          ..write('catatan: $catatan, ')
          ..write('sumber: $sumber, ')
          ..write('statusVerifikasi: $statusVerifikasi, ')
          ..write('buktiFotoUrl: $buktiFotoUrl, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('isDirty: $isDirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    customerId,
    jumlah,
    tanggalBayar,
    metode,
    catatan,
    sumber,
    statusVerifikasi,
    buktiFotoUrl,
    createdBy,
    createdAt,
    updatedAt,
    deletedAt,
    isDirty,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentRow &&
          other.id == this.id &&
          other.customerId == this.customerId &&
          other.jumlah == this.jumlah &&
          other.tanggalBayar == this.tanggalBayar &&
          other.metode == this.metode &&
          other.catatan == this.catatan &&
          other.sumber == this.sumber &&
          other.statusVerifikasi == this.statusVerifikasi &&
          other.buktiFotoUrl == this.buktiFotoUrl &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.isDirty == this.isDirty);
}

class PaymentsCompanion extends UpdateCompanion<PaymentRow> {
  final Value<String> id;
  final Value<String> customerId;
  final Value<int> jumlah;
  final Value<DateTime> tanggalBayar;
  final Value<String> metode;
  final Value<String?> catatan;
  final Value<String> sumber;
  final Value<String> statusVerifikasi;
  final Value<String?> buktiFotoUrl;
  final Value<String?> createdBy;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> isDirty;
  final Value<int> rowid;
  const PaymentsCompanion({
    this.id = const Value.absent(),
    this.customerId = const Value.absent(),
    this.jumlah = const Value.absent(),
    this.tanggalBayar = const Value.absent(),
    this.metode = const Value.absent(),
    this.catatan = const Value.absent(),
    this.sumber = const Value.absent(),
    this.statusVerifikasi = const Value.absent(),
    this.buktiFotoUrl = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentsCompanion.insert({
    required String id,
    required String customerId,
    required int jumlah,
    required DateTime tanggalBayar,
    this.metode = const Value.absent(),
    this.catatan = const Value.absent(),
    this.sumber = const Value.absent(),
    this.statusVerifikasi = const Value.absent(),
    this.buktiFotoUrl = const Value.absent(),
    this.createdBy = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       customerId = Value(customerId),
       jumlah = Value(jumlah),
       tanggalBayar = Value(tanggalBayar),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PaymentRow> custom({
    Expression<String>? id,
    Expression<String>? customerId,
    Expression<int>? jumlah,
    Expression<DateTime>? tanggalBayar,
    Expression<String>? metode,
    Expression<String>? catatan,
    Expression<String>? sumber,
    Expression<String>? statusVerifikasi,
    Expression<String>? buktiFotoUrl,
    Expression<String>? createdBy,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? isDirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (customerId != null) 'customer_id': customerId,
      if (jumlah != null) 'jumlah': jumlah,
      if (tanggalBayar != null) 'tanggal_bayar': tanggalBayar,
      if (metode != null) 'metode': metode,
      if (catatan != null) 'catatan': catatan,
      if (sumber != null) 'sumber': sumber,
      if (statusVerifikasi != null) 'status_verifikasi': statusVerifikasi,
      if (buktiFotoUrl != null) 'bukti_foto_url': buktiFotoUrl,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (isDirty != null) 'is_dirty': isDirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentsCompanion copyWith({
    Value<String>? id,
    Value<String>? customerId,
    Value<int>? jumlah,
    Value<DateTime>? tanggalBayar,
    Value<String>? metode,
    Value<String?>? catatan,
    Value<String>? sumber,
    Value<String>? statusVerifikasi,
    Value<String?>? buktiFotoUrl,
    Value<String?>? createdBy,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? isDirty,
    Value<int>? rowid,
  }) {
    return PaymentsCompanion(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      jumlah: jumlah ?? this.jumlah,
      tanggalBayar: tanggalBayar ?? this.tanggalBayar,
      metode: metode ?? this.metode,
      catatan: catatan ?? this.catatan,
      sumber: sumber ?? this.sumber,
      statusVerifikasi: statusVerifikasi ?? this.statusVerifikasi,
      buktiFotoUrl: buktiFotoUrl ?? this.buktiFotoUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isDirty: isDirty ?? this.isDirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (jumlah.present) {
      map['jumlah'] = Variable<int>(jumlah.value);
    }
    if (tanggalBayar.present) {
      map['tanggal_bayar'] = Variable<DateTime>(tanggalBayar.value);
    }
    if (metode.present) {
      map['metode'] = Variable<String>(metode.value);
    }
    if (catatan.present) {
      map['catatan'] = Variable<String>(catatan.value);
    }
    if (sumber.present) {
      map['sumber'] = Variable<String>(sumber.value);
    }
    if (statusVerifikasi.present) {
      map['status_verifikasi'] = Variable<String>(statusVerifikasi.value);
    }
    if (buktiFotoUrl.present) {
      map['bukti_foto_url'] = Variable<String>(buktiFotoUrl.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentsCompanion(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('jumlah: $jumlah, ')
          ..write('tanggalBayar: $tanggalBayar, ')
          ..write('metode: $metode, ')
          ..write('catatan: $catatan, ')
          ..write('sumber: $sumber, ')
          ..write('statusVerifikasi: $statusVerifikasi, ')
          ..write('buktiFotoUrl: $buktiFotoUrl, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('isDirty: $isDirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetEntriesTable extends BudgetEntries
    with TableInfo<$BudgetEntriesTable, BudgetEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tanggalMeta = const VerificationMeta(
    'tanggal',
  );
  @override
  late final GeneratedColumn<DateTime> tanggal = GeneratedColumn<DateTime>(
    'tanggal',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _namaTransaksiMeta = const VerificationMeta(
    'namaTransaksi',
  );
  @override
  late final GeneratedColumn<String> namaTransaksi = GeneratedColumn<String>(
    'nama_transaksi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipeMeta = const VerificationMeta('tipe');
  @override
  late final GeneratedColumn<String> tipe = GeneratedColumn<String>(
    'tipe',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jumlahMeta = const VerificationMeta('jumlah');
  @override
  late final GeneratedColumn<int> jumlah = GeneratedColumn<int>(
    'jumlah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _catatanMeta = const VerificationMeta(
    'catatan',
  );
  @override
  late final GeneratedColumn<String> catatan = GeneratedColumn<String>(
    'catatan',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tanggal,
    namaTransaksi,
    tipe,
    jumlah,
    catatan,
    createdBy,
    createdAt,
    updatedAt,
    deletedAt,
    isDirty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tanggal')) {
      context.handle(
        _tanggalMeta,
        tanggal.isAcceptableOrUnknown(data['tanggal']!, _tanggalMeta),
      );
    } else if (isInserting) {
      context.missing(_tanggalMeta);
    }
    if (data.containsKey('nama_transaksi')) {
      context.handle(
        _namaTransaksiMeta,
        namaTransaksi.isAcceptableOrUnknown(
          data['nama_transaksi']!,
          _namaTransaksiMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_namaTransaksiMeta);
    }
    if (data.containsKey('tipe')) {
      context.handle(
        _tipeMeta,
        tipe.isAcceptableOrUnknown(data['tipe']!, _tipeMeta),
      );
    } else if (isInserting) {
      context.missing(_tipeMeta);
    }
    if (data.containsKey('jumlah')) {
      context.handle(
        _jumlahMeta,
        jumlah.isAcceptableOrUnknown(data['jumlah']!, _jumlahMeta),
      );
    } else if (isInserting) {
      context.missing(_jumlahMeta);
    }
    if (data.containsKey('catatan')) {
      context.handle(
        _catatanMeta,
        catatan.isAcceptableOrUnknown(data['catatan']!, _catatanMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BudgetEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tanggal: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}tanggal'],
      )!,
      namaTransaksi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nama_transaksi'],
      )!,
      tipe: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipe'],
      )!,
      jumlah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}jumlah'],
      )!,
      catatan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catatan'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
    );
  }

  @override
  $BudgetEntriesTable createAlias(String alias) {
    return $BudgetEntriesTable(attachedDatabase, alias);
  }
}

class BudgetEntryRow extends DataClass implements Insertable<BudgetEntryRow> {
  final String id;
  final DateTime tanggal;
  final String namaTransaksi;
  final String tipe;
  final int jumlah;
  final String? catatan;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool isDirty;
  const BudgetEntryRow({
    required this.id,
    required this.tanggal,
    required this.namaTransaksi,
    required this.tipe,
    required this.jumlah,
    this.catatan,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.isDirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tanggal'] = Variable<DateTime>(tanggal);
    map['nama_transaksi'] = Variable<String>(namaTransaksi);
    map['tipe'] = Variable<String>(tipe);
    map['jumlah'] = Variable<int>(jumlah);
    if (!nullToAbsent || catatan != null) {
      map['catatan'] = Variable<String>(catatan);
    }
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['is_dirty'] = Variable<bool>(isDirty);
    return map;
  }

  BudgetEntriesCompanion toCompanion(bool nullToAbsent) {
    return BudgetEntriesCompanion(
      id: Value(id),
      tanggal: Value(tanggal),
      namaTransaksi: Value(namaTransaksi),
      tipe: Value(tipe),
      jumlah: Value(jumlah),
      catatan: catatan == null && nullToAbsent
          ? const Value.absent()
          : Value(catatan),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      isDirty: Value(isDirty),
    );
  }

  factory BudgetEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetEntryRow(
      id: serializer.fromJson<String>(json['id']),
      tanggal: serializer.fromJson<DateTime>(json['tanggal']),
      namaTransaksi: serializer.fromJson<String>(json['namaTransaksi']),
      tipe: serializer.fromJson<String>(json['tipe']),
      jumlah: serializer.fromJson<int>(json['jumlah']),
      catatan: serializer.fromJson<String?>(json['catatan']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tanggal': serializer.toJson<DateTime>(tanggal),
      'namaTransaksi': serializer.toJson<String>(namaTransaksi),
      'tipe': serializer.toJson<String>(tipe),
      'jumlah': serializer.toJson<int>(jumlah),
      'catatan': serializer.toJson<String?>(catatan),
      'createdBy': serializer.toJson<String?>(createdBy),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'isDirty': serializer.toJson<bool>(isDirty),
    };
  }

  BudgetEntryRow copyWith({
    String? id,
    DateTime? tanggal,
    String? namaTransaksi,
    String? tipe,
    int? jumlah,
    Value<String?> catatan = const Value.absent(),
    Value<String?> createdBy = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? isDirty,
  }) => BudgetEntryRow(
    id: id ?? this.id,
    tanggal: tanggal ?? this.tanggal,
    namaTransaksi: namaTransaksi ?? this.namaTransaksi,
    tipe: tipe ?? this.tipe,
    jumlah: jumlah ?? this.jumlah,
    catatan: catatan.present ? catatan.value : this.catatan,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    isDirty: isDirty ?? this.isDirty,
  );
  BudgetEntryRow copyWithCompanion(BudgetEntriesCompanion data) {
    return BudgetEntryRow(
      id: data.id.present ? data.id.value : this.id,
      tanggal: data.tanggal.present ? data.tanggal.value : this.tanggal,
      namaTransaksi: data.namaTransaksi.present
          ? data.namaTransaksi.value
          : this.namaTransaksi,
      tipe: data.tipe.present ? data.tipe.value : this.tipe,
      jumlah: data.jumlah.present ? data.jumlah.value : this.jumlah,
      catatan: data.catatan.present ? data.catatan.value : this.catatan,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetEntryRow(')
          ..write('id: $id, ')
          ..write('tanggal: $tanggal, ')
          ..write('namaTransaksi: $namaTransaksi, ')
          ..write('tipe: $tipe, ')
          ..write('jumlah: $jumlah, ')
          ..write('catatan: $catatan, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('isDirty: $isDirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tanggal,
    namaTransaksi,
    tipe,
    jumlah,
    catatan,
    createdBy,
    createdAt,
    updatedAt,
    deletedAt,
    isDirty,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetEntryRow &&
          other.id == this.id &&
          other.tanggal == this.tanggal &&
          other.namaTransaksi == this.namaTransaksi &&
          other.tipe == this.tipe &&
          other.jumlah == this.jumlah &&
          other.catatan == this.catatan &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.isDirty == this.isDirty);
}

class BudgetEntriesCompanion extends UpdateCompanion<BudgetEntryRow> {
  final Value<String> id;
  final Value<DateTime> tanggal;
  final Value<String> namaTransaksi;
  final Value<String> tipe;
  final Value<int> jumlah;
  final Value<String?> catatan;
  final Value<String?> createdBy;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> isDirty;
  final Value<int> rowid;
  const BudgetEntriesCompanion({
    this.id = const Value.absent(),
    this.tanggal = const Value.absent(),
    this.namaTransaksi = const Value.absent(),
    this.tipe = const Value.absent(),
    this.jumlah = const Value.absent(),
    this.catatan = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetEntriesCompanion.insert({
    required String id,
    required DateTime tanggal,
    required String namaTransaksi,
    required String tipe,
    required int jumlah,
    this.catatan = const Value.absent(),
    this.createdBy = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tanggal = Value(tanggal),
       namaTransaksi = Value(namaTransaksi),
       tipe = Value(tipe),
       jumlah = Value(jumlah),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<BudgetEntryRow> custom({
    Expression<String>? id,
    Expression<DateTime>? tanggal,
    Expression<String>? namaTransaksi,
    Expression<String>? tipe,
    Expression<int>? jumlah,
    Expression<String>? catatan,
    Expression<String>? createdBy,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? isDirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tanggal != null) 'tanggal': tanggal,
      if (namaTransaksi != null) 'nama_transaksi': namaTransaksi,
      if (tipe != null) 'tipe': tipe,
      if (jumlah != null) 'jumlah': jumlah,
      if (catatan != null) 'catatan': catatan,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (isDirty != null) 'is_dirty': isDirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetEntriesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? tanggal,
    Value<String>? namaTransaksi,
    Value<String>? tipe,
    Value<int>? jumlah,
    Value<String?>? catatan,
    Value<String?>? createdBy,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? isDirty,
    Value<int>? rowid,
  }) {
    return BudgetEntriesCompanion(
      id: id ?? this.id,
      tanggal: tanggal ?? this.tanggal,
      namaTransaksi: namaTransaksi ?? this.namaTransaksi,
      tipe: tipe ?? this.tipe,
      jumlah: jumlah ?? this.jumlah,
      catatan: catatan ?? this.catatan,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isDirty: isDirty ?? this.isDirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tanggal.present) {
      map['tanggal'] = Variable<DateTime>(tanggal.value);
    }
    if (namaTransaksi.present) {
      map['nama_transaksi'] = Variable<String>(namaTransaksi.value);
    }
    if (tipe.present) {
      map['tipe'] = Variable<String>(tipe.value);
    }
    if (jumlah.present) {
      map['jumlah'] = Variable<int>(jumlah.value);
    }
    if (catatan.present) {
      map['catatan'] = Variable<String>(catatan.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetEntriesCompanion(')
          ..write('id: $id, ')
          ..write('tanggal: $tanggal, ')
          ..write('namaTransaksi: $namaTransaksi, ')
          ..write('tipe: $tipe, ')
          ..write('jumlah: $jumlah, ')
          ..write('catatan: $catatan, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('isDirty: $isDirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CustomersTable customers = $CustomersTable(this);
  late final $PurchasesTable purchases = $PurchasesTable(this);
  late final $PaymentsTable payments = $PaymentsTable(this);
  late final $BudgetEntriesTable budgetEntries = $BudgetEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    customers,
    purchases,
    payments,
    budgetEntries,
  ];
}

typedef $$CustomersTableCreateCompanionBuilder =
    CustomersCompanion Function({
      required String id,
      required String nama,
      Value<String?> noHp,
      Value<String?> alamat,
      Value<String?> catatan,
      Value<bool> isArchived,
      Value<String?> authUserId,
      Value<String?> createdBy,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> isDirty,
      Value<int> rowid,
    });
typedef $$CustomersTableUpdateCompanionBuilder =
    CustomersCompanion Function({
      Value<String> id,
      Value<String> nama,
      Value<String?> noHp,
      Value<String?> alamat,
      Value<String?> catatan,
      Value<bool> isArchived,
      Value<String?> authUserId,
      Value<String?> createdBy,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> isDirty,
      Value<int> rowid,
    });

class $$CustomersTableFilterComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nama => $composableBuilder(
    column: $table.nama,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noHp => $composableBuilder(
    column: $table.noHp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alamat => $composableBuilder(
    column: $table.alamat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catatan => $composableBuilder(
    column: $table.catatan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authUserId => $composableBuilder(
    column: $table.authUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomersTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nama => $composableBuilder(
    column: $table.nama,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noHp => $composableBuilder(
    column: $table.noHp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alamat => $composableBuilder(
    column: $table.alamat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catatan => $composableBuilder(
    column: $table.catatan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authUserId => $composableBuilder(
    column: $table.authUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nama =>
      $composableBuilder(column: $table.nama, builder: (column) => column);

  GeneratedColumn<String> get noHp =>
      $composableBuilder(column: $table.noHp, builder: (column) => column);

  GeneratedColumn<String> get alamat =>
      $composableBuilder(column: $table.alamat, builder: (column) => column);

  GeneratedColumn<String> get catatan =>
      $composableBuilder(column: $table.catatan, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authUserId => $composableBuilder(
    column: $table.authUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);
}

class $$CustomersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomersTable,
          CustomerRow,
          $$CustomersTableFilterComposer,
          $$CustomersTableOrderingComposer,
          $$CustomersTableAnnotationComposer,
          $$CustomersTableCreateCompanionBuilder,
          $$CustomersTableUpdateCompanionBuilder,
          (
            CustomerRow,
            BaseReferences<_$AppDatabase, $CustomersTable, CustomerRow>,
          ),
          CustomerRow,
          PrefetchHooks Function()
        > {
  $$CustomersTableTableManager(_$AppDatabase db, $CustomersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nama = const Value.absent(),
                Value<String?> noHp = const Value.absent(),
                Value<String?> alamat = const Value.absent(),
                Value<String?> catatan = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String?> authUserId = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersCompanion(
                id: id,
                nama: nama,
                noHp: noHp,
                alamat: alamat,
                catatan: catatan,
                isArchived: isArchived,
                authUserId: authUserId,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                isDirty: isDirty,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nama,
                Value<String?> noHp = const Value.absent(),
                Value<String?> alamat = const Value.absent(),
                Value<String?> catatan = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String?> authUserId = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersCompanion.insert(
                id: id,
                nama: nama,
                noHp: noHp,
                alamat: alamat,
                catatan: catatan,
                isArchived: isArchived,
                authUserId: authUserId,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                isDirty: isDirty,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomersTable,
      CustomerRow,
      $$CustomersTableFilterComposer,
      $$CustomersTableOrderingComposer,
      $$CustomersTableAnnotationComposer,
      $$CustomersTableCreateCompanionBuilder,
      $$CustomersTableUpdateCompanionBuilder,
      (
        CustomerRow,
        BaseReferences<_$AppDatabase, $CustomersTable, CustomerRow>,
      ),
      CustomerRow,
      PrefetchHooks Function()
    >;
typedef $$PurchasesTableCreateCompanionBuilder =
    PurchasesCompanion Function({
      required String id,
      required String customerId,
      required String namaBarang,
      required int hargaJual,
      Value<int?> hargaBeli,
      required DateTime tanggalBeli,
      Value<String?> catatan,
      Value<String?> createdBy,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> isDirty,
      Value<int> rowid,
    });
typedef $$PurchasesTableUpdateCompanionBuilder =
    PurchasesCompanion Function({
      Value<String> id,
      Value<String> customerId,
      Value<String> namaBarang,
      Value<int> hargaJual,
      Value<int?> hargaBeli,
      Value<DateTime> tanggalBeli,
      Value<String?> catatan,
      Value<String?> createdBy,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> isDirty,
      Value<int> rowid,
    });

class $$PurchasesTableFilterComposer
    extends Composer<_$AppDatabase, $PurchasesTable> {
  $$PurchasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get namaBarang => $composableBuilder(
    column: $table.namaBarang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hargaJual => $composableBuilder(
    column: $table.hargaJual,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hargaBeli => $composableBuilder(
    column: $table.hargaBeli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get tanggalBeli => $composableBuilder(
    column: $table.tanggalBeli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catatan => $composableBuilder(
    column: $table.catatan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PurchasesTableOrderingComposer
    extends Composer<_$AppDatabase, $PurchasesTable> {
  $$PurchasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get namaBarang => $composableBuilder(
    column: $table.namaBarang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hargaJual => $composableBuilder(
    column: $table.hargaJual,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hargaBeli => $composableBuilder(
    column: $table.hargaBeli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get tanggalBeli => $composableBuilder(
    column: $table.tanggalBeli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catatan => $composableBuilder(
    column: $table.catatan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PurchasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PurchasesTable> {
  $$PurchasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get namaBarang => $composableBuilder(
    column: $table.namaBarang,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hargaJual =>
      $composableBuilder(column: $table.hargaJual, builder: (column) => column);

  GeneratedColumn<int> get hargaBeli =>
      $composableBuilder(column: $table.hargaBeli, builder: (column) => column);

  GeneratedColumn<DateTime> get tanggalBeli => $composableBuilder(
    column: $table.tanggalBeli,
    builder: (column) => column,
  );

  GeneratedColumn<String> get catatan =>
      $composableBuilder(column: $table.catatan, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);
}

class $$PurchasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PurchasesTable,
          PurchaseRow,
          $$PurchasesTableFilterComposer,
          $$PurchasesTableOrderingComposer,
          $$PurchasesTableAnnotationComposer,
          $$PurchasesTableCreateCompanionBuilder,
          $$PurchasesTableUpdateCompanionBuilder,
          (
            PurchaseRow,
            BaseReferences<_$AppDatabase, $PurchasesTable, PurchaseRow>,
          ),
          PurchaseRow,
          PrefetchHooks Function()
        > {
  $$PurchasesTableTableManager(_$AppDatabase db, $PurchasesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PurchasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PurchasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PurchasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<String> namaBarang = const Value.absent(),
                Value<int> hargaJual = const Value.absent(),
                Value<int?> hargaBeli = const Value.absent(),
                Value<DateTime> tanggalBeli = const Value.absent(),
                Value<String?> catatan = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PurchasesCompanion(
                id: id,
                customerId: customerId,
                namaBarang: namaBarang,
                hargaJual: hargaJual,
                hargaBeli: hargaBeli,
                tanggalBeli: tanggalBeli,
                catatan: catatan,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                isDirty: isDirty,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String customerId,
                required String namaBarang,
                required int hargaJual,
                Value<int?> hargaBeli = const Value.absent(),
                required DateTime tanggalBeli,
                Value<String?> catatan = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PurchasesCompanion.insert(
                id: id,
                customerId: customerId,
                namaBarang: namaBarang,
                hargaJual: hargaJual,
                hargaBeli: hargaBeli,
                tanggalBeli: tanggalBeli,
                catatan: catatan,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                isDirty: isDirty,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PurchasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PurchasesTable,
      PurchaseRow,
      $$PurchasesTableFilterComposer,
      $$PurchasesTableOrderingComposer,
      $$PurchasesTableAnnotationComposer,
      $$PurchasesTableCreateCompanionBuilder,
      $$PurchasesTableUpdateCompanionBuilder,
      (
        PurchaseRow,
        BaseReferences<_$AppDatabase, $PurchasesTable, PurchaseRow>,
      ),
      PurchaseRow,
      PrefetchHooks Function()
    >;
typedef $$PaymentsTableCreateCompanionBuilder =
    PaymentsCompanion Function({
      required String id,
      required String customerId,
      required int jumlah,
      required DateTime tanggalBayar,
      Value<String> metode,
      Value<String?> catatan,
      Value<String> sumber,
      Value<String> statusVerifikasi,
      Value<String?> buktiFotoUrl,
      Value<String?> createdBy,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> isDirty,
      Value<int> rowid,
    });
typedef $$PaymentsTableUpdateCompanionBuilder =
    PaymentsCompanion Function({
      Value<String> id,
      Value<String> customerId,
      Value<int> jumlah,
      Value<DateTime> tanggalBayar,
      Value<String> metode,
      Value<String?> catatan,
      Value<String> sumber,
      Value<String> statusVerifikasi,
      Value<String?> buktiFotoUrl,
      Value<String?> createdBy,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> isDirty,
      Value<int> rowid,
    });

class $$PaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get jumlah => $composableBuilder(
    column: $table.jumlah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get tanggalBayar => $composableBuilder(
    column: $table.tanggalBayar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metode => $composableBuilder(
    column: $table.metode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catatan => $composableBuilder(
    column: $table.catatan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sumber => $composableBuilder(
    column: $table.sumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statusVerifikasi => $composableBuilder(
    column: $table.statusVerifikasi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get buktiFotoUrl => $composableBuilder(
    column: $table.buktiFotoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get jumlah => $composableBuilder(
    column: $table.jumlah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get tanggalBayar => $composableBuilder(
    column: $table.tanggalBayar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metode => $composableBuilder(
    column: $table.metode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catatan => $composableBuilder(
    column: $table.catatan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sumber => $composableBuilder(
    column: $table.sumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statusVerifikasi => $composableBuilder(
    column: $table.statusVerifikasi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get buktiFotoUrl => $composableBuilder(
    column: $table.buktiFotoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get jumlah =>
      $composableBuilder(column: $table.jumlah, builder: (column) => column);

  GeneratedColumn<DateTime> get tanggalBayar => $composableBuilder(
    column: $table.tanggalBayar,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metode =>
      $composableBuilder(column: $table.metode, builder: (column) => column);

  GeneratedColumn<String> get catatan =>
      $composableBuilder(column: $table.catatan, builder: (column) => column);

  GeneratedColumn<String> get sumber =>
      $composableBuilder(column: $table.sumber, builder: (column) => column);

  GeneratedColumn<String> get statusVerifikasi => $composableBuilder(
    column: $table.statusVerifikasi,
    builder: (column) => column,
  );

  GeneratedColumn<String> get buktiFotoUrl => $composableBuilder(
    column: $table.buktiFotoUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);
}

class $$PaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaymentsTable,
          PaymentRow,
          $$PaymentsTableFilterComposer,
          $$PaymentsTableOrderingComposer,
          $$PaymentsTableAnnotationComposer,
          $$PaymentsTableCreateCompanionBuilder,
          $$PaymentsTableUpdateCompanionBuilder,
          (
            PaymentRow,
            BaseReferences<_$AppDatabase, $PaymentsTable, PaymentRow>,
          ),
          PaymentRow,
          PrefetchHooks Function()
        > {
  $$PaymentsTableTableManager(_$AppDatabase db, $PaymentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<int> jumlah = const Value.absent(),
                Value<DateTime> tanggalBayar = const Value.absent(),
                Value<String> metode = const Value.absent(),
                Value<String?> catatan = const Value.absent(),
                Value<String> sumber = const Value.absent(),
                Value<String> statusVerifikasi = const Value.absent(),
                Value<String?> buktiFotoUrl = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentsCompanion(
                id: id,
                customerId: customerId,
                jumlah: jumlah,
                tanggalBayar: tanggalBayar,
                metode: metode,
                catatan: catatan,
                sumber: sumber,
                statusVerifikasi: statusVerifikasi,
                buktiFotoUrl: buktiFotoUrl,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                isDirty: isDirty,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String customerId,
                required int jumlah,
                required DateTime tanggalBayar,
                Value<String> metode = const Value.absent(),
                Value<String?> catatan = const Value.absent(),
                Value<String> sumber = const Value.absent(),
                Value<String> statusVerifikasi = const Value.absent(),
                Value<String?> buktiFotoUrl = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentsCompanion.insert(
                id: id,
                customerId: customerId,
                jumlah: jumlah,
                tanggalBayar: tanggalBayar,
                metode: metode,
                catatan: catatan,
                sumber: sumber,
                statusVerifikasi: statusVerifikasi,
                buktiFotoUrl: buktiFotoUrl,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                isDirty: isDirty,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaymentsTable,
      PaymentRow,
      $$PaymentsTableFilterComposer,
      $$PaymentsTableOrderingComposer,
      $$PaymentsTableAnnotationComposer,
      $$PaymentsTableCreateCompanionBuilder,
      $$PaymentsTableUpdateCompanionBuilder,
      (PaymentRow, BaseReferences<_$AppDatabase, $PaymentsTable, PaymentRow>),
      PaymentRow,
      PrefetchHooks Function()
    >;
typedef $$BudgetEntriesTableCreateCompanionBuilder =
    BudgetEntriesCompanion Function({
      required String id,
      required DateTime tanggal,
      required String namaTransaksi,
      required String tipe,
      required int jumlah,
      Value<String?> catatan,
      Value<String?> createdBy,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> isDirty,
      Value<int> rowid,
    });
typedef $$BudgetEntriesTableUpdateCompanionBuilder =
    BudgetEntriesCompanion Function({
      Value<String> id,
      Value<DateTime> tanggal,
      Value<String> namaTransaksi,
      Value<String> tipe,
      Value<int> jumlah,
      Value<String?> catatan,
      Value<String?> createdBy,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> isDirty,
      Value<int> rowid,
    });

class $$BudgetEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetEntriesTable> {
  $$BudgetEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get tanggal => $composableBuilder(
    column: $table.tanggal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get namaTransaksi => $composableBuilder(
    column: $table.namaTransaksi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipe => $composableBuilder(
    column: $table.tipe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get jumlah => $composableBuilder(
    column: $table.jumlah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catatan => $composableBuilder(
    column: $table.catatan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BudgetEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetEntriesTable> {
  $$BudgetEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get tanggal => $composableBuilder(
    column: $table.tanggal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get namaTransaksi => $composableBuilder(
    column: $table.namaTransaksi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipe => $composableBuilder(
    column: $table.tipe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get jumlah => $composableBuilder(
    column: $table.jumlah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catatan => $composableBuilder(
    column: $table.catatan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BudgetEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetEntriesTable> {
  $$BudgetEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get tanggal =>
      $composableBuilder(column: $table.tanggal, builder: (column) => column);

  GeneratedColumn<String> get namaTransaksi => $composableBuilder(
    column: $table.namaTransaksi,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tipe =>
      $composableBuilder(column: $table.tipe, builder: (column) => column);

  GeneratedColumn<int> get jumlah =>
      $composableBuilder(column: $table.jumlah, builder: (column) => column);

  GeneratedColumn<String> get catatan =>
      $composableBuilder(column: $table.catatan, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);
}

class $$BudgetEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetEntriesTable,
          BudgetEntryRow,
          $$BudgetEntriesTableFilterComposer,
          $$BudgetEntriesTableOrderingComposer,
          $$BudgetEntriesTableAnnotationComposer,
          $$BudgetEntriesTableCreateCompanionBuilder,
          $$BudgetEntriesTableUpdateCompanionBuilder,
          (
            BudgetEntryRow,
            BaseReferences<_$AppDatabase, $BudgetEntriesTable, BudgetEntryRow>,
          ),
          BudgetEntryRow,
          PrefetchHooks Function()
        > {
  $$BudgetEntriesTableTableManager(_$AppDatabase db, $BudgetEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> tanggal = const Value.absent(),
                Value<String> namaTransaksi = const Value.absent(),
                Value<String> tipe = const Value.absent(),
                Value<int> jumlah = const Value.absent(),
                Value<String?> catatan = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetEntriesCompanion(
                id: id,
                tanggal: tanggal,
                namaTransaksi: namaTransaksi,
                tipe: tipe,
                jumlah: jumlah,
                catatan: catatan,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                isDirty: isDirty,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime tanggal,
                required String namaTransaksi,
                required String tipe,
                required int jumlah,
                Value<String?> catatan = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetEntriesCompanion.insert(
                id: id,
                tanggal: tanggal,
                namaTransaksi: namaTransaksi,
                tipe: tipe,
                jumlah: jumlah,
                catatan: catatan,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                isDirty: isDirty,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BudgetEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetEntriesTable,
      BudgetEntryRow,
      $$BudgetEntriesTableFilterComposer,
      $$BudgetEntriesTableOrderingComposer,
      $$BudgetEntriesTableAnnotationComposer,
      $$BudgetEntriesTableCreateCompanionBuilder,
      $$BudgetEntriesTableUpdateCompanionBuilder,
      (
        BudgetEntryRow,
        BaseReferences<_$AppDatabase, $BudgetEntriesTable, BudgetEntryRow>,
      ),
      BudgetEntryRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db, _db.customers);
  $$PurchasesTableTableManager get purchases =>
      $$PurchasesTableTableManager(_db, _db.purchases);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db, _db.payments);
  $$BudgetEntriesTableTableManager get budgetEntries =>
      $$BudgetEntriesTableTableManager(_db, _db.budgetEntries);
}
