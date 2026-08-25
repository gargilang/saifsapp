// Platform web — stub, tidak pernah dipakai (backendProvider pakai RemoteBackend).
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/backend.dart';

// Dummy agar Provider tetap ada tapi tidak dipakai di web.
class WebDatabaseStub {}

final appDatabaseProvider = Provider<WebDatabaseStub>((_) => WebDatabaseStub());

Backend buildLocalBackend(WebDatabaseStub db) =>
    throw UnsupportedError('Local backend tidak tersedia di web');
