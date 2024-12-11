import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:base32/base32.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TotpService {
  static const _key = 'secretKey'; // Clave para SharedPreferences

  // Método para obtener la clave secreta almacenada o generarla si no existe
  static Future<String> getSecretKey() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? secretKey = '';
    print(secretKey);
    // Si no existe la clave secreta, generamos una nuev
    secretKey = _generateSecretKey();
    await prefs.setString(_key, secretKey);
    return secretKey;
  }

  // Función para generar una nueva clave secreta base32
  static String _generateSecretKey() {
    final randomBytes = List.generate(20, (i) => (i + 5) * 8);
    final secretKey =
        base32.encode(Uint8List.fromList(randomBytes)).replaceAll('=', '');
    return secretKey;
  }

  // Función para generar el código TOTP
  static String generateTotp(String secretKey) {
    final key = base32.decode(secretKey.toUpperCase());

    final time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final timeStep = 30; // Intervalo de 30 segundos
    final timeCounter = (time / timeStep).floor();

    final timeBytes = ByteData(8)..setUint64(0, timeCounter);

    final hmac = Hmac(sha1, Uint8List.fromList(key)); // Usamos SHA-1 para HMAC
    final hash = hmac.convert(timeBytes.buffer.asUint8List());

    final offset = hash.bytes[19] & 0xf;

    int code = ((hash.bytes[offset] & 0x7f) << 24) |
        ((hash.bytes[offset + 1] & 0xff) << 16) |
        ((hash.bytes[offset + 2] & 0xff) << 8) |
        (hash.bytes[offset + 3] & 0xff);

    code = code % 1000000; // Limitar a 6 dígitos

    return code.toString().padLeft(6, '0');
  }

  // Generar la URL para escanear el código QR (opcional)
  static Future<String> generateOtpAuthUrl(
      String secretKey, String label, String issuer) async {
    final encodedLabel = Uri.encodeComponent(label);
    final encodedIssuer = Uri.encodeComponent(issuer);

    return 'otpauth://totp/$encodedLabel?secret=$secretKey&issuer=$encodedIssuer&algorithm=SHA1&digits=6&period=30';
  }
}
