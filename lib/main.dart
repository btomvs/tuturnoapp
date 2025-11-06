// Pantallas
import 'package:flutter/material.dart';
import 'package:tuturnoapp/screens/historial_screen.dart';
import 'package:tuturnoapp/screens/login_screen.dart';
import 'package:tuturnoapp/screens/home_screen.dart';
import 'package:tuturnoapp/screens/turno_screen.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Localización
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 👇 Fuerza español para Intl y carga símbolos de fecha
  Intl.defaultLocale = 'es_ES'; // puedes usar 'es_CL' si prefieres
  await initializeDateFormatting('es_ES');

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TuTurno App',

      // 👇 Español por defecto
      locale: const Locale('es', 'CL'),
      supportedLocales: const [
        Locale('es', 'CL'),
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      routes: {
        'login': (_) => const LoginPage(),
        'home': (_) => const HomeScreen(),
        'turno': (_) => const TurnoScreen(),
        'historial': (_) => const HistorialScreen(),
      },
      initialRoute: 'login',
    );
  }
}
