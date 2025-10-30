import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tuturnoapp/core/app_colors.dart';

class Bienvenido extends StatelessWidget {
  const Bienvenido({super.key});

  Future<String> _getNombre() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'Usuario';

    final snap = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();

    final data = snap.data();
    final nombres = (data?['nombres'] as String?)?.trim() ?? '';
    if (nombres.isEmpty) return 'Usuario';
    return nombres.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getNombre(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Text('Cargando...');
        }
        final nombre = snap.data ?? 'Usuario';
        return Text(
          '¡Bienvenido, $nombre!',
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w600,
            color: AppColors.oscuro,
          ),
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
