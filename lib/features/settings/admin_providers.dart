import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import 'admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final store = ref.watch(remoteStoreProvider);
  return AdminRepository(store);
});

final adminListProvider = FutureProvider.autoDispose<List<AdminUser>>((ref) {
  return ref.watch(adminRepositoryProvider).listAdmins();
});
