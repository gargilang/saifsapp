import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => Supabase.instance.client.auth
        .signInWithPassword(email: email.trim(), password: password));
  }

  Future<void> signOut() => Supabase.instance.client.auth.signOut();

  /// Ubah password diri sendiri.
  /// Re-auth dengan [oldPassword] terlebih dahulu untuk verifikasi.
  /// Throws [Exception] jika password lama salah atau update gagal.
  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email == null) throw Exception('Tidak ada sesi aktif');

    // Verifikasi password lama dengan re-auth
    await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: oldPassword,
    );

    // Update ke password baru
    final res = await Supabase.instance.client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
    if (res.user == null) {
      throw Exception('Gagal mengubah password');
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);
