import 'package:local_auth/local_auth.dart';
import 'package:smart_home/utils/session_utils.dart';

class BiometricUtils {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Solicita autenticação biométrica (digital, rosto, etc.)
  static Future<bool> authenticate(String type, {String reason = "Autentique-se"}) async {
    try {
      final biometricPreferences = await SessionUtils.getBiometricPreferences();
      if (type == 'login') {
        if (!biometricPreferences['biometric_login']!) {
          return true;
        }
      } else if (type == 'edit_device') {
        if (!biometricPreferences['biometric_edit']!) {
          return true;
        }
      } else if (type == 'remove_device') {
        if (!biometricPreferences['biometric_remove']!) {
          return true;
        }
      }

      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();

      if (!canCheck || !isSupported) {
        print("Biometria não disponível");
        return false;
      }

      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      return didAuthenticate;
    } catch (e) {
      print("Erro ao autenticar: $e");
      return false;
    }
  }
}
