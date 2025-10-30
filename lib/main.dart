//Pantallas
import 'package:flutter/material.dart';
import 'package:tuturnoapp/screens/login_page.dart';
import 'package:tuturnoapp/screens/home_screen.dart';

//Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:tuturnoapp/screens/iconos.dart';
import 'package:tuturnoapp/screens/register_page.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TuTurno App',
      routes: {
        'registro': (_) => const RegisterPage(),
        'login': (_) => const LoginPage(),
        'home': (_) => const HomeScreen(),
        'iconos': (_) => const IconosScreen(),
      },
      initialRoute: 'login',
    );
  }
}
