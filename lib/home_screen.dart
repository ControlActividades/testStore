// ignore_for_file: unused_field

import 'dart:async';
import 'package:aplicacion2/db_helper.dart';
import 'package:aplicacion2/login_screen.dart';
import 'package:aplicacion2/paypal_pagos.dart';
import 'package:aplicacion2/productos.dart';
import 'package:aplicacion2/services/gmail_service.dart';
import 'package:aplicacion2/services/network_service.dart';
import 'package:aplicacion2/validacion.dart';
import 'package:aplicacion2/widgets/map_screen.dart';
import 'package:aplicacion2/widgets/mostrar_mesajes.dart';
import 'package:aplicacion2/widgets/register_fingerprint_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _allUser = [];
  bool _isLoading = true;
  Timer? _inactividadTimer;
  int? _selectedRol;
  final _formKey = GlobalKey<FormState>();

  final FocusNode _usuarioFocusNode = FocusNode();
  final FocusNode _contFocusNode = FocusNode();
  final FocusNode _nombreFocusNode = FocusNode();
  final FocusNode _correoFocusNode = FocusNode();

  final TextEditingController _usuarioEditingController =
      TextEditingController();
  final TextEditingController _contEditingController = TextEditingController();
  final TextEditingController _nombreEditingController =
      TextEditingController();
  final TextEditingController _correoEditingController =
      TextEditingController();

  final FormValidator _validator = FormValidator();

  bool _isPasswordVisible = false;
  bool _isUpperCase = false;
  bool _isLowerCase = false;
  bool _isSpecialCharacter = false;
  bool _isNumber = false;

  // Lista de roles para el menú desplegable
  final List<DropdownMenuItem<int>> _rolOption = [
    DropdownMenuItem<int>(value: 1, child: Text("1")),
    DropdownMenuItem<int>(value: 2, child: Text("2")),
  ];

void _huella() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => RegisterFingerprintScreen()));
  }
  void _mapa() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => MapScreen()));
  }

  void _pagos() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => PaymentsPage()));
  }

  void _productos() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => Product()));
  }

  void _refreshUser() async {
    // Simulación de obtención de usuarios de la base de datos
    final user = await SQLHelper.getAllUser();
    setState(() {
      _allUser = user;
      _isLoading = false;
    });
  }

  void cerrarSesion() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  // Notificación de inactividad
  void _showInactividadNotification() {
    final snackBar = SnackBar(
      content: Text("Estás inactivo. Se cerrará sesión en 5 segundos."),
      duration: Duration(seconds: 5),
      action: SnackBarAction(
        label: 'Cerrar',
        onPressed: () {
          _inactividadTimer?.cancel();
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }


  @override
  void initState() {
    super.initState();
    _refreshUser();
  }

  @override
  void dispose() {
    _inactividadTimer?.cancel();
    _usuarioFocusNode.dispose();
    _contFocusNode.dispose();
    _nombreFocusNode.dispose();
    _correoFocusNode.dispose();
    super.dispose();
  }

  // Método para agregar un nuevo usuario
  void _addUser() {
    if (_formKey.currentState?.validate() ?? false) {
      SQLHelper.createUser(
        _usuarioEditingController.text,
        _contEditingController.text,
        _nombreEditingController.text,
        _correoEditingController.text,
        _selectedRol!,
        null
      );
      _usuarioEditingController.clear();
      _contEditingController.clear();
      _nombreEditingController.clear();
      _correoEditingController.clear();
      Navigator.of(context).pop();
      _refreshUser();
    }
  }

  // Método para actualizar un usuario
  void _updateUser(int id) async {
    if (await NetworkService.isConnectedToInternet()) {
      if (_formKey.currentState?.validate() ?? false) {
        SQLHelper.updateUser(
          id,
          _usuarioEditingController.text,
          _contEditingController.text,
          _nombreEditingController.text,
          _correoEditingController.text,
          _selectedRol!,
        );
        Navigator.of(context).pop();
        _refreshUser();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String correoUsu = prefs.getString('email_user') ?? '';

        EmailService.sendCambioDatos(
            correoUsu,
            _contEditingController.text,
            _usuarioEditingController.text,
            _nombreEditingController.text,
            _correoEditingController.text);
      } else {
        Mensajes().showErrorDialog(context, 'Conectate a una red!!!');
      }
    }
    _usuarioEditingController.clear();
    _contEditingController.clear();
    _nombreEditingController.clear();
    _correoEditingController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Cambios realizados!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Método para eliminar un usuario
  void _deleteUser(int id) async {
    await SQLHelper.deleteUser(id);
    _refreshUser();
  }

  // Función para validar la contraseña
  void _validatePassword(String password) {
    setState(() {
      _isUpperCase = password.contains(RegExp(r'[A-Z]'));
      _isLowerCase = password.contains(RegExp(r'[a-z]'));
      _isSpecialCharacter = password.contains(RegExp(r'[@$!%*?&]'));
      _isNumber = password.contains(RegExp(r'[0-9]'));
    });
  }

  // Mostrar datos en el formulario de registro/actualización
  void muestraDatos(int? id) {
    if (id != null) {
      final existingUser =
          _allUser.firstWhere((element) => element['id'] == id);
      _usuarioEditingController.text = existingUser['usuario'];
      _nombreEditingController.text = existingUser['nombre'];
      _correoEditingController.text = existingUser['correo'];
      _selectedRol = existingUser['rol'];
    } else {
      _usuarioEditingController.text = "";
      _contEditingController.text = "";
      _nombreEditingController.text = "";
      _correoEditingController.text = "";
      _selectedRol = null;
    }

    showModalBottomSheet(
      elevation: 5,
      isScrollControlled: true,
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              top: 30,
              left: 15,
              right: 15,
              bottom: MediaQuery.of(context).viewInsets.bottom + 50,
            ),
            child: Form(
              key: _formKey, // Agregamos el Form key
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextFormField(
                    controller: _usuarioEditingController,
                    focusNode: _usuarioFocusNode, // Asignamos el FocusNode
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Usuario",
                    ),
                    validator: (value) =>
                        _validator.validateUsername(value ?? ''),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _contEditingController,
                    focusNode: _contFocusNode, // Asignamos el FocusNode
                    obscureText: !_isPasswordVisible,
                    onChanged: _validatePassword,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Contraseña",
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setModalState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) =>
                        _validator.validatePassword(value ?? ''),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _nombreEditingController,
                    focusNode: _nombreFocusNode, // Asignamos el FocusNode
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Nombre Completo",
                    ),
                    validator: (value) =>
                        _validator.validateFullName(value ?? ''),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _correoEditingController,
                    focusNode: _correoFocusNode, // Asignamos el FocusNode
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Correo",
                    ),
                    validator: (value) => _validator.validateEmail(value ?? ''),
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: _selectedRol,
                    items: _rolOption,
                    onChanged: (value) {
                      setModalState(() {
                        _selectedRol = value;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Selecciona un rol",
                    ),
                    validator: (value) {
                      if (value == null) {
                        return 'Por favor selecciona un rol';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: id == null ? _addUser : () => _updateUser(id),
                    child: Text(id == null ? 'Registrar' : 'Actualizar'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: VisibilityDetector(
        key: Key('home-screen-key'),
        onVisibilityChanged: (info) {
          if (info.visibleFraction == 0) {
            _inactividadTimer?.cancel();
          } else {
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text('Bienvenido'),
            actions: [
              IconButton(
                icon: Icon(Icons.map),
                onPressed: _mapa,
              ),
              IconButton(
                icon: Icon(Icons.payment),
                onPressed: _pagos,
              ),
              IconButton(
                icon: Icon(Icons.shopping_cart),
                onPressed: _productos,
              ),
              IconButton(
                icon: Icon(Icons.fingerprint),
                onPressed: _huella,
              ),
              IconButton(
                icon: Icon(Icons.exit_to_app),
                onPressed: cerrarSesion,
              ),
            ],
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _allUser.length,
                  itemBuilder: (context, index) => Card(
                    margin: EdgeInsets.all(15),
                    child: ListTile(
                      title: Text(_allUser[index]['usuario']),
                      subtitle: Text(_allUser[index]['correo']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () =>
                                muestraDatos(_allUser[index]['id']),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteUser(_allUser[index]['id']),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () => muestraDatos(null),
          ),
        ),
      ),
    );
  }
}
