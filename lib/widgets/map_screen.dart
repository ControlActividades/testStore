import 'dart:convert';
import 'package:aplicacion2/services/locate_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:aplicacion2/services/network_service.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late Position _currentPosition;
  bool _isLocationReady = false;
  bool _hasInternet = false;

  final LatLng _storeLocation = LatLng(21.47831, -101.21566);

  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
  }

  Future<void> _checkInternetConnection() async {
    bool hasInternet = await NetworkService.isConnectedToInternet();
    setState(() {
      _hasInternet = hasInternet;
    });

    if (_hasInternet) {
      _getLocation();
    }
  }

  Future<void> _getLocation() async {
    try {
      Position position = await LocationService().getCurrentLocation();
      setState(() {
        _currentPosition = position;
        _isLocationReady = true;
      });

      _getRoute(LatLng(position.latitude, position.longitude), _storeLocation);
    } catch (e) {
      setState(() {
        _isLocationReady = false;
      });
    }
  }

  Future<void> _getRoute(LatLng start, LatLng end) async {
    final url = 'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&alternatives=false&steps=true';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final encodedPolyline = data['routes'][0]['geometry'];
      PolylinePoints polylinePoints = PolylinePoints();
      List<PointLatLng> decodedPoints = polylinePoints.decodePolyline(encodedPolyline);

      setState(() {
        _routePoints = decodedPoints.map((point) => LatLng(point.latitude, point.longitude)).toList();
      });
    } else {
      throw Exception('Error al obtener la ruta');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ubicación en Tiempo Real'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: !_hasInternet
          ? _buildNoInternetWidget()
          : _isLocationReady
              ? _buildMapWidget()
              : _buildLoadingWidget(),
    );
  }

  Widget _buildNoInternetWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 50, color: Colors.red),
            SizedBox(height: 20),
            Card(
              color: Colors.white,
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No tienes conexión a internet.\nPor favor verifica tu conexión.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
        strokeWidth: 6.0,
      ),
    );
  }

  Widget _buildMapWidget() {
    return FlutterMap(
      options: MapOptions(
        center: LatLng(_currentPosition.latitude, _currentPosition.longitude),
        zoom: 14.0,
        maxZoom: 18.0,
        minZoom: 10.0,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: ['a', 'b', 'c'],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(_currentPosition.latitude, _currentPosition.longitude),
              builder: (ctx) => Icon(Icons.location_on, color: Colors.blue, size: 50),
            ),
            Marker(
              point: _storeLocation,
              builder: (ctx) => Icon(Icons.store, color: Colors.red, size: 50),
            ),
          ],
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: _routePoints,
              strokeWidth: 6.0,
              color: Color.fromARGB(186, 17, 15, 159),
            ),
          ],
        ),
      ],
    );
  }
}
