// Platform web — stub, tidak pernah dipakai (backendProvider pakai RemoteBackend).
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/backend.dart';

// Dummy agar Provider tetap ada tapi tidak dipakai di web.
class _FakeDb {}

final appDatabaseProvider = Provider<_FakeDb>((_) => _FakeDb());

Backend buildLocalBackend(_FakeDb db) =>
    throw UnsupportedError('Local backend tidak tersedia di web');
