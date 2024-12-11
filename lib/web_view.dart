import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PayPalWebView extends StatefulWidget {
  final String approvalUrl;
  final Function(String payerId, String paymentId) onPaymentComplete;
  final VoidCallback onPaymentCancelled;

  PayPalWebView({
    required this.approvalUrl,
    required this.onPaymentComplete,
    required this.onPaymentCancelled,
    Key? key,
  }) : super(key: key);

  @override
  _PayPalWebViewState createState() => _PayPalWebViewState();
}

class _PayPalWebViewState extends State<PayPalWebView> {
  WebViewController? _controller;
  final String returnURL = 'aplicacion2://return';
  final String cancelURL = 'aplicacion2://cancel';
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _initializeWebViewController();
  }

  Future<void> _initializeWebViewController() async {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (NavigationRequest request) {
          if (_isNavigating) return NavigationDecision.prevent;

          if (request.url.startsWith(returnURL)) {
            _handleReturn(request.url);
            return NavigationDecision.prevent;
          } 
          if (request.url.startsWith(cancelURL)) {
            _handleCancel();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ));
    
    await controller.loadRequest(Uri.parse(widget.approvalUrl));
    if (mounted) {
      setState(() {
        _controller = controller;
      });
    }
  }

  void _handleReturn(String url) {
    if (_isNavigating) return;
    _isNavigating = true;

    final uri = Uri.parse(url);
    final payerId = uri.queryParameters['PayerID'];
    final paymentId = uri.queryParameters['paymentId'];

    if (payerId != null && paymentId != null) {
      widget.onPaymentComplete(payerId, paymentId);
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _handleCancel() {
    if (_isNavigating) return;
    _isNavigating = true;

    widget.onPaymentCancelled();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.onPaymentCancelled();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Pago PayPal'),
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              if (!_isNavigating) {
                _handleCancel();
              }
            },
          ),
        ),
        body: _controller == null
            ? Center(child: CircularProgressIndicator())
            : WebViewWidget(controller: _controller!),
      ),
    );
  }
}
