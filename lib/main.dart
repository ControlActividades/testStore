import 'package:flutter/material.dart';
import 'package:aplicacion2/login_screen.dart';
import 'package:aplicacion2/services/idle_timeout_service.dart';
import 'package:provider/provider.dart';
import 'package:aplicacion2/provider/theme_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final IdleTimeoutService idleTimeoutService =
        IdleTimeoutService(navigatorKey);

    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Builder(
        builder: (context) {
          final themeProvider = Provider.of<ThemeProvider>(context);

          // Iniciar el temporizador de inactividad
          idleTimeoutService.startIdleTimer(context);

          return MaterialApp(
            navigatorKey: navigatorKey,
            theme: themeProvider.currentTheme,
            home: GestureDetector(
              onTap: () {
                idleTimeoutService.userInteracted();
              },
              onPanUpdate: (_) {
                idleTimeoutService.userInteracted();
              },
              child: LoginScreen(),
            ),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
