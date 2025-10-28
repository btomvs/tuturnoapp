import 'package:flutter/material.dart';

//Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//Propios
import 'package:tuturnoapp/core/app_colors.dart';
import 'package:tuturnoapp/widgets/input_decoration.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  //Logica del Login
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      //Login con Email y Contraseña
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      final uid = cred.user!.uid;
      final snap = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (!snap.exists) {
        // Si el doc no existe, lo creamos con mínimos (opcional).
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
          'nombre': cred.user!.email,
          'email': cred.user!.email,
          'estado': 'activo',
          'rol': 'trabajador',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      final data =
          (await FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(uid)
                  .get())
              .data()!;

      final estado = (data['estado'] ?? '').toString().toLowerCase();
      if (estado != 'activo') {
        await FirebaseAuth.instance.signOut();
        throw Exception('Tu cuenta esta inactiva. Contacta a RRHH.');
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, 'home');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Error de autenticación');
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [fondo(size), logoLogin(), cuadroLogin(context)],
        ),
      ),
    );
  }

  SingleChildScrollView cuadroLogin(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 250),
          Container(
            padding: EdgeInsets.all(20),
            margin: EdgeInsets.symmetric(horizontal: 30),
            width: double.infinity,
            //height: 400,
            decoration: BoxDecoration(
              color: AppColors.oscuro,
              borderRadius: BorderRadius.circular(25),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 5),
                Text(
                  'Iniciar Sesión',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: AppColors.claro),
                ),
                const SizedBox(height: 30),
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailCtrl,
                        style: const TextStyle(color: AppColors.claro),
                        autocorrect: false,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecorations.inputDecoration(
                          hintText: 'Correo electronico',
                          labelText: 'Usuario',
                          icono: Icon(Icons.person_2_outlined),
                        ),

                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (s.isEmpty) return 'Ingresa tu correo';
                          final ok = RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          ).hasMatch(s);
                          return ok ? null : 'Correo no válido';
                        },
                      ),

                      const SizedBox(height: 30),

                      TextFormField(
                        controller: _passCtrl,
                        style: const TextStyle(color: AppColors.claro),
                        obscureText: true,
                        autocorrect: false,
                        decoration: InputDecorations.inputDecoration(
                          hintText: '********',
                          labelText: 'Contraseña',
                          icono: Icon(Icons.lock_outline),
                        ),
                        validator: (value) {
                          return (value != null && value.length >= 6)
                              ? null
                              : 'Ingrese al menos 6 caracteres';
                        },
                      ),
                      const SizedBox(height: 30),

                      if (_error != null)
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.oscuro,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(_loading ? 'Verificando...' : 'Ingresar'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                Text(
                  'Cambiar Contraseña',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.claro,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container logoLogin() {
    return Container(
      margin: EdgeInsets.only(top: 50),
      width: double.infinity,
      child: Image.asset(
        'assets/images/tuturno_logo_app.png',
        width: 150,
        height: 150,
        fit: BoxFit.contain,
      ),
    );
  }

  Container fondo(Size size) {
    return Container(
      width: double.infinity,
      height: size.height * 1,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.claro],
        ),
      ),
    );
  }
}
