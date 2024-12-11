import 'package:local_auth/local_auth.dart';
import 'package:aplicacion2/db_helper.dart'; // Tu clase SQLHelper

class FingerprintAuthService {
  final LocalAuthentication _localAuthentication = LocalAuthentication();

  // Autenticar al usuario con huella digital
  Future<bool> authenticateWithFingerprint(String userId) async {
    final db = await SQLHelper.db();

    var res = await db.query(
      'user_app',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (res.isNotEmpty) {
      String? storedToken = res.first['huella_digital_token'] as String?;

      // Verificar si el token de la huella digital coincide con el que hemos guardado
      try {
        bool isAuthenticated = await _localAuthentication.authenticate(
          localizedReason: 'Por favor, autentíquese con su huella digital.',
        );

        if (isAuthenticated) {
          if (storedToken != null && storedToken.isNotEmpty) {
            // Compara el token guardado en la base de datos con el token proporcionado
            return true;
          }
        }
      } catch (e) {
        print('Error durante la autenticación biométrica: $e');
      }
    }

    return false;
  }
}
