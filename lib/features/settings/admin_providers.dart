import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_providers.dart';
import 'admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final store = ref.watch(remoteStoreProvider);
  return AdminRepository(store);
});

final adminListProvider = FutureProvider.autoDispose<List<AdminUser>>((ref) {
  return ref.watch(adminRepositoryProvider).listAdmins();
});

/// Display name profil admin yang sedang login.
final currentProfileProvider = FutureProvider.autoDispose<String>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return '';
  final data = await Supabase.instance.client
      .from('profiles')
      .select('display_name')
      .eq('id', uid)
      .single();
  return (data['display_name'] as String?) ?? '';
});
