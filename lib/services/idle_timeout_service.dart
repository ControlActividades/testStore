import 'dart:async';
import 'package:flutter/material.dart';
import 'package:aplicacion2/login_screen.dart';

class IdleTimeoutService {
  final GlobalKey<NavigatorState> navigatorKey;
  Timer? _timer;
  static const _timeoutDuration = Duration(minutes: 5);

  IdleTimeoutService(this.navigatorKey);

  // Comienza el temporizador
  void startIdleTimer(BuildContext context) {
    _timer = Timer.periodic(_timeoutDuration, (timer) {
      _showLogoutDialog(context);
    });
  }

  // Reinicia el temporizador cuando el usuario interactúa
  void userInteracted() {
    _timer?.cancel();
    _timer = Timer.periodic(_timeoutDuration, (timer) {
      _showLogoutDialog(navigatorKey.currentContext!);
    });
  }

  // Muestra un cuadro de diálogo de confirmación antes de redirigir
  void _showLogoutDialog(BuildContext context) {
    if (Navigator.canPop(context)) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Inactividad detectada'),
            content: Text('¿Deseas continuar?'),
            actions: <Widget>[
              TextButton(
                child: Text('No'),
                onPressed: () {
                  _navigateToLogin(); // Llamar a la navegación
                  Navigator.of(context).pop(); // Cerrar el diálogo
                },
              ),
              TextButton(
                child: Text('Sí'),
                onPressed: () {
                  userInteracted(); // Reiniciar el temporizador
                  Navigator.of(context).pop(); // Cerrar el diálogo
                },
              ),
            ],
          );
        },
      );
    }
  }

  // Usamos _navigateToLogin para evitar errores de navegación
  void _navigateToLogin() {
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      // Depuración para verificar si se está llamando a la navegación
      print("Navegando a la pantalla de Login...");

      // Usamos `WidgetsBinding` para asegurarnos de que la navegación ocurra después del build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Reemplazar toda la pila de navegación para simular un "reinicio" de la aplicación
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,  // Eliminar todas las rutas previas
        );
      });
    } else {
      print("Navigator no está disponible");
    }
  }
}
