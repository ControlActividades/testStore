// ignore_for_file: unused_field, unused_local_variable

import 'dart:convert';
import 'package:aplicacion2/enviar_correo.dart';
import 'package:aplicacion2/home_screen.dart';
import 'package:aplicacion2/provider/theme_provider.dart';
import 'package:aplicacion2/services/fingerprint_auth_service%20.dart';
import 'package:aplicacion2/widgets/login_screen.dart';
import 'package:aplicacion2/widgets/mostrar_mesajes.dart';
import 'package:flutter/material.dart';
import 'package:aplicacion2/db_helper.dart';
import 'package:aplicacion2/validacion.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:aplicacion2/registro.dart';
import 'package:aplicacion2/recupera_pass.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  bool _isPasswordVisible = false;

  final FormValidator _validate = FormValidator();

  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasSpecialCharacter = false;
  bool _hasNumber = false;

  String? _passwordError;
  String? _usernameError;

  void _validatePassword(String password) {
    setState(() {
      _hasUpperCase = password.contains(RegExp(r'[A-Z]'));
      _hasLowerCase = password.contains(RegExp(r'[a-z]'));
      _hasSpecialCharacter =
          password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));

      _passwordError = _validate.validatePassword(password);
    });
  }

  void _validateUsername(String username) {
    setState(() {
      _usernameError = _validate.validateUsername(username);
    });
  }

  // Función de login
  void _login() async {
  // Mostrar la pantalla de carga mientras todo el proceso de login se realiza
  showDialog(
    context: context,
    barrierDismissible: false, // No permitir que el diálogo se cierre tocando fuera de él
    builder: (BuildContext context) {
      return AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text("Verificando credenciales..."),
          ],
        ),
      );
    },
  );

  // Validación de los campos de texto
  if (_usuarioController.text.isEmpty || _contrasenaController.text.isEmpty) {
    Navigator.pop(context); // Cerrar la pantalla de carga
    Mensajes().showErrorDialog(context,"Por favor, llena todos los campos");
    return;
  }

  // Validación de errores de los campos (username y password)
  if (_usernameError != null || _passwordError != null) {
    Navigator.pop(context); // Cerrar pantalla de carga
    Mensajes().showErrorDialog(context,"Por favor, corrige los errores antes de continuar");
    return;
  }

  try {
    // Intentar el login
    int? rol = await SQLHelper.loginUser(
      _usuarioController.text,
      _contrasenaController.text,
    );

    // Obtener los datos del usuario (si las credenciales son correctas)
    List<Map<String, dynamic>> usuarioIniciados =
        await SQLHelper.getSingleUser(
      _usuarioController.text,
      _contrasenaController.text,
    );

    if (usuarioIniciados.isNotEmpty) {
      Map<String, dynamic> usuarioIniciado = usuarioIniciados.first;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('email_user', usuarioIniciado['correo'] as String);
      await prefs.setInt('rol_user', usuarioIniciado['rol']);
      await prefs.setInt('idUsu', usuarioIniciado['id']);
      final correo = prefs.getString('email_user');
      await SQLHelper.updateSecretKey(correo!, usuarioIniciado['id']);

      Navigator.pop(context); // Cerrar el diálogo de carga

      // Verifica si el widget está montado antes de hacer cualquier navegación
      if (mounted) {
        // Comprobar si el usuario tiene un token de huella digital
        if (usuarioIniciado['huella_digital_token'] != null &&
            usuarioIniciado['huella_digital_token'].isNotEmpty) {
          // Si tiene token de huella, redirigir a la pantalla de autenticación con huella
          _showVerificationChoiceDialog(usuarioIniciado['id']);
        } else {
          // Si no tiene token de huella digital, redirigir al login con OTP
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LoginTokenScreen()),
          );
        }
      }
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.getInt('validaLogin') == 1) {
        Navigator.pop(context); // Cerrar la pantalla de carga
        Mensajes().showErrorDialog(context, 'Usuario no registrado');
      } else if (prefs.getInt('validaLogin') == 2) {
        Navigator.pop(context); // Cerrar la pantalla de carga
        Mensajes().showErrorDialog(context,'Contraseña incorrecta');
      }
    }
  } catch (e) {
    Navigator.pop(context); // Cerrar la pantalla de carga en caso de error
    Mensajes().showErrorDialog(context,"Error al verificar las credenciales.");
  }
}


  void _showVerificationChoiceDialog(int userId) {
    // Verificamos si el widget sigue montado antes de ejecutar cualquier acción con el context.
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Verificación de identidad"),
          content: Text("¿Cómo deseas verificar tu identidad?"),
          actions: [
            TextButton(
              onPressed: () async {
                if (!mounted)
                  return; // Verificar si sigue montado antes de continuar

                

                // Intentar autenticar con huella digital
                bool isAuthenticated = await FingerprintAuthService()
                    .authenticateWithFingerprint(userId.toString());

                if (isAuthenticated) {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                      Navigator.pop(context); // Cerrar el diálogo
                  if (prefs.getInt('rol_user') == 1 ||
                      prefs.getInt('rol_user') == 3) {
                    // Verificamos si el widget está montado antes de navegar
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => HomeScreen()),
                      );
                    }
                  } else if (prefs.getInt('rol_user') == 2) {
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProductUsuario()),
                      );
                    }
                  }
                } else {
                  if (mounted) {
                    Mensajes().showErrorDialog(context,
                        "No se pudo autenticar con huella digital.");
                  }
                }
              },
              child: Text("Con Huella Digital"),
            ),
            TextButton(
              onPressed: () {
                if (!mounted)
                  return; // Verificar si sigue montado antes de continuar
                Navigator.pop(context); // Cerrar el diálogo
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginTokenScreen())
                  );
                }
              },
              child: Text("Con OTP"),
            ),
          ],
        );
      },
    );
  }
  // Función de navegación al registro
  void _navigateToRegistro() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Registro()),
    );
  }

  void _navigateToRecuperarPass() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CambioContrasena()),
    );
  }

  String _generateHash(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
    Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Test Store"),
        actions: [
          IconButton(
            icon: Icon(
                themeProvider.isDarkMode ? Icons.wb_sunny : Icons.nights_stay),
            onPressed: () {
              themeProvider.toggleTheme(); // Cambiar el tema al presionar el icono
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: EdgeInsets.symmetric(horizontal: 30),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipOval(
                    child: Image.asset(
                      'lib/assets/pexels-rickyrecap-1607855.jpg',
                      height: 150,
                      width: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _usuarioController,
                    onChanged: _validateUsername,
                    decoration: InputDecoration(
                      labelText: "Usuario",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                      errorText: _usernameError,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _contrasenaController,
                    obscureText: !_isPasswordVisible,
                    onChanged: _validatePassword,
                    decoration: InputDecoration(
                      labelText: "Contraseña",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      errorText: _passwordError,
                    ),
                  ),
                  // Muestra la alerta de validación de la contraseña debajo del campo
                  if (_passwordError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _passwordError!,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 50,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Iniciar Sesión",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: _navigateToRegistro,
                    child: Text(
                      "Crear un registro",
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: _navigateToRecuperarPass,
                    child: Text(
                      "Recuperar contraseña",
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

