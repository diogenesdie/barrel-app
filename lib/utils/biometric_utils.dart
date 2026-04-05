// =============================================================================
// biometric_utils.dart
//
// Autenticação biométrica (digital, rosto) para ações sensíveis.
// As preferências por tipo são lidas de [SessionUtils.getBiometricPreferences].
//
// Tipos suportados:
//   'login'         — exigido ao abrir o app
//   'edit_device'   — exigido ao salvar edições de dispositivo
//   'remove_device' — exigido ao remover um dispositivo
//
// Se a preferência estiver desabilitada para o tipo, retorna true imediatamente
// (autenticação pulada).
// =============================================================================

// Terceiros
import 'package:local_auth/local_auth.dart';

// Projeto — utils
import 'package:smart_home/utils/session_utils.dart';

/// Wrapper de autenticação biométrica do aplicativo.
class BiometricUtils {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Solicita autenticação biométrica para o [type] especificado.
  ///
  /// Retorna true se autenticado com sucesso ou se a biometria está desabilitada
  /// para o [type]. Retorna false se o dispositivo não suporta biometria ou se
  /// o usuário cancelou.
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
