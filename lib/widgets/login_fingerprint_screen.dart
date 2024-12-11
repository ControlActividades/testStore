import 'package:flutter/material.dart';

class LoginTokenScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verificación OTP")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Aquí va la lógica de la verificación OTP
          },
          child: Text("Verificar con OTP"),
        ),
      ),
    );
  }
}
