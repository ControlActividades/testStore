import 'package:flutter/material.dart';

class Mensajes {
  // Función para mostrar un Dialog de error
  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "¡Oops! Algo salió mal",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar el diálogo
            },
            child: Text(
              'Intentar de nuevo',
              style: TextStyle(color: Colors.blue, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // Función para mostrar un Dialog de éxito
  void showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "¡Genial! Todo salió perfecto",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar el diálogo
            },
            child: Text(
              '¡Entendido!',
              style: TextStyle(color: Colors.green, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
