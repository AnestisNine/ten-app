import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class AppLockService {
  AppLockService._();

  static final LocalAuthentication _auth =
      LocalAuthentication();

  static Future<bool> authenticate() async {
    // Web: no biometrics. Access is protected by Cloudflare Access.
    if (kIsWeb) {
      return true;
    }

    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;

      if (!supported && !canCheck) {
        // Do not block development devices that have no
        // device authentication configured.
        return true;
      }

      return await _auth.authenticate(
        localizedReason:
            'Ξεκλείδωσε το TBN Manager για πρόσβαση '
            'σε οικονομικά και προσωπικά δεδομένα.',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
