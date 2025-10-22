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
  final _usuarioCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _passwordCtrl.dispose();
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
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _usuarioCtrl.text.trim(),
        password: _passwordCtrl.text
      );

    

    final uid = cred.user!.uid;
    final snap = await FirebaseFirestore.instance
    .collection('usuarios')
    .doc(uid)
    .get();

    if (!snap.exists){
      await FirebaseAuth.instance.signOut();
      throw Exception('Cuenta no registrada, consulta con tu administrador.');
    }

    final data = snap.data()!;
    final estado = (data['estado'] ?? '').toString().toLowerCase();
    if (estado != 'activo'){
      await FirebaseAuth.instance.signOut();
      throw Exception('Tu cuenta esta inactiva. Contacta a RRHH.');
    }

    final rol = (data['role'] ?? '').toString().toLowerCase();
    const rolesPermitidos = ['trabajador', 'supervisor', 'rrhh'];
    if (!rolesPermitidos.contains(rol)) {
      await FirebaseAuth.instance.signOut();
      throw Exception('Tu rol no tiene acceso a la app móvil.');
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, 'home');
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
                        controller: _usuarioCtrl,
                        style: const TextStyle(color: AppColors.claro),
                        autocorrect: false,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecorations.inputDecoration(
                          hintText: 'DNI o Correo electronico',
                          labelText: 'Usuario',
                          icono: Icon(Icons.person_2_outlined),
                        ),
                        //Limpiar cuando no es correo
                        onChanged: (txt) {
                          final looksLikeRut = RegExp(
                            r'^[0-9.\-\sKk]+$',
                          ).hasMatch(txt);
                          if (!looksLikeRut) {
                            return;
                          }
                          //DNI sin digito verificador
                          final cleaned = txt
                              .split('-')
                              .first
                              .replaceAll(RegExp(r'\D'), '');
                          if (cleaned != txt) {
                            _usuarioCtrl.value = TextEditingValue(
                              text: cleaned,
                              selection: TextSelection.collapsed(
                                offset: cleaned.length,
                              ),
                            );
                          }
                        },
                        validator: (value) {
                          final v = (value ?? '').trim();
                          if (v.isEmpty) return 'Este campo es obligatorio';
                          //Email
                          const emailPattern =
                              r'^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@'
                              r'((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|'
                              r'(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                          final isEmail = RegExp(emailPattern).hasMatch(v);
                          // DNI
                          final rutBody = v
                              .split('-')
                              .first
                              .replaceAll(RegExp(r'\D'), '');
                          final isRutBody = RegExp(
                            r'^\d{6,9}$',
                          ).hasMatch(rutBody);
                          return (isEmail || isRutBody)
                              ? null
                              : 'Ingresa un correo válido o un DNI';
                        },
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        style: const TextStyle(color: AppColors.claro),
                        obscureText: true,
                        autocorrect: false,
                        decoration: InputDecorations.inputDecoration(
                          hintText: '********',
                          labelText: 'Contraseña',
                          icono: Icon(Icons.lock_outline),
                        ),
                        validator: (value) {
                          return (value != null && value.length >= 4)
                              ? null
                              : 'Ingrese al menos 4 caracteres';
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
                            horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(_loading ? 'Verificando...' : 'Ingresar'),
                        ),
                      )


                      // MaterialButton(
                      //   shape: RoundedRectangleBorder(
                      //     borderRadius: BorderRadiusGeometry.circular(10),
                      //   ),
                      //   disabledColor: Colors.grey,
                      //   color: AppColors.primary,
                      //   child: Container(
                      //     padding: EdgeInsets.symmetric(
                      //       horizontal: 20,
                      //       vertical: 10,
                      //     ),
                      //     child: Text(
                      //       'Ingresar',
                      //       style: TextStyle(color: AppColors.oscuro),
                      //     ),
                      //   ),
                      //   onPressed: () {
                      //     Navigator.pushReplacementNamed(context, 'home');
                      //   },
                      // ),
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
