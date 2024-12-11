import 'package:aplicacion2/MailHelper.dart';
import 'package:aplicacion2/db_helper.dart';
import 'package:aplicacion2/services/gmail_service.dart';
import 'package:aplicacion2/services/network_service.dart';
import 'package:aplicacion2/validacion.dart';
import 'package:aplicacion2/widgets/mostrar_mesajes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:otp/otp.dart';

class CambioContrasena extends StatefulWidget {
  const CambioContrasena({super.key});

  @override
  _CambioContrasenaState createState() => _CambioContrasenaState();
}

class _CambioContrasenaState extends State<CambioContrasena> {
  final _formKey = GlobalKey<FormBuilderState>();
  final TextEditingController _correoEditingController =
      TextEditingController();
  final TextEditingController _nuevaContEditingController =
      TextEditingController();
  final TextEditingController _confirmarContEditingController =
      TextEditingController();
  final TextEditingController _nuevaSecretKeyEditingController =
      TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final FormValidator _validator = FormValidator();

  bool _isUpperCase = false;
  bool _isLowerCase = false;
  bool _isSpecialCharacter = false;
  bool _isNumber = false;

  // ignore: unused_field
  bool _isPasswordMatch =
      true; // Para validar si las contraseñas coinciden en tiempo real

  bool _isSecretKeyEnabled =
      false; // Controla la habilitación del campo Secret Key
  bool _isPasswordEnabled =
      false; // Controla la habilitación de los campos de contraseña
  bool _isEmailValidated = false; // Controla si el correo ha sido validado
  bool _isSecretKeyValidated =
      false; // Controla si el secret key ha sido validado

  int? _idUsu; // Guardar el id del usuario para evitar validaciones repetidas
  String? _generatedSecretKey; // Almacenar la clave secreta generada

  // Método para validar la contraseña en tiempo real
  void _validatePassword(String? password) {
    setState(() {
      _isUpperCase = password?.contains(RegExp(r'[A-Z]')) ?? false;
      _isLowerCase = password?.contains(RegExp(r'[a-z]')) ?? false;
      _isSpecialCharacter =
          password?.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')) ?? false;
      _isNumber = password?.contains(RegExp(r'[0-9]')) ?? false;
      _isPasswordMatch = _nuevaContEditingController.text ==
          _confirmarContEditingController.text;
    });
  }

  // Función para validar el correo
  Future<void> _validateEmail(String correo) async {
    if (await NetworkService.isConnectedToInternet()) {
      if (_formKey.currentState?.saveAndValidate() ?? false) {
        // Buscamos el correo en la base de datos
        _idUsu = await SQLHelper.foundEmail(correo);
        if (_idUsu != null) {
          setState(() {
            _isSecretKeyEnabled = true; // Habilitamos el campo de Secret Key
            _isEmailValidated = true; // Marcamos que el correo fue validado
          });

          // Generamos una nueva secret key solo una vez
          _generatedSecretKey = OTP.randomSecret();
          EmailService.recuperarPass(correo, _generatedSecretKey!);

          Mensajes().showSuccessDialog(
              context, 'Correo encontrado, ingresa el Secret Key');
        } else {
          Mensajes().showErrorDialog(context, 'Correo no encontrado');
        }
      }
    } else {
      Mensajes().showErrorDialog(context, 'Conectate a una red!!!');
    }
  }

  // Función para validar el Secret Key
  Future<void> _validateSecretKey() async {
    if (_nuevaSecretKeyEditingController.text == _generatedSecretKey) {
      setState(() {
        _isPasswordEnabled = true; // Habilitamos los campos de contraseña
        _isSecretKeyValidated = true; // Marcamos que el Secret Key fue validado
      });
      Mensajes().showSuccessDialog(
          context, 'Secret Key válido, ingresa la nueva contraseña');
    } else {
      Mensajes().showErrorDialog(context, 'Secret Key inválido');
    }
  }

  // Función para cambiar la contraseña
  Future<void> _changePassword() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      // Validaciones adicionales antes de cambiar la contraseña
      if (!_isUpperCase ||
          !_isLowerCase ||
          !_isSpecialCharacter ||
          !_isNumber) {
        Mensajes().showErrorDialog(
            context, 'La contraseña no cumple con los requisitos');
        return;
      }

      // Actualizamos la contraseña en la base de datos
      if (_idUsu != null) {
        SQLHelper.updatePass(_idUsu!, _nuevaContEditingController.text);
        MailHelper.sendPassword(
            _correoEditingController.text, _nuevaContEditingController.text);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text("Contraseña cambiada con éxito"),
          ),
        );
        Navigator.of(context).pop();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
        title: Text("Cambio de Contraseña"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              SizedBox(height: 10),

              // Mostrar el botón de validar correo si no está validado
              if (!_isEmailValidated)
                ElevatedButton(
                  onPressed: () =>
                      _validateEmail(_correoEditingController.text),
                  child: Text("Validar Correo"),
                ),
              SizedBox(height: 10),

              // Mostrar el campo Secret Key solo después de validar el correo
              if (_isSecretKeyEnabled)
                FormBuilderTextField(
                  name: 'secretkey',
                  controller: _nuevaSecretKeyEditingController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Secret Key",
                  ),
                  validator: (value) => _validator.validaKey(value ?? ''),
                ),
              SizedBox(height: 10),

              // Mostrar el botón de validar Secret Key si no está validado
              if (!_isSecretKeyValidated && _isSecretKeyEnabled)
                ElevatedButton(
                  onPressed: _validateSecretKey,
                  child: Text("Validar Secret Key"),
                ),
              SizedBox(height: 10),

              // Mostrar los campos de contraseña solo después de validar el Secret Key
              if (_isPasswordEnabled)
                Column(
                  children: [
                    FormBuilderTextField(
                      name: 'nueva_contrasena',
                      controller: _nuevaContEditingController,
                      obscureText: !_isPasswordVisible,
                      onChanged: (value) {
                        _validatePassword(_nuevaContEditingController.text);
                      },
                      decoration: InputDecoration(
                        labelText: 'Nueva Contraseña',
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
                      validator: (value) =>
                          _validator.validatePassword(value ?? ''),
                    ),
                    SizedBox(height: 10),

                    // Campo de Confirmar Contraseña
                    FormBuilderTextField(
                      name: 'confirmar_contrasena',
                      controller: _confirmarContEditingController,
                      obscureText: !_isConfirmPasswordVisible,
                      onChanged: (value) {
                        _validatePassword(_confirmarContEditingController.text);
                      },
                      decoration: InputDecoration(
                        labelText: 'Confirmar Contraseña',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value != _nuevaContEditingController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                  ],
                ),

              // Botón para cambiar la contraseña
              if (_isPasswordEnabled)
                ElevatedButton(
                  onPressed: _changePassword,
                  child: Text("Cambiar Contraseña"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
