import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si los servicios de localización están habilitados
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Los servicios de localización están deshabilitados');
    }

    // Verificar permisos de ubicación
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permiso de localización denegado');
      }
    }

    // Obtener la ubicación actual
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
