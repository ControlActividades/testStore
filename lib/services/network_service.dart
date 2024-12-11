import 'package:http/http.dart' as http;

class NetworkService {
  static Future<bool> isConnectedToInternet() async {
    try {
      // Intentar hacer una solicitud GET simple a un servidor confiable (ejemplo: Google)
      final response = await http.get(Uri.parse('https://www.google.com'));
      if (response.statusCode == 200) {
        return true;  // Hay conexión a internet
      }
    } catch (e) {
      // Si la solicitud falla, probablemente no haya conexión
      return false;
    }

    return false;
  }
}
