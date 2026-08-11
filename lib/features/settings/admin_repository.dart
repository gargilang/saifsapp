import '../../data/remote/remote_store.dart';

class AdminUser {
  final String id;
  final String email;
  final String displayName;
  final DateTime createdAt;

  const AdminUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
        id: j['id'] as String,
        email: j['email'] as String,
        displayName: j['display_name'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class AdminRepository {
  final RemoteStore _store;
  AdminRepository(this._store);

  Future<List<AdminUser>> listAdmins() async {
    final data = await _store.callFunction('admin-users', method: 'GET');
    final list = data['admins'] as List<dynamic>;
    return list
        .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createAdmin({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await _store.callFunction(
      'admin-users',
      body: {
        'email': email.trim(),
        'password': password,
        'display_name': displayName.trim(),
      },
    );
  }

  Future<void> deleteAdmin(String userId) async {
    await _store.callFunction(
      'admin-users',
      method: 'DELETE',
      body: {'user_id': userId},
    );
  }
}
