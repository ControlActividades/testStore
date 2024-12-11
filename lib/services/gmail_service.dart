import 'package:mailer/smtp_server.dart';
import 'package:mailer/mailer.dart';

class EmailService {
  static Future<void> sendEmail(String user, String secretKey) async {
    final smtpServer = gmail('rodriguez.mora.zahir.15@gmail.com',
        'lsli frjn naku iyoh'); // Usar credenciales de Gmail

    final message = Message()
      ..from = Address('rodriguez.mora.zahir.15@gmail.com', 'Test Store')
      ..recipients.add(user) // Destinatario
      ..subject = 'Bienvenido...'
      ..text =
          'Se ha creado código para tu inicio de sesion la siguiente clave secreta:'
      ..html = '''
     <html>
  <head>
    <style>
      /* Estilos generales */
      body {
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        background-color: #f1f4f9;
        margin: 0;
        padding: 0;
        color: #333;
      }

      .container {
        width: 100%;
        max-width: 650px;
        margin: 40px auto;
        background-color: #ffffff;
        padding: 30px;
        border-radius: 12px;
        box-shadow: 0 12px 30px rgba(0, 0, 0, 0.1);
        text-align: center;
        font-size: 16px;
        transition: all 0.3s ease-in-out;
      }

      .container:hover {
        box-shadow: 0 15px 40px rgba(0, 0, 0, 0.2);
        transform: translateY(-5px);
      }

      /* Encabezado */
      .header {
        background-color: #00aaff;
        color: white;
        padding: 20px;
        border-radius: 12px;
        box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
      }

      .header h1 {
        font-size: 28px;
        margin: 0;
        font-weight: bold;
      }

      /* Contenido */
      .content {
        margin-top: 25px;
      }

      .content h2 {
        font-size: 22px;
        color: #333;
        margin-bottom: 10px;
      }

      .content p {
        font-size: 16px;
        color: #555;
        line-height: 1.8;
      }

      /* Footer */
      .footer {
        margin-top: 30px;
        font-size: 14px;
        color: #aaa;
        text-align: center;
        border-top: 1px solid #eee;
        padding-top: 20px;
      }

      /* Botón */
      .button {
        background-color: #00aaff;
        color: white;
        padding: 12px 25px;
        border-radius: 25px;
        text-decoration: none;
        display: inline-block;
        font-size: 16px;
        transition: background-color 0.3s ease-in-out;
        margin-top: 25px;
      }

      .button:hover {
        background-color: #0088cc;
      }

      /* QR Code */
      .qr-image {
        display: block;
        margin: 20px auto;
        width: 220px;
        height: 220px;
        border-radius: 12px;
        box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
      }

      .qr-instructions {
        font-size: 14px;
        color: #333;
        margin-top: 15px;
        text-align: center;
      }
    </style>
  </head>
  <body>
    <div class="container">
      <div class="header">
        <h1>Has iniciado sesión correctamente</h1>
      </div>
      <div class="content">
        <h2>¡Bienvenido de nuevo!</h2>
        <p>Tu sesión se ha iniciado correctamente. Ahora solo comprueba que eres tú ingresando esta llave de acceso: <strong>$secretKey</strong>.</p>
        <p>Gracias por usar nuestro servicio. Si necesitas ayuda, no dudes en contactarnos.</p>
      </div>
      <div class="footer">
        <p>Este es un mensaje automatizado. Si no has solicitado este inicio de sesión, ignora este mensaje.</p>
      </div>
    </div>
  </body>
</html>


      ''';

    try {
      final sendReport = await send(message, smtpServer);
      print('Correo enviado: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('Error al enviar el correo: $e');
    }
  }

//secret key para pagos
  static Future<void> sendPayment(String user, String secretKey) async {
    final smtpServer = gmail('rodriguez.mora.zahir.15@gmail.com',
        'lsli frjn naku iyoh'); // Usar credenciales de Gmail

    final message = Message()
      ..from = Address('rodriguez.mora.zahir.15@gmail.com', 'Test Store')
      ..recipients.add(user) // Destinatario
      ..subject = 'Vamos a pagar !!!'
      ..text =
          'Se ha creado código para tu hacer tu pago, la siguiente clave secreta: $secretKey'
      ..html = '''
      <html>
  <head>
    <style>
      /* Estilos generales */
      body {
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        background-color: #f5f7fb;
        margin: 0;
        padding: 0;
        color: #333;
      }

      /* Contenedor principal */
      .container {
        width: 100%;
        max-width: 600px;
        margin: 30px auto;
        background-color: #ffffff;
        padding: 25px;
        border-radius: 12px;
        box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
        text-align: center;
      }

      .container:hover {
        box-shadow: 0 15px 30px rgba(0, 0, 0, 0.2);
        transform: translateY(-3px);
      }

      /* Encabezado */
      .header {
        background-color: #00aaff;
        color: white;
        padding: 20px;
        border-radius: 12px;
        box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
      }

      .header h1 {
        font-size: 28px;
        margin: 0;
        font-weight: bold;
      }

      /* Contenido */
      .content {
        margin-top: 25px;
        font-size: 16px;
        color: #555;
      }

      .content p {
        font-size: 18px;
        color: #333;
        line-height: 1.8;
      }

      .content strong {
        color: #0077cc;
        font-weight: bold;
        font-size: 18px;
      }

      /* Footer */
      .footer {
        margin-top: 30px;
        font-size: 14px;
        color: #999;
        text-align: center;
        border-top: 1px solid #eee;
        padding-top: 20px;
      }

      /* Estilos de enlace */
      .button {
        background-color: #00aaff;
        color: white;
        padding: 12px 25px;
        border-radius: 25px;
        text-decoration: none;
        display: inline-block;
        font-size: 16px;
        margin-top: 30px;
        transition: background-color 0.3s ease-in-out;
      }

      .button:hover {
        background-color: #0088cc;
      }

      /* Instrucciones */
      .qr-instructions {
        font-size: 14px;
        color: #555;
        margin-top: 15px;
        text-align: center;
      }

      /* Imagen QR */
      .qr-image {
        display: block;
        margin: 20px auto;
        width: 180px;
        height: 180px;
        border-radius: 12px;
        box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
      }
    </style>
  </head>
  <body>
    <div class="container">
      <div class="header">
        <h1>Esperamos verificar que seas tú</h1>
      </div>
      <div class="content">
        <p><strong>Clave Secreta:</strong> $secretKey</p>
      </div>
      <div class="footer">
        <p>Este es un mensaje automatizado. Si no has solicitado este registro, ignora este mensaje.</p>
      </div>
    </div>
  </body>
</html>

      ''';

    try {
      final sendReport = await send(message, smtpServer);
      print('Correo enviado: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('Error al enviar el correo: $e');
    }
  }

  static Future<void> sendCambioDatos(String correoUsu, String cont, String usu,
      String nomb, String correo) async {
    final smtpServer = gmail('rodriguez.mora.zahir.15@gmail.com',
        'lsli frjn naku iyoh'); // Usar credenciales de Gmail

    final message = Message()
      ..from = Address('rodriguez.mora.zahir.15@gmail.com', 'Test Store')
      ..recipients.add(correo) // Destinatario
      ..subject = 'Tu cuenta ha sido modificada por $correoUsu'
      ..text = ''
      ..html = '''
        <html lang="es">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Resumen de Compra</title>
    <style>
      /* Estilos generales */
      body {
        font-family: 'Arial', sans-serif;
        margin: 0;
        padding: 0;
        background-color: #f4f7fa;
        color: #333;
      }

      /* Contenedor principal */
      .container {
        width: 100%;
        max-width: 600px;
        margin: 30px auto;
        background-color: #ffffff;
        border-radius: 12px;
        box-shadow: 0 10px 20px rgba(0, 0, 0, 0.1);
        padding: 20px;
        text-align: center;
      }

      /* Cabecera */
      .header {
        margin-bottom: 30px;
      }

      .header img {
        width: 150px;
        margin-bottom: 15px;
      }

      .header h1 {
        font-size: 28px;
        color: #333;
        margin: 0;
        font-weight: bold;
      }

      /* Estilos para el contenido */
      .content {
        font-size: 16px;
        color: #555;
        margin-bottom: 20px;
        text-align: left;
      }

      .content h2 {
        font-size: 22px;
        color: #444;
        margin-bottom: 15px;
        font-weight: 600;
      }

      .content h3 {
        font-size: 16px;
        margin-bottom: 10px;
        font-weight: 500;
      }

      .content h3 span {
        font-weight: 700;
        color: #0077cc;
      }

      /* Pie de página */
      .footer {
        text-align: center;
        padding: 15px;
        background-color: #f1f1f1;
        border-top: 1px solid #ddd;
        margin-top: 20px;
        font-size: 14px;
        color: #888;
      }

      /* Responsividad para móviles */
      @media (max-width: 600px) {
        .container {
          width: 90%;
        }

        .header h1 {
          font-size: 24px;
        }

        .content h2 {
          font-size: 20px;
        }

        .content h3 {
          font-size: 14px;
        }
      }
    </style>
  </head>
  <body>
    <div class="container">
      <div class="header">
        <img src="URL_DEL_LOGO" alt="Logo Ejemplo">
        <h1>Resumen de los datos modificados</h1>
      </div>
      <div class="content">
        <h2>Datos modificados</h2>
        <h3>Su usuario es: <span>$usu</span></h3>
        <h3>Su contraseña es: <span>$cont</span></h3>
        <h3>Su nombre es: <span>$nomb</span></h3>
        <h3>Su correo electrónico es: <span>$correo</span></h3>
      </div>
      <div class="footer">
        <p>Modificado por: <span>"$correoUsu"</span></p>
      </div>
    </div>
  </body>
</html>

      ''';

    try {
      final sendReport = await send(message, smtpServer);
      print('Correo enviado: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('Error al enviar el correo: $e');
    }
  }

  static Future<void> recuperarPass(String correo, String secretKey) async {
    final smtpServer = gmail('rodriguez.mora.zahir.15@gmail.com',
        'lsli frjn naku iyoh'); // Usar credenciales de Gmail

    final message = Message()
      ..from = Address('rodriguez.mora.zahir.15@gmail.com', 'Test Store')
      ..recipients.add(correo) // Destinatario
      ..subject = '¿Eres tu?'
      ..text =
          'Se ha creado código para recuperar contraseña, la siguiente clave secreta: $secretKey'
      ..html = '''
      <html lang="es">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Verificación de Usuario</title>
    <style>
      body {
        font-family: 'Arial', sans-serif;
        margin: 0;
        padding: 0;
        background-color: #f4f7fa;
        color: #333;
      }

      .container {
        width: 100%;
        max-width: 600px;
        margin: 30px auto;
        background-color: #ffffff;
        border-radius: 12px;
        box-shadow: 0 10px 20px rgba(0, 0, 0, 0.1);
        padding: 30px;
      }

      .header {
        text-align: center;
        background-color: #0066cc;
        color: white;
        padding: 20px;
        border-radius: 8px;
      }

      .header h1 {
        margin: 0;
        font-size: 26px;
        font-weight: bold;
      }

      .content {
        padding: 20px;
        font-size: 16px;
        color: #555;
        text-align: left;
      }

      .content h2 {
        font-size: 20px;
        color: #333;
        margin-bottom: 15px;
        font-weight: bold;
      }

      .content p {
        font-size: 14px;
        line-height: 1.6;
        color: #666;
      }

      .content .key {
        font-weight: bold;
        font-size: 18px;
        color: #0077cc;
      }

      .footer {
        text-align: center;
        padding: 20px;
        font-size: 12px;
        color: #888;
        border-top: 1px solid #f1f1f1;
      }

      .footer p {
        margin: 0;
      }

      .button {
        background-color: #0066cc;
        color: white;
        text-align: center;
        padding: 12px 25px;
        border-radius: 5px;
        text-decoration: none;
        display: inline-block;
        margin-top: 20px;
      }

      .button:hover {
        background-color: #004c99;
      }

      /* Estilo para dispositivos móviles */
      @media (max-width: 600px) {
        .container {
          width: 90%;
        }

        .header h1 {
          font-size: 22px;
        }

        .content h2 {
          font-size: 18px;
        }

        .footer {
          padding: 15px;
        }
      }
    </style>
  </head>
  <body>
    <div class="container">
      <div class="header">
        <h1>Esperamos verificar que seas tú</h1>
      </div>
      <div class="content">
        <h2>Clave Secreta</h2>
        <p><span class="key">$secretKey</span></p>
      </div>
      <div class="footer">
        <p>Este es un mensaje automatizado. Si no has solicitado este registro, por favor ignora este mensaje.</p>
      </div>
    </div>
  </body>
</html>

      ''';

    try {
      final sendReport = await send(message, smtpServer);
      print('Correo enviado: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('Error al enviar el correo: $e');
    }
  }

  static Future<void> sendCart(
      String? correoUsu, Map<String, dynamic>? paymentDetails) async {
    // Información de autenticación
    String username = 'rodriguez.mora.zahir.15@gmail.com';
    String password = 'lsli frjn naku iyoh';
    String destino = 'gds0641.tsu.iv@gmail.com';
    final smtpServer = gmail(username, password);

    // Agregar detalles del pago al mensaje
    String paymentDetailsHtml = """
    <p><strong>ID de Pago:</strong> ${paymentDetails?['id']}</p>
    <p><strong>Estado:</strong> ${paymentDetails?['state']}</p>
    <p><strong>Fecha:</strong> ${paymentDetails?['create_time']}</p>
    <p><strong>Método de Pago:</strong> ${paymentDetails?['payer']['payment_method']}</p>
    <p><strong>Correo del Pagador:</strong> ${paymentDetails?['payer']['payer_info']['email']}</p>
    <p><strong>Descripción del Pedido:</strong> ${paymentDetails?['transactions'][0]['description']}</p>
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
        
        <div class="payment-details">
          $paymentDetailsHtml
        </div>

      </div>
      <div class="footer">
        <p>Gracias por su compra en TestStore. ¡Esperamos verte pronto!</p>
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
    } catch (e) {
      print('Error al enviar el correo: ${e.toString()}');
    }
  }
}
