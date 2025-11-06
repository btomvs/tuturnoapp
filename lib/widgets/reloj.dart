// lib/widgets/jornada_reloj.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class JornadaService {
  final _db = FirebaseFirestore.instance;

  String _hoyStr(DateTime now) => DateFormat('yyyy-MM-dd').format(now);
  String _hoyId(String uid, DateTime now) =>
      '$uid-${DateFormat('yyyyMMdd').format(now)}';

  Future<DocumentReference<Map<String, dynamic>>> _ensureDoc(String uid) async {
    final now = DateTime.now();
    final docId = _hoyId(uid, now);
    final ref = _db.collection('jornadas').doc(docId);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'uid': uid,
        'fecha': _hoyStr(now),
        'estado': 'pausada',
        'inicioActual': null,
        'trabajadoSegundos': 0,
        'entradas': 0,
        'salidas': 0,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    }
    return ref;
  }

  Future<void> entrada(String uid) async {
    final ref = await _ensureDoc(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data()!;
      final estado = (data['estado'] as String?) ?? 'pausada';
      final entradasPrev = (data['entradas'] as num?)?.toInt() ?? 0;

      if (estado == 'activa') return;

      final int orden = entradasPrev + 1;
      final String codigo = 'entrada$orden';

      tx.update(ref, {
        'estado': 'activa',
        'inicioActual': FieldValue.serverTimestamp(),
        'entradas': FieldValue.increment(1),
        'actualizadoEn': FieldValue.serverTimestamp(),
      });

      final marcaRef = ref.collection('marcas').doc();
      tx.set(marcaRef, {
        'tipo': 'entrada',
        'orden': orden,
        'codigo': codigo,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> salida(String uid) async {
    final ref = await _ensureDoc(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data()!;
      final estado = (data['estado'] as String?) ?? 'pausada';
      final inicio = (data['inicioActual'] as Timestamp?);
      final salidasPrev = (data['salidas'] as num?)?.toInt() ?? 0;

      if (estado != 'activa' || inicio == null) {
        tx.update(ref, {
          'estado': 'pausada',
          'inicioActual': null,
          'actualizadoEn': FieldValue.serverTimestamp(),
        });
        return;
      }

      final ahora = DateTime.now();
      final stint = ahora.difference(inicio.toDate()).inSeconds;
      final acumuladoPrev = (data['trabajadoSegundos'] as num?)?.toInt() ?? 0;

      final int orden = salidasPrev + 1;
      final String codigo = 'salida$orden';

      tx.update(ref, {
        'estado': 'pausada',
        'inicioActual': null,
        'trabajadoSegundos': acumuladoPrev + (stint > 0 ? stint : 0),
        'salidas': FieldValue.increment(1),
        'actualizadoEn': FieldValue.serverTimestamp(),
      });

      final marcaRef = ref.collection('marcas').doc();
      tx.set(marcaRef, {
        'tipo': 'salida',
        'orden': orden,
        'codigo': codigo,
        'createdAt': FieldValue.serverTimestamp(),
        'stintSegundos': (stint > 0 ? stint : 0),
      });
    });
  }

  Stream<Map<String, dynamic>?> jornadaDeHoyStream(String uid) {
    final docId = _hoyId(uid, DateTime.now());
    return _db
        .collection('jornadas')
        .doc(docId)
        .snapshots()
        .map((s) => s.data());
  }
}

class RelojJornada extends StatefulWidget {
  const RelojJornada({super.key, required this.uid, this.compacto = false});

  final String uid;
  final bool compacto;

  @override
  State<RelojJornada> createState() => _RelojJornadaState();
}

class _RelojJornadaState extends State<RelojJornada> {
  final _srv = JornadaService();

  final ValueNotifier<DateTime> _now = ValueNotifier<DateTime>(DateTime.now());
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _now.value = DateTime.now();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _now.dispose();
    super.dispose();
  }

  String _fmt(int sec) {
    final h = (sec ~/ 3600).toString().padLeft(2, '0');
    final m = ((sec % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final big = TextStyle(
      fontSize: widget.compacto ? 32 : 56,
      fontWeight: FontWeight.w700,
      fontFamily: 'RobotoMono',
      letterSpacing: 1.5,
    );

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _srv.jornadaDeHoyStream(widget.uid),
      builder: (_, snap) {
        String estado = 'pausada';
        Timestamp? inicio;

        if (snap.hasData && snap.data != null) {
          final data = snap.data!;
          estado = (data['estado'] as String?) ?? 'pausada';
          inicio = (data['inicioActual'] as Timestamp?);
        }

        return ValueListenableBuilder<DateTime>(
          valueListenable: _now,
          builder: (_, now, __) {
            int show = 0;

            if (estado == 'activa' && inicio != null) {
              show = now.difference(inicio.toDate()).inSeconds;
              if (show < 0) show = 0;
            } else {
              show = 0; // pausado -> 00:00:00
            }

            return Center(
              child: Text(_fmt(show), style: big, textAlign: TextAlign.center),
            );
          },
        );
      },
    );
  }
}
