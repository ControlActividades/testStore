import 'package:aplicacion2/services/paypal_services.dart';
import 'package:otp/otp.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:crypto/crypto.dart';
import 'dart:convert';

class SQLHelper {
  static Future<void> createTables(sql.Database database) async {
    await database.execute("""CREATE TABLE user_app(
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      usuario TEXT NOT NULL,
      cont TEXT NOT NULL,
      correo TEXT NOT NULL UNIQUE,
      nombre TEXT NOT NULL,
      rol INTEGER NOT NULL,
      secretkey TEXT,
      huella_digital_token TEXT,
      createdAT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    )""");

    await database.execute("""CREATE TABLE producto_app(
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      nombre_product TEXT NOT NULL,
      precio DOUBLE NOT NULL,
      cantidad_producto INTEGER NOT NULL,
      imagen TEXT NOT NULL,
      createdAT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    )""");

    await database.execute("""CREATE TABLE compras_usu(
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      idUsu TEXT NOT NULL,
      idPago TEXT NOT NULL,
      createdAT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )""");

    await database.execute("""CREATE TABLE user_fingerprints(
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      user_id INTEGER NOT NULL,
      fingerprint_token TEXT NOT NULL,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(user_id) REFERENCES user_app(id)
    )""");

    // Crea administrador
    String hashedPassword = _generateHash('Linux2024!');
    await database.execute("""INSERT INTO user_app(
      usuario, cont, correo, nombre, rol,secretkey) values ('MrMexico2014','$hashedPassword','rodriguez.mora.zahir.15@gmail.com','Zahir Andrés Rodríguez Mora',3,'ZSNJUA6SAP3NJKTR')""");

    await database.execute("""INSERT INTO producto_app(
      nombre_product, precio, cantidad_producto, imagen) 
      values ('Bocho',100,10,'https://www.eluniversal.com.mx/sites/default/files/2018/12/12/volkswagen_restaura_vocho_de_hace48_anos8.jpg')
      """);

    await database.execute("""INSERT INTO producto_app(
      nombre_product, precio, cantidad_producto, imagen) 
      values ('Camaro',100,10,'https://th.bing.com/th/id/R.7d80bb7c6459cafc4de5eb7b48a99596?rik=t1gqrDpejVAAQw&riu=http%3a%2f%2fwww.hdcarwallpapers.com%2fwalls%2f1970_chevrolet_camaro_rs-HD.jpg&ehk=17NAq8VmLzglXYWXbObL69B8blO1ruGsvGzUFofULIU%3d&risl=&pid=ImgRaw&r=0')
      """);
  }

  // Crear base de datos
  static Future<sql.Database> db() async {
    return sql.openDatabase("database_v14.db", version: 1,
        onCreate: (sql.Database database, int version) async {
      await createTables(database);
    });
  }

  // Generar hash de la contraseña
  static String _generateHash(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Crear un usuario
  static Future<int> createUser(String usuario, String cont, String nombre,
      String correo, int rol, String? huellaToken) async {
    final db = await SQLHelper.db();

    String secretKey = OTP.randomSecret();
    String hashedPassword = _generateHash(cont);
    final userApp = {
      'usuario': usuario,
      'cont': hashedPassword,
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
      'secretkey': secretKey,
      'huella_digital_token':
          huellaToken // Guardamos el token de huella digital
    };
    final id = await db.insert('user_app', userApp,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  // Actualizar el token de la huella digital
  static Future<int> updateFingerprintToken(int id, String token) async {
    final db = await SQLHelper.db();

    final user = {
      'huella_digital_token': token,
    };

    final result = await db.update(
      'user_app',
      user,
      where: 'id = ?',
      whereArgs: [id],
    );

    return result;
  }

  // Validar login con huella digital (comparando el token de huella)
  static Future<bool> loginWithFingerprint(String userId, String token) async {
    final db = await SQLHelper.db();

    var res = await db.query(
      'user_app',
      where: 'id = ? AND huella_digital_token = ?',
      whereArgs: [userId, token],
    );

    return res.isNotEmpty; // Retorna true si el token coincide
  }

  // Obtener todos los usuarios
  static Future<List<Map<String, dynamic>>> getAllUser() async {
    final db = await SQLHelper.db();
    return db.query('user_app', where: "rol!=3", orderBy: 'id');
  }

  // Obtener un solo usuario
  static Future<List<Map<String, dynamic>>> getSingleUser(
      String nomUsuario, String pass) async {
    final db = await SQLHelper.db();
    String hashedPassword = _generateHash(pass);
    return db.query('user_app',
        where: "usuario=? AND cont=?",
        whereArgs: [nomUsuario, hashedPassword],
        limit: 1);
  }

//actualizar jwt
  static Future<int> updateSecretKey(String user, int id) async {
    final db = await SQLHelper.db();
    String secretKey = OTP.randomSecret();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final userApp = {
      'secretKey': secretKey,
    };

    final id2 = await db.update(
      'user_app',
      userApp,
      where: "id = ?",
      whereArgs: [id],
    );

    // Enviar el email con el nuevo secretKey

    await prefs.setString('secretKey', secretKey);

    return id2;
  }

  // Actualizar los usuarios
  static Future<int> updateUser(int id, String usuario, String cont,
      String nombre, String correo, int rol) async {
    final db = await SQLHelper.db();
    String hashedPassword = _generateHash(cont);
    final user = {
      'usuario': usuario,
      'cont': hashedPassword,
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
      'createdAT': DateTime.now().toString()
    };

    final result =
        await db.update('user_app', user, where: "id=?", whereArgs: [id]);
    return result;
  }

  //Actualizar contraseña
  static Future<int> updatePass(int id, String cont) async {
    final db = await SQLHelper.db();
    String hashedPassword = _generateHash(cont);
    final user = {
      'cont': hashedPassword,
      'createdAT': DateTime.now().toString()
    };

    final result =
        await db.update('user_app', user, where: "id=?", whereArgs: [id]);
    return result;
  }

  // Borrar usuarios
  static Future<void> deleteUser(int id) async {
    final db = await SQLHelper.db();
    await db.delete('user_app', where: "id=?", whereArgs: [id]);
  }

  // Metodo para validar login de usuario
  static Future<int?> loginUser(String usuario, String cont) async {
    final db = await SQLHelper.db();
    String hashedPassword = _generateHash(cont);
    SharedPreferences pref = await SharedPreferences.getInstance();

    // Buscar el usuario
    var res = await db.query(
      'user_app',
      where: 'usuario = ?',
      whereArgs: [usuario],
    );

    // Buscar la contraseña
    var resc = await db.query(
      'user_app',
      where: 'cont = ?',
      whereArgs: [hashedPassword],
    );

    if (res.isNotEmpty && resc.isNotEmpty) {
      // Usuario y contraseña correctos
      return res.first['rol'] as int;
    }

    if (res.isEmpty) {
      // El usuario no existe
      pref.setInt('validaLogin', 1); // Indicar que el usuario no fue encontrado
      return null;
    }

    if (resc.isEmpty) {
      // La contraseña es incorrecta
      pref.setInt('validaLogin', 2); // Indicar que la contraseña es incorrecta
      return null;
    }

    return null; // Caso general
  }

  //Recuperar contraseña
  static Future<int?> foundEmail(String correo) async {
    final db = await SQLHelper.db();
    var res = await db.query(
      'user_app',
      where: 'correo = ?',
      whereArgs: [correo],
    );

    if (res.isNotEmpty) {
      return res.first['id'] as int;
    }
    return null; // Si el usuario no se encuentra
  }

  /* Métodos para productos */

  // Agregar productos
  static Future<int> createProduct(String nombreProduct, double precio,
      int cantidadProducto, String imagen) async {
    final db = await SQLHelper.db();
    final productoApp = {
      'nombre_product': nombreProduct,
      'precio': precio,
      'cantidad_producto': cantidadProducto,
      'imagen': imagen,
    };
    final id = await db.insert('producto_app', productoApp,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  static Future<void> agregar(String nombreProduct, double precio, int cantidad,
      String categoria) async {
    final db = await SQLHelper.db();
    final productApp = {
      'nombProduct': nombreProduct,
      'precio': precio,
      'cantidad': cantidad,
      'categoria': categoria,
    };
    final id = await db.insert('product_app', productApp,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    print(id);
  }

  // Actualizar productos
  static Future<int> updateProduct(int id, String nombreProduct, double precio,
      int cantidadProducto, String imagen) async {
    final db = await SQLHelper.db();
    final user = {
      'nombre_product': nombreProduct,
      'precio': precio,
      'cantidad_producto': cantidadProducto,
      'imagen': imagen,
      'createdAT': DateTime.now().toString()
    };

    final result =
        await db.update('producto_app', user, where: "id=?", whereArgs: [id]);
    return result;
  }

  // Eliminar productos
  static Future<void> deleteProduct(int id) async {
    final db = await SQLHelper.db();
    await db.delete('producto_app', where: "id=?", whereArgs: [id]);
  }

  // Mostrar productos
  static Future<List<Map<String, dynamic>>> getAllProduct() async {
    final db = await SQLHelper.db();
    return db.query('producto_app', orderBy: 'id');
  }

  /*Metodos para la tabla productos*/
// Agregar productos
  static Future<int> createCompra(String idUsu, String idPago) async {
    final db = await SQLHelper.db();

    // Insertar la compra en la base de datos
    return await db.insert(
      'compras_usu', // Nombre de la tabla
      {
        'idUsu': idUsu, // id del usuario
        'idPago': idPago, // id del pago de PayPal
      },
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getCompraUsu(String idUsu) async {
    final db = await SQLHelper.db(); // Obtiene la instancia de la base de datos

    // Consultar las compras del usuario
    final compras = await db.query(
      'compras_usu', // Nombre de la tabla de compras
      where: "idUsu = ?", // Filtro por idUsu
      whereArgs: [idUsu],
    );

    // Iterar sobre cada compra y agregar los detalles de PayPal
    for (var compra in compras) {
      String idPago = compra['idPago'] as String;

      // Obtenemos los detalles del pago desde PayPal
      try {
        final paypalDetails = await PayPalService().getPaymentDetails(idPago);
        compra['paypal_details'] =
            paypalDetails; // Añadimos los detalles de PayPal
      } catch (e) {
        print('Error obteniendo detalles de PayPal: $e');
      }
    }

    return compras;
  }

  //huella por usuario 8/12/2024
  // Registrar una huella para un usuario
  static Future<int> registerFingerprint(
      int userId, String fingerprintToken) async {
    final db = await SQLHelper.db();

    final fingerprint = {
      'user_id': userId,
      'fingerprint_token': fingerprintToken, // Guardar el token de la huella
    };

    return await db.insert('user_fingerprints', fingerprint,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
  }

  // Verificar si una huella digital está registrada para un usuario
  static Future<bool> isFingerprintRegistered(
      int userId, String fingerprintToken) async {
    final db = await SQLHelper.db();

    var res = await db.query(
      'user_fingerprints',
      where: 'user_id = ? AND fingerprint_token = ?',
      whereArgs: [userId, fingerprintToken],
    );

    return res.isNotEmpty;
  }

  //otras cosas
  
}
