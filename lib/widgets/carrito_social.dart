import 'dart:math';
import 'package:aplicacion2/db_helper.dart';
import 'package:aplicacion2/global.dart';
import 'package:aplicacion2/services/gmail_service.dart';
import 'package:aplicacion2/services/network_service.dart';
import 'package:aplicacion2/services/paypal_services.dart';
import 'package:aplicacion2/widgets/mostrar_mesajes.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> _cart = []; // Lista del carrito
  final PayPalService _paypalService = PayPalService();
  bool isConnected = true; // Variable para manejar el estado de la conexión
  bool loading = true; // Para controlar la carga de productos

  @override
  void initState() {
    super.initState();
    _checkInternetConnection(); // Cargar productos desde la nueva API
  }


  // Verificar si hay conexión a internet
  Future<void> _checkInternetConnection() async {
    bool connected = await NetworkService.isConnectedToInternet();
    if (connected) {
      _fetchProducts(); // Si hay conexión, cargar productos
    } else {
      setState(() {
        isConnected = false; // Si no hay conexión, actualizar estado
        loading = false; // Detener el indicador de carga
      });
    }
  }

  // Generar una clave secreta de 8 caracteres
  String _generateSecretKey() {
    const length = 8;
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    String secretKey = String.fromCharCodes(
      Iterable.generate(
          length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
    return secretKey;
  }

  // Paso 1: Generar y enviar la clave secreta al correo del usuario
  Future<String> _generateAndSendSecretKey() async {
    // Mostrar la pantalla de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text("Enviando clave secreta..."),
            ],
          ),
        );
      },
    );

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String secretKey =
        _generateSecretKey(); // Generamos una clave secreta de 8 caracteres
    await prefs.setString('key', secretKey);

    // Enviar la clave secreta por correo
    String? correo = prefs.getString('email_user');
    if (await NetworkService.isConnectedToInternet()) {
      try {
        await EmailService.sendPayment(correo!, secretKey);

        // Cerrar el diálogo de carga
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Correo enviado.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        // Cerrar el diálogo de carga en caso de error
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Correo no enviado, revisa tu conexión a internet.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      Mensajes().showErrorDialog(context, 'Conéctate a una red!!!');
    }
    return secretKey;
  }

  // Paso 2: Mostrar un cuadro de diálogo para que el usuario ingrese la clave secreta recibida por correo
  Future<bool> _showSecretKeyDialog(String correctSecretKey) async {
    TextEditingController secretKeyController = TextEditingController();

    bool isValid = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Verificación de clave secreta'),
        content: TextField(
          controller: secretKeyController,
          decoration: InputDecoration(
            hintText: 'Ingresa la clave secreta recibida por correo',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              String enteredKey = secretKeyController.text.trim();
              if (enteredKey == correctSecretKey) {
                isValid = true;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Clave secreta correcta.'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Clave secreta incorrecta.'),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: Text('Verificar'),
          ),
        ],
      ),
    );

    return isValid;
  }

  // Cargar productos desde la API de Fake Store
   // Cargar productos desde la API de Fake Store
  Future<void> _fetchProducts() async {
    try {
      final response =
          await http.get(Uri.parse('https://fakestoreapi.com/products'));

      if (response.statusCode == 200) {
        List<dynamic> products = json.decode(response.body);

        setState(() {
          _cart = products.map((product) {
            // Procesar las imágenes directamente (las imágenes ya son URLs válidas)
            List<String> images = [];
            if (product['image'] != null) {
              images = [product['image']]; // Solo usar la primera imagen
            } else {
              // Si no hay imágenes disponibles, usar una imagen predeterminada
              images = [
                'https://th.bing.com/th/id/OIP.gi6o1056H5v9fHO-QYwZmAHaFj?rs=1&pid=ImgDetMain'
              ];
            }

            return {
              'id': product['id'],
              'nombre_product': product['title'],
              'precio': product['price'],
              'cart_quantity': 0,
              'images': images, // Usar la lista de imágenes procesadas
            };
          }).toList();
          loading = false; // Finalizamos el estado de carga
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      setState(() {
        loading = false; // Finalizamos el estado de carga
      });
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los productos: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _cart.fold(
        0.0, (sum, item) => sum + (item['precio'] * item['cart_quantity']));

    return Scaffold(
      appBar: AppBar(
        title: Text("Carrito de Compras"),
        backgroundColor: Colors.deepPurple, // Cambié el color de la barra
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Agregué margen para separar los bordes
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Si no hay conexión, mostrar el mensaje
            if (!isConnected && !loading)
              Center(
                child: Text(
                  'No hay conexión a internet. Por favor, conecta tu dispositivo.',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            // Si estamos cargando, mostrar un indicador de progreso
            if (loading)
              Center(
                child: CircularProgressIndicator(),
              ),
            // Mostrar productos en el carrito si hay conexión
            if (isConnected && !loading)
              Expanded(
                child: ListView.builder(
                  itemCount: _cart.length,
                  itemBuilder: (context, index) {
                    var item = _cart[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      elevation: 4, // Agregado para darle sombra
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item['images'][0],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          item['nombre_product'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text('Precio: \$${item['precio']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  if (item['cart_quantity'] > 1) {
                                    item['cart_quantity']--;
                                  }
                                });
                              },
                            ),
                            Text(
                              '${item['cart_quantity']}',
                              style: TextStyle(fontSize: 16),
                            ),
                            IconButton(
                              icon: Icon(Icons.add, color: Colors.green),
                              onPressed: () {
                                setState(() {
                                  item['cart_quantity']++;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            // Mostrar total
            if (isConnected && !loading)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "\$${total.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
            if (isConnected && !loading) SizedBox(height: 20), // Espaciado antes del botón
            // Botón de pago
            if (isConnected && !loading)
              ElevatedButton(
                onPressed: () async {
                  try {
                    if (await NetworkService.isConnectedToInternet()) {
                      String secretKey = await _generateAndSendSecretKey();
                      bool isValid = await _showSecretKeyDialog(secretKey);

                      if (!isValid) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('La clave secreta es incorrecta.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return; // Salir si la clave es incorrecta
                      }

                      final description = _cart
                          .map((item) =>
                              '${item['nombre_product']} x${item['cart_quantity']}')
                          .join(', ');

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            content: Row(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(width: 16),
                                Text("Procesando el pago..."),
                              ],
                            ),
                          );
                        },
                      );

                      bool paymentSuccessful =
                          await _paypalService.processPayment(
                        context,
                        total,
                        description,
                      );

                      Navigator.pop(context);

                      if (paymentSuccessful) {
                        print("Pago exitoso");

                        Map<String, dynamic> paymentDetails = getPaymentDetails();
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        // Extraemos solo el idPago y lo guardamos en la base de datos
                        String idPago =
                            paymentDetails['id'] ?? 'ID de pago no disponible';
                        String? idUsu = prefs.getInt('idUsu')?.toString();

                        if (idUsu != null) {
                          // Llamamos a la función para guardar solo el idCompra y idUsu en la base de datos
                          int compraId =
                              await SQLHelper.createCompra(idUsu, idPago);
                          print('Compra guardada con ID: $compraId');
                        }

                        if (await NetworkService.isConnectedToInternet()) {
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          String? correo = prefs.getString('email_user');
                          await EmailService.sendCart(correo!, paymentDetails);
                        } else {
                          Mensajes().showErrorDialog(context,
                              'Comprobante no enviado, conexión perdida');
                        }

                        Mensajes().showSuccessDialog(
                            context, 'Comprobante enviado al correo!!!');

                        setState(() {
                          _fetchProducts();
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Pago fallido.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } else {
                      Mensajes()
                          .showErrorDialog(context, 'Conéctate a una red!!!');
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ocurrió un error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 208, 154, 218), // color morado
                ),
                child: Text(
                  "Pagar",
                  style: TextStyle(fontSize: 18),
                  
                ),
              ),
          ],
        ),
      ),
    );
  }
}
