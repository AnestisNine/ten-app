import 'package:http/http.dart' as http;

http.Client createHttpClient() => http.Client();

/// Native apps keep the session cookie themselves (in the Keychain, see CookieStore).
const bool manualCookies = true;
