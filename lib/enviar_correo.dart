import 'dart:async';
import 'dart:math';
import 'package:aplicacion2/global.dart';
import 'package:aplicacion2/login_screen.dart';
import 'package:aplicacion2/services/gmail_service.dart';
import 'package:aplicacion2/services/network_service.dart';
import 'package:aplicacion2/services/paypal_services.dart';
import 'package:aplicacion2/widgets/carrito_social.dart';
import 'package:aplicacion2/widgets/map_screen.dart';
import 'package:aplicacion2/widgets/mostrar_mesajes.dart';
import 'package:aplicacion2/widgets/pagos_usu.dart';
import 'package:aplicacion2/widgets/register_fingerprint_screen.dart';
import 'package:flutter/material.dart';
import 'package:aplicacion2/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:aplicacion2/MailHelper.dart';

class ProductUsuario extends StatefulWidget {
  const ProductUsuario({super.key});

  @override
  State<ProductUsuario> createState() => _ProductState();
}

class _ProductState extends State<ProductUsuario> {
  List<Map<String, dynamic>> _allProduct = [];
  final List<Map<String, dynamic>> _cart = [];
  bool _isLoading = true;
  Timer? _inactividadTimer;
  final PayPalService _paypalService = PayPalService();

  // Custom Colors
  final Color primaryColor = Color.fromARGB(255, 160, 113, 227);
  final Color secondaryColor = Color(0xFF03DAC6);
  final Color backgroundColor = Color(0xFFF5F5F5);
  final Color cardColor = Colors.white;
  final Color textColor = Color(0xFF1D1D1D);

  // Custom TextStyles
  final TextStyle titleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1D1D1D),
  );

  final TextStyle priceStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Color(0xFF4CAF50),
  );

  final TextStyle stockStyle = TextStyle(
    fontSize: 14,
    color: Colors.grey[600],
    fontWeight: FontWeight.w500,
  );

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

  // Step 1: Generate and send the secret key to the user's email
  Future<String> _generateAndSendSecretKey() async {
    // Generate or fetch the secret key
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String secretKey =
        _generateSecretKey(); // Generamos una clave secreta de 8 caracteres
    await prefs.setString('key', secretKey);

    // Send the secret key via email (assuming _sendMail is already implemented)
    String? correo = prefs.getString('email_user');
    try {
      if (await NetworkService.isConnectedToInternet()) {
        await EmailService.sendPayment(correo!, secretKey);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Correo enviado.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        Mensajes()
            .showErrorDialog(context, 'Conectate a una red para continuar!!!');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Correo no enviado, revisa tu conexión a internet.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return secretKey; // Ya no es necesario un cast a Future<String>
  }

// Step 2: Show a dialog for the user to input the secret key received in email
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

  void _refreshProduct() async {
    final product = await SQLHelper.getAllProduct();
    setState(() {
      _allProduct = product;
      _isLoading = false;
    });
  }

  void _huella() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterFingerprintScreen()),
    );
  }

  void _moreTink() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CartScreen()),
    );
  }

  void _compras() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ComprasScreen()),
    );
  }

  void _map() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapScreen()),
    );
  }

  void cerrarSesion() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    _refreshProduct();
  }

  @override
  void dispose() {
    _inactividadTimer?.cancel();
    super.dispose();
  }

  void _showQuantityDialog(Map<String, dynamic> product) {
    int quantity = 1;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Seleccionar cantidad'),
        content: StatefulBuilder(
          builder: (context, setState) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.remove),
                onPressed: () {
                  if (quantity > 1) {
                    setState(() => quantity--);
                  }
                },
              ),
              Text(quantity.toString()),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  if (quantity < product['cantidad_producto']) {
                    setState(() => quantity++);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _addToCart({...product, 'cart_quantity': quantity});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Producto añadido al carrito')),
              );
            },
            child: Text('Añadir'),
          ),
        ],
      ),
    );
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      int existingIndex = _cart.indexWhere(
        (item) => item['id'] == product['id'],
      );

      if (existingIndex != -1) {
        int newQuantity =
            _cart[existingIndex]['cart_quantity'] + product['cart_quantity'];
        if (newQuantity <= product['cantidad_producto']) {
          _cart[existingIndex]['cart_quantity'] = newQuantity;
        }
      } else {
        _cart.add(product);
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  void _updateCartQuantity(
      int index, int newQuantity, StateSetter bottomSheetSetState) {
    if (newQuantity > 0 && newQuantity <= _cart[index]['cantidad_producto']) {
      setState(() {
        _cart[index]['cart_quantity'] = newQuantity;
      });
      bottomSheetSetState(() {});
    }
  }

  Future<void> _sendMail(List<Map<String, dynamic>> products,
      Map<String, dynamic>? paymentDetailsG) async {
    // Llamar al método sendCart pasando la lista completa de productos
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String correoUsuario = prefs.getString('email_user') ?? '';

    await MailHelper.sendCart(correoUsuario, products, paymentDetailsG);

    // Actualizar la cantidad de cada producto en la base de datos
    for (var product in products) {
      int newQuantity = product['cantidad_producto'] - product['cart_quantity'];
      await SQLHelper.updateProduct(
        product['id'],
        product['nombre_product'],
        product['precio'].toDouble(),
        newQuantity,
        product['imagen'],
      );
    }

    // Mostrar un mensaje de éxito
    Mensajes().showSuccessDialog(context, 'Pedido enviado correctamente');

    // Refrescar la lista de productos
    _refreshProduct();
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, bottomSheetSetState) => Column(
            children: [
              ListTile(
                title: Text('Carrito de Compras'),
                trailing: SizedBox(
                  width: 96,
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.send),
                        onPressed: () async {
                          if (await NetworkService.isConnectedToInternet()) {
                            // Muestra un indicador de carga
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return Center(
                                    child: CircularProgressIndicator());
                              },
                            );

                            // Procesa el envío de los correos
                            await _sendMail(_cart, null);

                            setState(() {
                              _cart.clear();
                            });

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ProductUsuario()),
                            );

                            // Muestra un mensaje de éxito
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Todos los pedidos fueron procesados correctamente'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            Mensajes().showErrorDialog(
                                context, 'Conectate a una red!!!');
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_sweep),
                        onPressed: () {
                          setState(() {
                            _cart.clear();
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Resto de la UI del carrito permanece igual
              Expanded(
                child: ListView.builder(
                  itemCount: _cart.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: _cart[index]['imagen'] != null &&
                                          _cart[index]['imagen'].isNotEmpty
                                      ? Image.network(
                                          _cart[index]['imagen'],
                                          fit: BoxFit.cover,
                                        )
                                      : Center(child: Text("No hay imagen")),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _cart[index]['nombre_product'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "\$${_cart[index]['precio'].toString()}",
                                        style: TextStyle(
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove_circle_outline),
                                  onPressed: () => _updateCartQuantity(
                                    index,
                                    _cart[index]['cart_quantity'] - 1,
                                    bottomSheetSetState,
                                  ),
                                ),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    _cart[index]['cart_quantity'].toString(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add_circle_outline),
                                  onPressed: () => _updateCartQuantity(
                                    index,
                                    _cart[index]['cart_quantity'] + 1,
                                    bottomSheetSetState,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _removeFromCart(index);
                                    });
                                    bottomSheetSetState(() {});
                                    if (_cart.isEmpty) {
                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Total: \$${_cart.fold(0.0, (sum, item) => sum + (item['precio'] * item['cart_quantity'])).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (await NetworkService.isConnectedToInternet()) {
                          try {
                            // Verificar si el carrito tiene productos
                            if (_cart.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Sin productos en el carrito.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return; // Salir si no hay productos en el carrito
                            }

                            // Paso 1: Generar y enviar la clave secreta al correo del usuario
                            // Mostrar la pantalla de carga mientras se genera y envía el correo
                            showDialog(
                              context: context,
                              barrierDismissible:
                                  false, // No cerrar el diálogo tocando fuera
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  content: Row(
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(width: 16),
                                      Text("Enviando el token..."),
                                    ],
                                  ),
                                );
                              },
                            );

                            String secretKey =
                                await _generateAndSendSecretKey();

                            // Cerrar la pantalla de carga después de que se complete el proceso
                            Navigator.pop(context);

                            // Paso 2: Solicitar al usuario que ingrese la clave secreta que recibió por correo
                            bool isOtpValid =
                                await _showSecretKeyDialog(secretKey);

                            if (!isOtpValid) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Verificación de clave secreta fallida.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return; // No continuar si la clave secreta es inválida
                            }

                            // Paso 3: Proceder con el pago después de la validación exitosa de la clave secreta
                            final total = _cart.fold(
                              0.0,
                              (sum, item) =>
                                  sum +
                                  (item['precio'] * item['cart_quantity']),
                            );

                            final description = _cart
                                .map((item) =>
                                    '${item['nombre_product']} x${item['cart_quantity']}')
                                .join(', ');

                            // Mostrar pantalla de carga mientras procesas el pago
                            showDialog(
                              context: context,
                              barrierDismissible:
                                  false, // No cerrar el diálogo tocando fuera
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

                            // Procesar el pago
                            bool paymentSuccessful =
                                await _paypalService.processPayment(
                              context,
                              total,
                              description,
                            );

                            // Cerrar la pantalla de carga después de que se complete el proceso
                            Navigator.pop(context);

                            if (paymentSuccessful) {
                              print("Pago exitoso");
                              await _sendMail(_cart,
                                  getPaymentDetails()); // Enviar correo de confirmación
                              setState(() {
                                _cart.clear();
                              });
                              Navigator.pop(context); // Cerrar la vista actual
                              Mensajes().showSuccessDialog(
                                  context, 'Comprobante enviado al correo');

                              // Obtener la respuesta de PayPal y extraer los datos
                              SharedPreferences prefs =
                                  await SharedPreferences.getInstance();
                              Map<String, dynamic> compra =
                                  getPaymentDetails(); // Aquí obtienes el mapa de PayPal
                              print(compra);

                              // Extraemos solo el idPago y lo guardamos en la base de datos
                              String idPago =
                                  compra['id'] ?? 'ID de pago no disponible';
                              String? idUsu = prefs.getInt('idUsu')?.toString();

                              if (idUsu != null) {
                                // Llamamos a la función para guardar solo el idCompra y idUsu en la base de datos
                                int compraId =
                                    await SQLHelper.createCompra(idUsu, idPago);
                                print('Compra guardada con ID: $compraId');
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Pago fallido.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            print('Error: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } else {
                          Mensajes().showErrorDialog(
                              context, 'Conectate a una red a internet!!!');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding:
                            EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.payment),
                          SizedBox(width: 8),
                          Text('Pagar con Paypal'),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Rest of the build method and other methods remain exactly the same
  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('home-screen'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction == 0) {
          _inactividadTimer?.cancel();
        } else {}
      },
      child: Listener(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          child: Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: primaryColor,
              title: Text(
                "Productos",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              actions: [
                Stack(
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      child: IconButton(
                        icon: Icon(Icons.shopping_cart, color: Colors.white),
                        onPressed: _showCart,
                      ),
                    ),
                    if (_cart.isNotEmpty)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: secondaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            _cart.length.toString(),
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                Container(
                  margin: EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(Icons.map, color: Colors.white),
                    onPressed: _map,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(Icons.warehouse_outlined, color: Colors.white),
                    onPressed: _moreTink,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(Icons.fingerprint, color: Colors.white),
                    onPressed: _huella,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(Icons.history, color: Colors.white),
                    onPressed: _compras,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(Icons.logout, color: Colors.white),
                    onPressed: cerrarSesion,
                  ),
                ),
              ],
            ),
            body: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  )
                : Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio:
                            0.6, // Adjusted from 0.7 to give more vertical space
                      ),
                      itemCount: _allProduct.length,
                      itemBuilder: (context, index) => Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2, // Adjusted flex ratio
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                  ),
                                  child: _allProduct[index]['imagen'] != null &&
                                          _allProduct[index]['imagen']
                                              .isNotEmpty
                                      ? Image.network(
                                          _allProduct[index]['imagen'],
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Center(
                                              child: Icon(
                                                Icons.image_not_supported,
                                                size: 40,
                                                color: Colors.grey[400],
                                              ),
                                            );
                                          },
                                        )
                                      : Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                            size: 40,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                ),
                              ),
                              Expanded(
                                flex: 3, // Adjusted flex ratio
                                child: Padding(
                                  padding: EdgeInsets.all(8), // Reduced padding
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment
                                        .spaceEvenly, // Changed to spaceEvenly
                                    children: [
                                      Text(
                                        _allProduct[index]['nombre_product'],
                                        style: titleStyle.copyWith(
                                            fontSize: 16), // Adjusted font size
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        "\$${_allProduct[index]['precio'].toString()}",
                                        style: priceStyle,
                                      ),
                                      Text(
                                        "Stock: ${_allProduct[index]['cantidad_producto']}",
                                        style: stockStyle,
                                      ),
                                      SizedBox(height: 4), // Small spacing
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () => _showQuantityDialog(
                                              _allProduct[index]),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                                vertical: 8), // Reduced padding
                                          ),
                                          child: Text(
                                            'Añadir',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),
          ),
        ),
      ),
    );
  }
}
