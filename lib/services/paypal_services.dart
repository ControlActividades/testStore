import 'dart:async';
import 'dart:convert';
import 'package:aplicacion2/global.dart';
import 'package:aplicacion2/web_view.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PayPalService {
  final String clientId =
      'AcaWZbFYfVqdakSWVvzBnQ9UhR1fi_l1y9pwq2sCu95G2tJsBo4qg7uAH9uLZAQ8zl4I-JqboC50gDSx';
  final String clientSecret =
      'ENKqQ_0VJ4mXYlpnAhZWprk_1je6xthdfXsInawG80MvvCBzneo0rJzgnMKS3zcb2r0Mgc-YvW2_MCSc';
  final String returnURL = 'aplicacion2://return';
  final String cancelURL = 'aplicacion2://cancel';

  static Completer<bool>? _paymentCompleter;
  Map<String, dynamic>? paymentDetailsG;

  Future<String> getAccessToken() async {
    try {
      final response = await http.post(
        Uri.parse('https://api-m.sandbox.paypal.com/v1/oauth2/token'),
        headers: {
          'Accept': 'application/json',
          'Accept-Language': 'en_US',
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
        },
        body: 'grant_type=client_credentials',
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['access_token'];
      } else {
        print('Error getting token: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get access token');
      }
    } catch (e) {
      print('Exception getting token: $e');
      throw Exception('Failed to get access token');
    }
  }

  Future<Map<String, dynamic>> createPayment(double amount, String description) async {
  final accessToken = await getAccessToken();

  // Aseguramos que 'amount' es un double y lo convertimos a String con 2 decimales
  final amountStr = (amount is int ? amount.toDouble() : amount).toStringAsFixed(2);

  final Map<String, dynamic> body = {
    'intent': 'sale',
    'payer': {'payment_method': 'paypal'},
    'transactions': [
      {
        'amount': {'total': amountStr, 'currency': 'MXN'},
        'description': description
      }
    ],
    'redirect_urls': {'return_url': returnURL, 'cancel_url': cancelURL}
  };

  try {
    final response = await http.post(
      Uri.parse('https://api-m.sandbox.paypal.com/v1/payments/payment'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print(
          'Error creating payment: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to create payment');
    }
  } catch (e) {
    print('Exception creating payment: $e');
    throw Exception('Failed to create payment');
  }
}

  Future<bool> processPayment(
      BuildContext context, double amount, String description) async {
    try {
      _paymentCompleter = Completer<bool>();

      final payment = await createPayment(amount, description);
      final approvalUrl = payment['links']
          .firstWhere((link) => link['rel'] == 'approval_url')['href'];

      if (await canLaunchUrl(Uri.parse(approvalUrl))) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PayPalWebView(
              approvalUrl: approvalUrl,
              onPaymentComplete: (payerId, paymentId) async {
                try {
                  final paymentDetails =
                      await executePayment(paymentId, payerId, context);
                  if (paymentDetails != null) {
                    savePaymentDetails(paymentDetails);
                    _paymentCompleter?.complete(true);
                  } else {
                    _paymentCompleter?.complete(false);
                  }
                } catch (e) {
                  print('Error executing payment: $e');
                  _paymentCompleter?.complete(false);
                }
              },
              onPaymentCancelled: () {
                _paymentCompleter?.complete(false);
              },
            ),
          ),
        );

        return await _paymentCompleter!.future;
      } else {
        throw Exception('Could not launch PayPal URL');
      }
    } catch (e) {
      print('Error processing payment: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar el pago: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  Future<Map<String, dynamic>?> executePayment(
      String paymentId, String payerId, BuildContext context) async {
    try {
      final accessToken = await getAccessToken();

      final response = await http.post(
        Uri.parse(
            'https://api-m.sandbox.paypal.com/v1/payments/payment/$paymentId/execute'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
        body: jsonEncode({'payer_id': payerId}),
      );

      print(
          'PayPal execute response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final paymentDetails = jsonDecode(response.body);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('¡Pago exitoso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return paymentDetails;
      } else {
        print(
            'Error executing payment: ${response.statusCode} - ${response.body}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al procesar el pago'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }
    } catch (e) {
      print('Exception executing payment: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar el pago: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPayments() async {
    final accessToken = await getAccessToken();

    try {
      final response = await http.get(
        Uri.parse('https://api-m.sandbox.paypal.com/v1/payments/payment'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(body['payments']);
      } else {
        print(
            'Error fetching payments: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch payments');
      }
    } catch (e) {
      print('Exception fetching payments: $e');
      throw Exception('Failed to fetch payments');
    }
  }

  Future<void> handlePaymentResponse(Uri uri, BuildContext context) async {
    if (_paymentCompleter == null || _paymentCompleter!.isCompleted) {
      return;
    }

    try {
      if (uri.toString().startsWith(returnURL)) {
        final payerId = uri.queryParameters['PayerID'];
        final paymentId = uri.queryParameters['paymentId'];

        if (payerId != null && paymentId != null) {
          final paymentDetails =
              await executePayment(paymentId, payerId, context);
          if (paymentDetails != null) {
            _paymentCompleter!.complete(true);
            // Aquí puedes manejar los detalles del pago como desees.
            print('Detalles del pago: $paymentDetails');
            savePaymentDetails(paymentDetails);
          } else {
            _paymentCompleter!.complete(false);
          }
        } else {
          _paymentCompleter!.complete(false);
        }
      } else if (uri.toString().startsWith(cancelURL)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pago cancelado'),
            backgroundColor: Colors.orange,
          ),
        );
        _paymentCompleter!.complete(false);
      }
    } catch (e) {
      print('Error handling payment response: $e');
      _paymentCompleter!.complete(false);
    }
  }

  Future<Map<String, dynamic>> getPaymentDetails(String paymentId) async {
    final accessToken = await getAccessToken();

    try {
      final response = await http.get(
        Uri.parse(
            'https://api-m.sandbox.paypal.com/v1/payments/payment/$paymentId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print(
            'Error fetching payment details: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch payment details');
      }
    } catch (e) {
      print('Exception fetching payment details: $e');
      throw Exception('Failed to fetch payment details');
    }
  }
  
}
