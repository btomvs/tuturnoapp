import 'package:flutter/material.dart';

// Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Propios
import 'package:tuturnoapp/core/app_colors.dart';
import 'package:tuturnoapp/widgets/input_decoration.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();

  String _rol = 'trabajador'; // valores: trabajador, supervisor, rrhh
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final nombre = _nombreCtrl.text.trim();
      final email = _emailCtrl.text.trim();
      final pass = _passCtrl.text;

      // 1) Crear usuario en Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      // 2) Actualizar displayName
      await cred.user!.updateDisplayName(nombre);

      // 3) Crear/merge perfil en Firestore (doc id = uid)
      final uid = cred.user!.uid;
      final userDoc = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid);

      await userDoc.set({
        'correo': email,
        'estado': 'activo',
        'fechaCreacion': FieldValue.serverTimestamp(),
        'nombre': nombre,
        'rol': _rol,
        'uid': uid, // útil para consultas
      }, SetOptions(merge: true));

      // 4) (Opcional) Verificación por correo (no bloquea el acceso)
      try {
        await cred.user!.sendEmailVerification();
      } catch (_) {}

      // 5) Navegar directo a HOME y limpiar el back stack
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('login', (route) => false);
    } on FirebaseAuthException catch (e) {
      String msg = 'Error de autenticación';
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'El correo ya está registrado.';
          break;
        case 'invalid-email':
          msg = 'Correo no válido.';
          break;
        case 'weak-password':
          msg = 'La contraseña es débil.';
          break;
        case 'operation-not-allowed':
          msg = 'Método de acceso no habilitado.';
          break;
      }
      setState(() => _error = msg);
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
        child: Stack(children: [_fondo(size), _logo(), _formCard(context)]),
      ),
    );
  }

  Widget _formCard(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 280),
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 30),
            width: double.infinity,
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Crear cuenta',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: AppColors.claro),
                ),
                const SizedBox(height: 20),

                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: [
                      // Nombre
                      TextFormField(
                        controller: _nombreCtrl,
                        style: const TextStyle(color: AppColors.claro),
                        textInputAction: TextInputAction.next,
                        decoration: InputDecorations.inputDecoration(
                          hintText: 'Nombre y apellido',
                          labelText: 'Nombre',
                          icono: const Icon(Icons.badge_outlined),
                        ),
                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (s.isEmpty) return 'Ingresa tu nombre';
                          if (s.length < 3) return 'Muy corto';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Correo
                      TextFormField(
                        controller: _emailCtrl,
                        style: const TextStyle(color: AppColors.claro),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecorations.inputDecoration(
                          hintText: 'correo@empresa.com',
                          labelText: 'Correo',
                          icono: const Icon(Icons.alternate_email_outlined),
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
                      const SizedBox(height: 18),

                      // Rol
                      DropdownButtonFormField<String>(
                        style: const TextStyle(color: AppColors.claro),
                        initialValue: _rol,
                        dropdownColor: AppColors.oscuro,
                        decoration: InputDecorations.inputDecoration(
                          hintText: 'Selecciona un rol',
                          labelText: 'Rol',
                          icono: const Icon(Icons.security_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'trabajador',
                            child: Text('Trabajador'),
                          ),
                          DropdownMenuItem(
                            value: 'supervisor',
                            child: Text('Supervisor'),
                          ),
                          DropdownMenuItem(value: 'rrhh', child: Text('RRHH')),
                        ],
                        onChanged: (v) =>
                            setState(() => _rol = v ?? 'trabajador'),
                      ),
                      const SizedBox(height: 18),

                      // Contraseña
                      TextFormField(
                        controller: _passCtrl,
                        style: const TextStyle(color: AppColors.claro),
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecorations.inputDecoration(
                          hintText: '********',
                          labelText: 'Contraseña',
                          icono: const Icon(Icons.lock_outline),
                        ),
                        validator: (v) {
                          final s = v ?? '';
                          if (s.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Confirmación
                      TextFormField(
                        controller: _pass2Ctrl,
                        style: const TextStyle(color: AppColors.claro),
                        obscureText: true,
                        decoration: InputDecorations.inputDecoration(
                          hintText: '********',
                          labelText: 'Confirmar contraseña',
                          icono: const Icon(Icons.lock_reset_outlined),
                        ),
                        validator: (v) {
                          if (v != _passCtrl.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

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
                          onPressed: _loading ? null : _registrar,
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
                          child: Text(_loading ? 'Creando...' : 'Registrar'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                TextButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _logo() {
    return Container(
      margin: const EdgeInsets.only(top: 90),
      width: double.infinity,
      child: Image.asset(
        'assets/images/tuturno_logo_app.png',
        width: 150,
        height: 150,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _fondo(Size size) {
    return Container(
      width: double.infinity,
      height: size.height,
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
