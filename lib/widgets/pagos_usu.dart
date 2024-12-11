import 'package:aplicacion2/db_helper.dart';
import 'package:aplicacion2/services/paypal_services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aplicacion2/services/network_service.dart';  // Importamos el NetworkService

class ComprasScreen extends StatefulWidget {
  @override
  _ComprasScreenState createState() => _ComprasScreenState();
}

class _ComprasScreenState extends State<ComprasScreen> {
  String? userId;
  List<Map<String, dynamic>> _allCompras = [];
  List<Map<String, dynamic>> _filteredCompras = [];
  TextEditingController _searchController = TextEditingController();
  int _itemsPerPage = 5; // Número de compras a mostrar inicialmente
  bool _hasMoreItems = true; // Indicador para cargar más compras
  bool _isInternetAvailable = true; // Indicador de conectividad a internet

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _searchController.addListener(_filterCompras);
  }

  // Cargar el id del usuario desde SharedPreferences
  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs
          .getInt('idUsu')
          ?.toString(); // Convertir a String si es necesario
    });

    // Verificar la conectividad a internet después de cargar el id del usuario
    await _checkInternetConnection();
  }

  // Verificar si el dispositivo tiene conexión a Internet
  Future<void> _checkInternetConnection() async {
    bool hasInternet = await NetworkService.isConnectedToInternet();
    setState(() {
      _isInternetAvailable = hasInternet;
    });
  }

  // Filtrar compras según el término de búsqueda
  void _filterCompras() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      _filteredCompras = _allCompras.where((compra) {
        // Filtrar por el ID de pago o la descripción (o cualquier otro campo que desees)
        return compra['idPago'].toLowerCase().contains(query) ||
            compra['createdAT'].toLowerCase().contains(query);
      }).toList();
    });
  }

  // Cargar más compras cuando se presiona el botón "Cargar más"
  void _loadMoreItems() {
    setState(() {
      _itemsPerPage += 5; // Aumentar el número de compras mostradas
      if (_itemsPerPage >= _allCompras.length) {
        _hasMoreItems = false; // No hay más compras para cargar
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      // Si el id del usuario no está disponible, mostrar un mensaje
      return Scaffold(
        appBar: AppBar(
          title: Text('Mis Compras'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isInternetAvailable) {
      // Si no hay conexión a Internet, mostrar un mensaje
      return Scaffold(
        appBar: AppBar(
          title: Text('Mis Compras'),
        ),
        body: Center(
          child: Text(
            'No tienes conexión a internet. Por favor verifica tu conexión.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Compras'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CompraSearchDelegate(_filteredCompras),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>( 
        // Usamos el método getCompraUsu para obtener las compras del usuario
        future: SQLHelper.getCompraUsu(userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar las compras'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No tienes compras registradas.'));
          }

          // Datos obtenidos de la base de datos
          List<Map<String, dynamic>> compras = snapshot.data!;

          // Actualizar la lista de compras
          _allCompras = compras;
          _filteredCompras = compras.take(_itemsPerPage).toList(); // Limitar las primeras compras

          return ListView.builder(
            itemCount: _filteredCompras.length,
            itemBuilder: (context, index) {
              var compra = _filteredCompras[index];

              // Esperamos los detalles de PayPal
              return FutureBuilder<Map<String, dynamic>>(
                future: _getPaypalDetails(compra['idPago']),
                builder: (context, paypalSnapshot) {
                  if (paypalSnapshot.connectionState == ConnectionState.waiting) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      elevation: 4,
                      child: ListTile(
                        title: Text('Cargando...'),
                        subtitle: Text('Espere un momento...'),
                      ),
                    );
                  }

                  if (paypalSnapshot.hasError) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      elevation: 4,
                      child: ListTile(
                        title: Text('Error al obtener detalles de PayPal'),
                      ),
                    );
                  }

                  if (!paypalSnapshot.hasData) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      elevation: 4,
                      child: ListTile(
                        title: Text('Detalles de PayPal no disponibles'),
                      ),
                    );
                  }

                  // Si los detalles de PayPal están disponibles, los mostramos
                  var paypalDetails = paypalSnapshot.data!;
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    elevation: 4,
                    child: ListTile(
                      title: Text(paypalDetails['transactions'][0]['description']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Monto Total: ${paypalDetails['transactions'][0]['amount']['total']} ${paypalDetails['transactions'][0]['amount']['currency']}'),
                          Text('Fecha: ${compra['createdAT']}'),
                          SizedBox(height: 10),
                          Text('Estado de pago: ${paypalDetails['state']}'),
                          Text(
                              'Método de pago: ${paypalDetails['payer']['payment_method']}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.info_outline),
                        onPressed: () {
                          _showCompraDetails(context, compra, paypalDetails);
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: _hasMoreItems
          ? FloatingActionButton(
              onPressed: _loadMoreItems,
              child: Icon(Icons.add),
              tooltip: 'Cargar más compras',
            )
          : null,
    );
  }

  // Método para obtener los detalles de PayPal
  Future<Map<String, dynamic>> _getPaypalDetails(String idPago) async {
    Map<String, dynamic>? paypalDetails;
    try {
      paypalDetails = await PayPalService().getPaymentDetails(idPago);
    } catch (e) {
      print('Error al obtener detalles de PayPal: $e');
    }
    return paypalDetails ?? {}; // Devuelve un mapa vacío si no se encuentran detalles
  }

  // Método para mostrar detalles de una compra
  void _showCompraDetails(BuildContext context, Map<String, dynamic> compra,
      Map<String, dynamic> paypalDetails) async {
    // Mostramos los detalles de la compra y de PayPal en un AlertDialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de la compra'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID de compra: ${compra['idPago']}'),
            Text('Fecha: ${compra['createdAT']}'),
            if (paypalDetails.isNotEmpty) ...[
              SizedBox(height: 10),
              Text('Detalles de PayPal:'),
              Text('Estado del pago: ${paypalDetails['state']}'),
              Text(
                  'Método de pago: ${paypalDetails['payer']['payment_method']}'),
              Text(
                  'Payer Email: ${paypalDetails['payer']['payer_info']['email']}'),
              Text(
                  'Monto Total: ${paypalDetails['transactions'][0]['amount']['total']} ${paypalDetails['transactions'][0]['amount']['currency']}'),
              Text(
                  'Descripción: ${paypalDetails['transactions'][0]['description']}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

// Clase personalizada para la búsqueda de compras
class CompraSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> compras;

  CompraSearchDelegate(this.compras);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = compras.where((compra) {
      return compra['idPago'].toLowerCase().contains(query.toLowerCase()) ||
          compra['createdAT'].toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        var compra = results[index];
        return ListTile(
          title: Text(compra['idPago']),
          subtitle: Text(compra['createdAT']),
          onTap: () {
            close(context, compra);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = compras.where((compra) {
      return compra['idPago'].toLowerCase().contains(query.toLowerCase()) ||
          compra['createdAT'].toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        var compra = suggestions[index];
        return ListTile(
          title: Text(compra['idPago']),
          subtitle: Text(compra['createdAT']),
          onTap: () {
            query = compra['idPago'];
            showResults(context);
          },
        );
      },
    );
  }
}
