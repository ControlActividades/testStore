import 'package:flutter/material.dart';
import 'package:aplicacion2/services/paypal_services.dart';

class PaymentsPage extends StatefulWidget {
  @override
  _PaymentsPageState createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  late PayPalService _payPalService;
  late Future<List<Map<String, dynamic>>> _paymentsFuture;
  List<Map<String, dynamic>> _allPayments = [];
  List<Map<String, dynamic>> _filteredPayments = [];
  TextEditingController _searchController = TextEditingController();
  int _itemsPerPage = 5; // Número de pagos a mostrar inicialmente
  bool _hasMoreItems = true; // Indicador para cargar más pagos

  @override
  void initState() {
    super.initState();
    _payPalService = PayPalService();
    _paymentsFuture = _payPalService.getPayments();
    _searchController.addListener(_filterPayments); // Agregamos el listener para el filtro
  }

  // Cargar más pagos cuando se presiona el botón "Cargar más"
  void _loadMoreItems() {
    setState(() {
      _itemsPerPage += 5; // Aumentar el número de pagos mostrados
      if (_itemsPerPage >= _allPayments.length) {
        _hasMoreItems = false; // No hay más pagos para cargar
      }
    });
  }

  // Filtrar pagos según el término de búsqueda
  void _filterPayments() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      _filteredPayments = _allPayments.where((payment) {
        // Filtrar por la descripción del pago
        return payment['transactions'][0]['description']
            .toLowerCase()
            .contains(query);
      }).toList();
    });
  }

  // Método para mostrar detalles de un pago cuando se da clic
  void _showPaymentDetails(BuildContext context, Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles del Pago'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Descripción: ${payment['transactions'][0]['description']}'),
              Text('Estado: ${payment['state']}'),
              Text(
                  'Monto Total: ${payment['transactions'][0]['amount']['total']} ${payment['transactions'][0]['amount']['currency']}'),
              Text('Fecha: ${payment['create_time']}'),
              SizedBox(height: 10),
              Text('Detalles de PayPal:'),
              Text('Método de pago: ${payment['payer']['payment_method']}'),
              Text(
                  'Email del pagador: ${payment['payer']['payer_info']['email']}'),
            ],
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pagos Realizados'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Mostrar un campo de búsqueda para filtrar los pagos
              showSearch(
                context: context,
                delegate: PaymentSearchDelegate(
                    _filteredPayments, _showPaymentDetails),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _paymentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Conéctate a una red!!!'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No hay pagos realizados'));
          } else {
            // Datos obtenidos de la API de PayPal
            final payments = snapshot.data!;

            // Actualizar la lista de pagos y filtrarlos
            _allPayments = payments;
            _filteredPayments = payments.take(_itemsPerPage).toList();

            return ListView.builder(
              itemCount: _filteredPayments.length,
              itemBuilder: (context, index) {
                final payment = _filteredPayments[index];

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 4,
                  child: ListTile(
                    title: Text(payment['transactions'][0]['description'] ??
                        'Sin descripción'),
                    subtitle: Text(
                        'Monto: ${payment['transactions'][0]['amount']['total']} ${payment['transactions'][0]['amount']['currency']}'),
                    trailing: payment['state'] == 'approved'
                        ? Icon(Icons.check_circle, color: Colors.green)
                        : Icon(Icons.cancel, color: Colors.red),
                    onTap: () {
                      _showPaymentDetails(context, payment);
                    },
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: _hasMoreItems
          ? FloatingActionButton(
              onPressed: _loadMoreItems,
              child: Icon(Icons.add),
              tooltip: 'Cargar más pagos',
              backgroundColor: Colors.deepPurple,
            )
          : null,
    );
  }
}

// Clase personalizada para la búsqueda de pagos
class PaymentSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> payments;
  final Function(BuildContext, Map<String, dynamic>) showPaymentDetails;

  PaymentSearchDelegate(this.payments, this.showPaymentDetails);

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
    final results = payments.where((payment) {
      return payment['transactions'][0]['description']
          .toLowerCase()
          .contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final payment = results[index];
        return ListTile(
          title: Text(
              payment['transactions'][0]['description'] ?? 'Sin descripción'),
          subtitle: Text(
              'Monto: ${payment['transactions'][0]['amount']['total']} ${payment['transactions'][0]['amount']['currency']}'),
          onTap: () {
            showPaymentDetails(context, payment);
            close(context, payment);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = payments.where((payment) {
      return payment['transactions'][0]['description']
          .toLowerCase()
          .contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final payment = suggestions[index];
        return ListTile(
          title: Text(
              payment['transactions'][0]['description'] ?? 'Sin descripción'),
          subtitle: Text(
              'Monto: ${payment['transactions'][0]['amount']['total']} ${payment['transactions'][0]['amount']['currency']}'),
          onTap: () {
            query = payment['transactions'][0]['description'];
            showResults(context);
          },
        );
      },
    );
  }
}
