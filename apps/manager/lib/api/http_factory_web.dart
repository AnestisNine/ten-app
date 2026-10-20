import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

/// The session lives in an httpOnly cookie that only the browser can see.
/// `withCredentials` lets that cookie flow when the API is on another origin (development).
http.Client createHttpClient() => BrowserClient()..withCredentials = true;
