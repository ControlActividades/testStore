import 'package:aplicacion2/enviar_correo.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aplicacion2/db_helper.dart'; // Tu clase SQLHelper
import 'package:aplicacion2/home_screen.dart'; // Ajusta según tus rutas
import 'package:aplicacion2/widgets/mostrar_mesajes.dart'; // Para mostrar mensajes de éxito y error

class RegisterFingerprintScreen extends StatefulWidget {
  @override
  _RegisterFingerprintScreenState createState() =>
      _RegisterFingerprintScreenState();
}

class _RegisterFingerprintScreenState extends State<RegisterFingerprintScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  bool _isAuthenticated = false;
  bool _hasFingerprintToken =
      false; // Para saber si ya tiene una huella registrada

  @override
  void initState() {
    super.initState();
    _checkBiometricsAvailability();
    _checkIfFingerprintRegistered();
  }

  // Verificar si el dispositivo tiene biometría disponible
  void _checkBiometricsAvailability() async {
    bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
    bool isDeviceSupported = await _localAuth.isDeviceSupported();

    setState(() {
      _canCheckBiometrics = canCheckBiometrics;
    });

    if (canCheckBiometrics && isDeviceSupported) {
      print("El dispositivo tiene biometría registrada.");
    } else {
      print("Este dispositivo no tiene huella digital registrada.");
      Mensajes().showErrorDialog(context, 'No cuenta con lector de huella');
    }
  }

  // Verificar si ya tiene un token de huella registrado en la base de datos
  // Verificar si ya tiene un token de huella registrado en la base de datos
  void _checkIfFingerprintRegistered() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt('idUsu') ?? 0;

    // Verificamos si hay un token de huella en la base de datos
    var db = await SQLHelper
        .db(); // Esperamos a obtener la base de datos correctamente
    var res = await db.query(
      'user_app',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (res.isNotEmpty && res.first['huella_digital_token'] != null) {
      setState(() {
        _hasFingerprintToken = true; // Ya tiene una huella registrada
      });
    }
  }

  // Intentar registrar o eliminar la huella digital
  Future<void> _registerOrDeleteFingerprint() async {
    if (_hasFingerprintToken) {
      // Si ya tiene huella, eliminarla
      await _deleteFingerprint();
    } else {
      // Si no tiene huella, registrar una nueva
      await _registerFingerprint();
    }
  }

  // Eliminar la huella digital registrada
  Future<void> _deleteFingerprint() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt('idUsu') ?? 0;

    // Borrar el token de la huella digital
    await SQLHelper.updateFingerprintToken(userId, '');
    setState(() {
      _hasFingerprintToken = false; // Después de eliminar, ya no hay huella
    });

    // Mostrar un mensaje de éxito
    Mensajes()
        .showSuccessDialog(context, 'Huella digital eliminada exitosamente');
  }

  // Intentar autenticar con la huella digital
  Future<void> _registerFingerprint() async {
    try {
      // Intentamos autenticar con la huella digital
      _isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Por favor, registre su huella digital.',
        options: AuthenticationOptions(biometricOnly: true),
      );

      if (_isAuthenticated) {
        // Si es exitoso, obtenemos el token
        String fingerprintToken =
            'token_ficticio_para_${DateTime.now().millisecondsSinceEpoch}';

        // Guardamos el token de huella en la base de datos
        SharedPreferences prefs = await SharedPreferences.getInstance();
        int userId = prefs.getInt('idUsu') ?? 0;
        await SQLHelper.updateFingerprintToken(userId, fingerprintToken);

        setState(() {
          _hasFingerprintToken =
              true; // Marca que ahora tiene una huella registrada
        });

        // Redirigir a la pantalla correspondiente según el rol
        if (prefs.getInt('rol_user') == 1 || prefs.getInt('rol_user') == 3) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
            (Route<dynamic> route) =>
                false, // Elimina todas las pantallas anteriores
          );
        } else if (prefs.getInt('rol_user') == 2) { 
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => ProductUsuario()),
            (Route<dynamic> route) =>
                false, // Elimina todas las pantallas anteriores
          );
        }

        Mensajes().showSuccessDialog(context, 'Registro de tu huella exitóso');
      } else {
        Mensajes().showErrorDialog(context, 'Registro de tu huella fallido');
      }
    } catch (e) {
      print("Error durante el registro biométrico: $e");
      Mensajes().showErrorDialog(
          context, 'Hubo un problema durante el registro de tu huella');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Registrar Huella Digital"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _canCheckBiometrics ? _registerOrDeleteFingerprint : null,
          child: Text(_hasFingerprintToken
              ? "Eliminar mi huella digital"
              : "Registrar mi huella digital"),
        ),
      ),
    );
  }
}
