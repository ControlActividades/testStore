import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class MailHelper {
  static Future<void> sendCart(
      String correoUsu,
      List<Map<String, dynamic>> productos,
      Map<String, dynamic>? paymentDetails) async {
    // Información de autenticación
    String username = 'rodriguez.mora.zahir.15@gmail.com';
    String password = 'lsli frjn naku iyoh';
    String destino = 'gds0641.tsu.iv@gmail.com';
    final smtpServer = gmail(username, password);

    // Calcular el total y la lista de productos
    double total = 0.0;
    String productListHtml = productos.map((producto) {
      double precio = producto['precio'];
      int cantidad = producto['cart_quantity'];
      total += precio * cantidad;
      return """
    <tr style="border-bottom: 1px solid #ddd;">
      <td style="padding: 15px; text-align: left;">
        <img src="${producto['imagen']}" alt="${producto['nombre_product']}" width="60" style="border-radius: 4px;">
      </td>
      <td style="padding: 15px; text-align: left; font-weight: bold; color: #333;">${producto['nombre_product']}</td>
      <td style="padding: 15px; text-align: center; color: #888;">\$${precio.toStringAsFixed(2)}</td>
      <td style="padding: 15px; text-align: center; color: #888;">$cantidad</td>
      <td style="padding: 15px; text-align: center; font-weight: bold; color: #333;">\$${(precio * cantidad).toStringAsFixed(2)}</td>
    </tr>
    """;
    }).join();

    // Agregar detalles del pago al mensaje
    String paymentDetailsHtml = """
<h2 style="font-size: 22px; color: #333; margin-bottom: 20px;">Detalles del Pago</h2>
<p><strong>ID de Pago:</strong> ${paymentDetails?['id']}</p>
<p><strong>Estado:</strong> ${paymentDetails?['state']}</p>
<p><strong>Fecha:</strong> ${paymentDetails?['create_time']}</p>
<p><strong>Método de Pago:</strong> ${paymentDetails?['payer']['payment_method']}</p>
<p><strong>Correo del Pagador:</strong> ${paymentDetails?['payer']['payer_info']['email']}</p>
<p><strong>Nombre del Pagador:</strong> ${paymentDetails?['payer']['payer_info']['first_name']} ${paymentDetails?['payer']['payer_info']['last_name']}</p>
<p><strong>ID del Pagador:</strong> ${paymentDetails?['payer']['payer_info']['payer_id']}</p>
<p><strong>Dirección de Envío:</strong></p>
<ul>
  <li><strong>Nombre:</strong> ${paymentDetails?['payer']['payer_info']['shipping_address']['recipient_name']}</li>
  <li><strong>Dirección:</strong> ${paymentDetails?['payer']['payer_info']['shipping_address']['line1']}</li>
  <li><strong>Ciudad:</strong> ${paymentDetails?['payer']['payer_info']['shipping_address']['city']}</li>
  <li><strong>Estado:</strong> ${paymentDetails?['payer']['payer_info']['shipping_address']['state']}</li>
  <li><strong>Código Postal:</strong> ${paymentDetails?['payer']['payer_info']['shipping_address']['postal_code']}</li>
  <li><strong>Código de País:</strong> ${paymentDetails?['payer']['payer_info']['shipping_address']['country_code']}</li>
</ul>
""";

    // Crear el mensaje
    final message = Message()
      ..from = Address(username, 'Zahir Andrés Rodriguez Mora')
      ..recipients.addAll(
          [destino, correoUsu]) // Añadir ambos correos a los destinatarios
      ..ccRecipients.addAll([username, destino])
      ..bccRecipients.add(Address(destino))
      ..subject = 'Resumen de tu compra - ${DateTime.now()}'
      ..text = 'Este es el resumen de tu compra...'
      ..html = """
      <!DOCTYPE html>
<html lang="es">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Resumen de Compra</title>
    <style>
      body {
        font-family: 'Arial', sans-serif;
        margin: 0;
        padding: 0;
        background-color: #f4f4f9;
        color: #333;
      }
      .container {
        width: 100%;
        max-width: 650px;
        margin: 30px auto;
        background-color: #ffffff;
        border-radius: 8px;
        box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
        padding: 30px;
      }
      .header {
        text-align: center;
        margin-bottom: 25px;
      }
      .header img {
        width: 120px;
        margin-bottom: 15px;
      }
      .header h1 {
        font-size: 30px;
        color: #333;
        margin: 0;
        font-weight: 600;
      }
      .content {
        font-size: 16px;
        color: #555;
        line-height: 1.6;
      }
      .product-table {
        width: 100%;
        margin-top: 20px;
        border-collapse: collapse;
      }
      .product-table th, .product-table td {
        padding: 12px;
        text-align: left;
        border-bottom: 1px solid #f1f1f1;
      }
      .product-table th {
        background-color: #f8f8f8;
        color: #555;
        font-weight: 600;
      }
      .product-table td {
        color: #777;
      }
      .total {
        text-align: right;
        font-size: 18px;
        color: #FF5722;
        font-weight: bold;
        margin-top: 20px;
      }
      .footer {
        text-align: center;
        padding: 20px;
        background-color: #f1f1f1;
        border-top: 1px solid #ddd;
        margin-top: 30px;
      }
      .footer p {
        font-size: 14px;
        color: #888;
      }
      .section-title {
        font-size: 22px;
        color: #333;
        margin-bottom: 20px;
        font-weight: 600;
      }
      .payment-details p {
        margin: 8px 0;
        font-size: 16px;
        color: #555;
      }
      .payment-details strong {
        color: #333;
      }
      .payment-details ul {
        list-style-type: none;
        padding-left: 0;
        margin: 10px 0;
      }
      .payment-details ul li {
        margin-bottom: 6px;
        color: #777;
      }
      .btn {
        display: inline-block;
        padding: 10px 15px;
        background-color: #FF5722;
        color: #fff;
        font-size: 16px;
        font-weight: 600;
        text-decoration: none;
        border-radius: 5px;
        margin-top: 20px;
      }
      .btn:hover {
        background-color: #E64A19;
      }
      @media (max-width: 600px) {
        .container {
          width: 90%;
        }
        .header h1 {
          font-size: 26px;
        }
        .product-table th, .product-table td {
          font-size: 14px;
        }
      }
    </style>
  </head>
  <body>
    <div class="container">
      <div class="header">
        <img src="URL_DEL_LOGO" alt="Logo Ejemplo">
        <h1>Resumen de Compra</h1>
      </div>
      <div class="content">
        <h2 class="section-title">Detalles del Pedido</h2>
        <table class="product-table">
          <thead>
            <tr>
              <th>Imagen</th>
              <th>Producto</th>
              <th>Precio</th>
              <th>Cantidad</th>
              <th>Total</th>
            </tr>
          </thead>
          <tbody>
            <!-- Aquí se llenará dinámicamente con los productos -->
            $productListHtml
          </tbody>
        </table>
        <div class="total">
          <h3>Total: \$${total.toStringAsFixed(2)}</h3> <!-- Asegúrate de formatear el total -->
        </div>
        <!-- Aquí se llenará dinámicamente con los detalles de pago -->
        $paymentDetailsHtml
      </div>
      <div class="footer">
        <p>Gracias por su compra en Ejemplo. ¡Esperamos verte pronto!</p>
      </div>
    </div>
  </body>
</html>
 
    """;

    try {
      final connection = PersistentConnection(smtpServer);
      await connection.send(message);
      await connection.close();
      print('Correo enviado exitosamente.');
    } on MailerException catch (e) {
      for (var p in e.problems) {
        print('Problema: ${p.code}: ${p.msg}');
      }
      print('Error al enviar el correo: ${e.toString()}');
      await sendErrorNotification(e, correoUsu, smtpServer);
    } catch (e) {
      print('Ocurrió un error inesperado: ${e.toString()}');
      await sendErrorNotification(e, correoUsu, smtpServer);
    }
  }

  static Future<void> sendErrorNotification(
      dynamic error, String correoUsuario, SmtpServer smtpServer) async {
    String username = 'rodriguez.mora.zahir.15@gmail.com';
    String correoAdmin = 'gds0641.tsu.iv@gmail.com';

    // Crear el mensaje de notificación
    final message = Message()
      ..from = Address(username, 'Zahir Andrés Rodriguez Mora')
      ..recipients.add(correoAdmin)
      ..subject = 'Error al enviar correo a $correoUsuario - ${DateTime.now()}'
      ..text =
          'Hubo un error al enviar el correo al usuario $correoUsuario.\nError: $error'
      ..html = """
        <div style="font-family: Arial, sans-serif; color: #444;">
          <h2>Error al enviar correo a $correoUsuario</h2>
          <p>Hubo un error al intentar enviar el correo al usuario <strong>$correoUsuario</strong>.</p>
          <p><strong>Error:</strong> $error</p>
        </div>
      """;

    try {
      final connection = PersistentConnection(smtpServer);
      await connection.send(message);
      await connection.close();
      print('Notificación de error enviada al administrador.');
    } on MailerException catch (e) {
      print(
          'Error al enviar la notificación de error al administrador: ${e.toString()}');
    }
  }

  static Future<void> sendPassword(String correoUsu, String cont) async {
    // Información de autenticación
    String username = 'rodriguez.mora.zahir.15@gmail.com';
    String password = 'lsli frjn naku iyoh';
    String destino = 'gds0641.tsu.iv@gmail.com';
    final smtpServer = gmail(username, password);

    // Crear el mensaje
    final message = Message()
      ..from = Address(username, 'Zahir Andrés Rodriguez Mora')
      ..recipients.addAll(
          [destino, correoUsu]) // Añadir ambos correos a los destinatarios
      ..ccRecipients.addAll([username, destino])
      ..bccRecipients.add(Address(destino))
      ..subject = 'Recuperacion de contraseña - ${DateTime.now()}'
      ..text = 'Esta es la recueperación de tu contraseña...'
      ..html = """
        <!DOCTYPE html>
<html lang="es">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Resumen de Cambio de Contraseña</title>
    <style>
      body {
        font-family: 'Arial', sans-serif;
        margin: 0;
        padding: 0;
        background-color: #f9f9f9;
      }
      .container {
        width: 100%;
        max-width: 600px;
        margin: 20px auto;
        background-color: #ffffff;
        border-radius: 10px;
        box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
        padding: 20px;
      }
      .header {
        text-align: center;
        margin-bottom: 20px;
      }
      .header img {
        width: 150px;
        margin-bottom: 10px;
      }
      .header h1 {
        font-size: 28px;
        color: #333;
        margin: 0;
        font-weight: bold;
      }
      .content {
        font-size: 16px;
        color: #555;
      }
      .content h3 {
        font-size: 20px;
        color: #333;
        font-weight: bold;
      }
      .footer {
        text-align: center;
        padding: 15px;
        background-color: #f1f1f1;
        border-top: 1px solid #ddd;
        margin-top: 20px;
      }
      .footer p {
        font-size: 14px;
        color: #888;
      }
      .footer a {
        color: #0066cc;
        text-decoration: none;
        font-weight: bold;
      }
      @media (max-width: 600px) {
        .container {
          width: 90%;
        }
        .header h1 {
          font-size: 24px;
        }
        .content h3 {
          font-size: 18px;
        }
      }
    </style>
  </head>
  <body>
    <div class="container">
      <div class="header">
        <img src="URL_DEL_LOGO" alt="Logo Ejemplo">
        <h1>Resumen de Cambio de Contraseña</h1>
      </div>
      <div class="content">
        <h2 style="font-size: 22px; color: #333; margin-bottom: 20px;">Contraseña Recuperada</h2>
        <h3>Su nueva contraseña es: $cont</h3>
        <p style="font-size: 14px; color: #777;">Si no fue usted quien solicitó este cambio, por favor contacte con nosotros de inmediato.</p>
      </div>
      <div class="footer">
        <p>Si no fue usted quien solicitó este cambio, reporte el incidente a <a href="mailto:rodriguez.mora.zahir.15@gmail.com">rodriguez.mora.zahir.15@gmail.com</a></p>
      </div>
    </div>
  </body>
</html>

      """;

    try {
      final connection = PersistentConnection(smtpServer);
      await connection.send(message);
      await connection.close();
      print('Correo enviado exitosamente.');
    } on MailerException catch (e) {
      print('Error al enviar el correo: ${e.toString()}');
    }
  }

  
}
