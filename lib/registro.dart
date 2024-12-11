import 'package:aplicacion2/db_helper.dart';
import 'package:aplicacion2/validacion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class Registro extends StatefulWidget {
  const Registro({super.key});

  @override
  _RegistroState createState() => _RegistroState();
}

class _RegistroState extends State<Registro> {
  final _formKey = GlobalKey<FormBuilderState>();
  final TextEditingController _usuarioEditingController =
      TextEditingController();
  final TextEditingController _contEditingController = TextEditingController();
  final TextEditingController _confirmarContEditingController =
      TextEditingController();
  final TextEditingController _nombreEditingController =
      TextEditingController();
  final TextEditingController _correoEditingController =
      TextEditingController();
  bool _isPasswordVisible = false;

  final FormValidator _validator = FormValidator();

  bool _isUpperCase = false;
  bool _isLowerCase = false;
  bool _isSpecialCharacter = false;
  bool _isNumber = false;

  String?
      _confirmPasswordError; // Variable de error para la confirmación de contraseña

// Método para validar la confirmación de la contraseña
  void _validateConfirmPassword() {
    setState(() {
      if (_confirmarContEditingController.text != _contEditingController.text) {
        _confirmPasswordError = 'Las contraseñas no coinciden';
      } else {
        _confirmPasswordError =
            null; // No hay error si las contraseñas coinciden
      }
    });
  }

  void _validatePassword(String? password) {
    setState(() {
      _isUpperCase = password?.contains(RegExp(r'[A-Z]')) ?? false;
      _isLowerCase = password?.contains(RegExp(r'[a-z]')) ?? false;
      _isSpecialCharacter =
          password?.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')) ?? false;
      _isNumber = password?.contains(RegExp(r'[0-9]')) ?? false;
    });
  }

  Future<void> _addUser() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      await SQLHelper.createUser(
        _usuarioEditingController.text,
        _contEditingController.text,
        _nombreEditingController.text,
        _correoEditingController.text,
        2,
        null
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Usuario registrado con éxito"),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Por favor, completa el formulario correctamente"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Registro"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Campo de Usuario
              FormBuilderTextField(
                name: 'usuario',
                controller: _usuarioEditingController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Usuario",
                ),
                validator: (value) => _validator.validateUsername(value ?? ''),
              ),
              SizedBox(height: 10),

              // Campo de Contraseña
              FormBuilderTextField(
                name: 'contrasena',
                controller: _contEditingController,
                obscureText: !_isPasswordVisible,
                onChanged: (value) {
                  setState(() {
                    _validatePassword(value);
                    _validateConfirmPassword();
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Contraseña',
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
                ),
                validator: (value) => _validator.validatePassword(value ?? ''),
              ),
              SizedBox(height: 10),
              FormBuilderTextField(
                name: 'confirmar_contrasena',
                controller: _confirmarContEditingController,
                obscureText: !_isPasswordVisible,
                onChanged: (value) {
                  setState(() {
                    _validateConfirmPassword(); // Validar si la confirmación coincide en tiempo real
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Confirmar Contraseña',
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
                  errorText:
                      _confirmPasswordError, // Mostramos el error de confirmación aquí
                ),
                validator: (value) {
                  return _confirmPasswordError; // Devuelve el error si las contraseñas no coinciden
                },
              ),
              Text(
                "La contraseña debe contener:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    _isUpperCase ? Icons.check : Icons.close,
                    color: _isUpperCase ? Colors.green : Colors.red,
                  ),
                  SizedBox(width: 10),
                  Text("Una letra mayúscula"),
                ],
              ),
              Row(
                children: [
                  Icon(
                    _isLowerCase ? Icons.check : Icons.close,
                    color: _isLowerCase ? Colors.green : Colors.red,
                  ),
                  SizedBox(width: 10),
                  Text("Una letra minúscula"),
                ],
              ),
              Row(
                children: [
                  Icon(
                    _isSpecialCharacter ? Icons.check : Icons.close,
                    color: _isSpecialCharacter ? Colors.green : Colors.red,
                  ),
                  SizedBox(width: 10),
                  Text("Un carácter especial"),
                ],
              ),
              Row(
                children: [
                  Icon(
                    _isNumber ? Icons.check : Icons.close,
                    color: _isNumber ? Colors.green : Colors.red,
                  ),
                  SizedBox(width: 10),
                  Text("Un número"),
                ],
              ),
              SizedBox(height: 10),

              // Campo de Nombres
              FormBuilderTextField(
                name: 'nombres',
                controller: _nombreEditingController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Nombres",
                ),
                validator: (value) => _validator.validateFullName(value ?? ''),
              ),
              SizedBox(height: 10),

              // Campo de Correo
              FormBuilderTextField(
                name: 'correo',
                controller: _correoEditingController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Correo",
                ),
                validator: (value) => _validator.validateEmail(value ?? ''),
              ),
              SizedBox(height: 20),

              // Botón de Registro
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await _addUser();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      "Registrar Usuario",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
