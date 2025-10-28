import 'package:flutter/material.dart';

//Pantallas

import 'package:tuturnoapp/screens/login_page.dart';
import 'package:tuturnoapp/screens/home_screen.dart';
import 'package:tuturnoapp/screens/pruebaaas.dart';

//Firebase

import 'package:firebase_core/firebase_core.dart';
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
        //'registro': (_) => const RegistroScreen(),
        'login': (_) => const LoginPage(),
        'person': (_) => const PersonIconsGallery(),
        'home': (_) => const HomeScreen(),
      },
      initialRoute: 'login',
    );
  }
}
