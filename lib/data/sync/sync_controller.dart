// Facade: pilih implementasi sesuai platform saat compile.
export 'sync_ui_state.dart';
export 'sync_controller_native.dart'
    if (dart.library.html) 'sync_controller_web.dart';
