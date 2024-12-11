import 'dart:async';
import 'package:aplicacion2/enviar_correo.dart';
import 'package:aplicacion2/services/gmail_service.dart';
import 'package:aplicacion2/services/network_service.dart';
import 'package:aplicacion2/widgets/mostrar_mesajes.dart';
import 'package:flutter/material.dart';
import 'package:aplicacion2/services/totp_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aplicacion2/home_screen.dart';
import 'package:aplicacion2/login_screen.dart';

class LoginTokenScreen extends StatefulWidget {
  @override
  _LoginTokenScreenState createState() => _LoginTokenScreenState();
}

class _LoginTokenScreenState extends State<LoginTokenScreen> {
  Mensajes avisos = Mensajes();
  String _secretKey = ''; // Stores the user's secret key
  int _remainingTime = 60; // Time remaining for manual OTP (60 seconds)
  String _manualOtpCode = ''; // Manual OTP code (60 seconds)
  late Timer _manualOtpTimer; // Timer for manual OTP
  final _otpController = TextEditingController(); // Controller for OTP input

  bool _isSendingEmail = false; // State to track email sending process
  bool _isEmailSent =
      false; // State to track if email has been sent successfully

  @override
  void initState() {
    super.initState();
    _loadSecretKey(); // Load the secret key stored
    _startManualOtpTimer(); // Start the timer for manual OTP
  }

  // Load the secret key, which should be unique for each user
  Future<void> _loadSecretKey() async {
    final secretKey = await TotpService.getSecretKey(); // Get the secret key
    setState(() {
      _secretKey = secretKey;
    });
    print('Secret key loaded: $_secretKey');
    _generateManualOtpCode(); // Generate the OTP manually
    _sendOtpToEmail(); // Send the OTP to the user's email
  }

  // Generate the OTP manually (every 60 seconds)
  void _generateManualOtpCode() {
    setState(() {
      _manualOtpCode = TotpService.generateTotp(_secretKey);
    });
    print('Generated OTP: $_manualOtpCode');
  }

  // Send the OTP to the user's email
  Future<void> _sendOtpToEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userEmail = prefs.getString('email_user');
    bool hasInternet = await NetworkService.isConnectedToInternet();

    print(hasInternet);

    if (userEmail != null && hasInternet) {
      if (mounted) {
        setState(() {
          _isSendingEmail = true;
        });
      }

      try {
        await EmailService.sendEmail(
            userEmail, _manualOtpCode); // Send OTP via email

        if (mounted) {
          setState(() {
            _isSendingEmail = false;
            _isEmailSent = true; // Email sent successfully
          });
        }

        if (mounted) {
          avisos.showSuccessDialog(context, 'Código OTP enviado');
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSendingEmail = false;
          });
          avisos.showErrorDialog(context, 'Error al enviar el correo');
        }
      }
    } else {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
        avisos.showErrorDialog(context, 'No cuentas con internet');
      }
    }
  }

  // Start the timer for manual OTP (60 seconds)
  void _startManualOtpTimer() {
    _manualOtpTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _manualOtpTimer.cancel(); // Stop the timer once it reaches 0
          _redirectToLogin(); // Redirect to login if time runs out
        }
      });
    });
    _generateManualOtpCode(); // Generate OTP when the timer starts
  }

  // Redirect to the login screen when the time is up
  Future<void> _redirectToLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('idUsu'); // Clear user info if necessary
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  // Validate the OTP entered by the user
  Future<void> _validateManualOtp() async {
    String userOtp = _otpController.text;
    if (userOtp == _manualOtpCode) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final role = prefs.getInt('rol_user');
      if (role == 1 || role == 3) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
          (Route<dynamic> route) => false,
        );
      } else if (role == 2) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ProductUsuario()),
          (Route<dynamic> route) => false,
        );
      }
      _showSuccessDialog('¡Bienvenido!');
    } else {
      avisos.showErrorDialog(context, 'Código TOTP incorrecto');
    }
  }

  // Function to show success dialog
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Éxito", style: TextStyle(color: Colors.green)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cerrar', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_manualOtpTimer.isActive) {
      _manualOtpTimer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verifica tu identidad'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple, // Attractive app bar color
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 100,
                color: Colors.deepPurple, // Large icon for attractiveness
              ),
              SizedBox(height: 20),
              Text(
                'Tiempo restante para ingresar la clave de tu correo electrónico: $_remainingTime s',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _otpController,
                decoration: InputDecoration(
                  labelText: "Ingresa tu código",
                  hintText: "Código OTP",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                  ),
                  prefixIcon: Icon(Icons.lock, color: Colors.deepPurple),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepPurple),
                  ),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _validateManualOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 154, 114, 222), // Button color
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Verificar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 20),
              if (_isSendingEmail) CircularProgressIndicator(),
              if (!_isSendingEmail && _isEmailSent)
                Text(
                  'Correo enviado correctamente',
                  style: TextStyle(color: Colors.green, fontSize: 16),
                ),
              if (!_isSendingEmail && !_isEmailSent)
                Text(
                  'Esperando envío de correo...',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
