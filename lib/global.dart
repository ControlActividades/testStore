// global.dart
Map<String, dynamic> globalPaymentDetails = {};

// Función para almacenar el Map en la variable global
void savePaymentDetails(Map<String, dynamic> paymentDetails) {
  globalPaymentDetails = paymentDetails;
}

// Función para acceder a los detalles guardados
Map<String, dynamic> getPaymentDetails() {
  return globalPaymentDetails;
}
