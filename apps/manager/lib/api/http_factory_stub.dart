import 'package:http/http.dart' as http;

/// Not used by the app (web-only); lets tests run on the Dart VM.
http.Client createHttpClient() => http.Client();
