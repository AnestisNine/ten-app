// The app is web-only; the stub only exists so unit tests can compile on the Dart VM.
export 'http_factory_stub.dart' if (dart.library.js_interop) 'http_factory_web.dart';
