import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:tuturnoapp/core/app_colors.dart';

/// ===== Jornada (doc padre) =====
class JornadaDoc {
  final String id; // ej: "<uid>-20251106"
  final String uid;
  final DateTime fecha; // 00:00 local
  JornadaDoc({required this.id, required this.uid, required this.fecha});

  static DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  factory JornadaDoc.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final x = d.data() ?? {};
    // fecha es string "YYYY-MM-DD" en tu BD
    DateTime f;
    if (x['fecha'] is String) {
      try {
        f = DateTime.parse(x['fecha']);
      } catch (_) {
        f = DateTime.now();
      }
    } else {
      f = DateTime.now();
    }
    return JornadaDoc(id: d.id, uid: x['uid'] ?? '', fecha: _onlyDate(f));
  }
}

/// ===== Marca (subdoc) =====
class Marca {
  final String id;
  final String tipo; // "entrada" | "salida"
  final int? orden; // 1 | 2
  final String? codigo; // "entrada1"|"salida2"... (opcional)
  final DateTime ts;

  Marca({
    required this.id,
    required this.tipo,
    required this.ts,
    this.orden,
    this.codigo,
  });

  factory Marca.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final x = d.data() ?? {};
    DateTime ts;
    if (x['createdAt'] is Timestamp) {
      ts = (x['createdAt'] as Timestamp).toDate();
    } else if (x['ts_server'] is Timestamp) {
      ts = (x['ts_server'] as Timestamp).toDate();
    } else {
      ts = DateTime.now();
    }
    return Marca(
      id: d.id,
      tipo: (x['tipo'] as String? ?? '').toLowerCase(),
      orden: (x['orden'] as num?)?.toInt(),
      codigo: x['codigo'] as String?,
      ts: ts,
    );
  }
}

/// ===== Screen =====
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _selectedDay = _onlyDate(DateTime.now());
  }

  /// Stream de jornadas del mes (usa uid + rango por fecha string)
  Stream<List<JornadaDoc>> _streamJornadasMes(DateTime month) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream<List<JornadaDoc>>.empty();

    final startStr = _ymd(DateTime(month.year, month.month, 1));
    final endStr = _ymd(DateTime(month.year, month.month + 1, 1));

    return _db
        .collection('jornadas')
        .where('uid', isEqualTo: uid)
        .where('fecha', isGreaterThanOrEqualTo: startStr)
        .where('fecha', isLessThan: endStr)
        .orderBy('fecha')
        .snapshots()
        .map((qs) => qs.docs.map((d) => JornadaDoc.fromDoc(d)).toList());
  }

  /// Stream de marcas de la jornada seleccionada (si existe)
  Stream<List<Marca>> _streamMarcasDeJornada(String jornadaId) {
    return _db
        .collection('jornadas')
        .doc(jornadaId)
        .collection('marcas')
        .orderBy('createdAt') // en tu BD existe este campo
        .snapshots()
        .map((qs) => qs.docs.map((d) => Marca.fromDoc(d)).toList());
  }

  /// Busca la jornada del día seleccionado dentro del mes cargado
  JornadaDoc? _jornadaDelDia(List<JornadaDoc> jornadas, DateTime day) {
    final d = _onlyDate(day);
    for (final j in jornadas) {
      if (_onlyDate(j.fecha) == d) return j;
    }
    return null;
  }

  /// Calcula primera entrada y última salida (sin descontar colación)
  (DateTime?, DateTime?, Duration?) _calcularResumen(List<Marca> marcas) {
    if (marcas.isEmpty) return (null, null, null);

    // Orden cronológico por createdAt
    marcas.sort((a, b) => a.ts.compareTo(b.ts));

    DateTime? primeraEntrada;
    DateTime? ultimaSalida;

    // Preferencias: entrada1/salida2 si están; si no, primera/última genérica
    DateTime? entrada1;
    DateTime? salida2;

    for (final m in marcas) {
      if (m.tipo == 'entrada') {
        if (m.orden == 1 || m.codigo == 'entrada1') {
          entrada1 ??= m.ts;
        }
        primeraEntrada ??= m.ts; // primera entrada genérica
      } else if (m.tipo == 'salida') {
        if (m.orden == 2 || m.codigo == 'salida2') {
          salida2 = m.ts; // la última iteración quedará como la última salida2
        }
        ultimaSalida = m.ts; // va quedando la última salida genérica
      }
    }

    final inicio = entrada1 ?? primeraEntrada;
    final fin = salida2 ?? ultimaSalida;

    Duration? total;
    if (inicio != null && fin != null && fin.isAfter(inicio)) {
      total = fin.difference(inicio); // SIN descontar colación (Chile)
    }
    return (inicio, fin, total);
  }

  String _ymd(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  String _fmtFechaCorta(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    return '$dd/$mm/$yy';
  }

  String _fmtHora(DateTime? dt) {
    if (dt == null) return '-';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _fmtDur(Duration? d) {
    if (d == null) return '-';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
      color: AppColors.oscuro,
      fontWeight: FontWeight.w700,
    );

    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          children: [
            _fondo(MediaQuery.of(context).size),
            _logo(),
            Positioned.fill(
              top: 240,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: StreamBuilder<List<JornadaDoc>>(
                  stream: _streamJornadasMes(_focusedDay),
                  builder: (context, jsnap) {
                    if (jsnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (jsnap.hasError) {
                      return _err('Error al cargar jornadas: ${jsnap.error}');
                    }

                    final jornadas = jsnap.data ?? const <JornadaDoc>[];
                    final jSel = _jornadaDelDia(
                      jornadas,
                      _selectedDay ?? _focusedDay,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Historial de marcas',
                          textAlign: TextAlign.center,
                          style: titleStyle,
                        ),
                        const SizedBox(height: 8),
                        _buildCalendar(jornadas),
                        const Divider(height: 24, color: AppColors.oscuro),

                        if (jSel == null)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: Text(
                                'Sin marcas para este día',
                                style: TextStyle(color: AppColors.oscuro),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: StreamBuilder<List<Marca>>(
                              stream: _streamMarcasDeJornada(jSel.id),
                              builder: (context, msnap) {
                                if (msnap.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (msnap.hasError) {
                                  return _err(
                                    'Error al cargar marcas: ${msnap.error}',
                                  );
                                }

                                final marcas = msnap.data ?? const <Marca>[];
                                final (entrada1, salida2, total) =
                                    _calcularResumen(marcas);

                                return _buildResumenCard(
                                  fecha: jSel.fecha,
                                  marcas: marcas,
                                  entrada1: entrada1,
                                  salida2: salida2,
                                  total: total,
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(List<JornadaDoc> jornadas) {
    final setDias = jornadas.map((j) => _onlyDate(j.fecha)).toSet();

    List<dynamic> _eventsFor(DateTime day) =>
        setDias.contains(_onlyDate(day)) ? [1] : [];

    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2035, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
      eventLoader: _eventsFor,
      startingDayOfWeek: StartingDayOfWeek.monday,
      headerStyle: const HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: TextStyle(
          color: AppColors.oscuro,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.oscuro),
        rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.oscuro),
      ),
      calendarStyle: CalendarStyle(
        defaultTextStyle: const TextStyle(color: AppColors.oscuro),
        weekendTextStyle: const TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.w600,
        ),
        outsideTextStyle: TextStyle(color: AppColors.oscuro.withOpacity(0.45)),
        todayDecoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.25),
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: AppColors.secondary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(
          color: AppColors.oscuro,
          fontWeight: FontWeight.w700,
        ),
        markerDecoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        tablePadding: const EdgeInsets.symmetric(horizontal: 6),
        canMarkersOverflow: true,
      ),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          if (events.isEmpty) return const SizedBox.shrink();
          return Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _markerDot(),
            ),
          );
        },
        dowBuilder: (context, day) => Center(
          child: Text(
            ['L', 'M', 'M', 'J', 'V', 'S', 'D'][day.weekday - 1],
            style: const TextStyle(
              color: AppColors.oscuro,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _markerDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildResumenCard({
    required DateTime fecha,
    required List<Marca> marcas,
    required DateTime? entrada1,
    required DateTime? salida2,
    required Duration? total,
  }) {
    // Busca marcas por orden/codigo para mostrar hh:mm
    DateTime? _hora(String tipo, int orden) {
      for (final m in marcas) {
        if (m.tipo == tipo &&
            (m.orden == orden || m.codigo == '${tipo}${orden}')) {
          return m.ts;
        }
      }
      return null;
    }

    final fechaStr = _fmtFechaCorta(fecha);

    // Clonar + ordenar para no mutar la lista original
    final sorted = [...marcas]..sort((a, b) => a.ts.compareTo(b.ts));

    return Card(
      color: Colors.white.withOpacity(0.35),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.work_history,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fechaStr,
                        style: const TextStyle(
                          color: AppColors.oscuro,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Entrada1: ${_fmtHora(_hora("entrada", 1))}   ·   Salida1: ${_fmtHora(_hora("salida", 1))}',
                        style: const TextStyle(color: AppColors.oscuro),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Entrada2: ${_fmtHora(_hora("entrada", 2))}   ·   Salida2: ${_fmtHora(_hora("salida", 2))}',
                        style: const TextStyle(color: AppColors.oscuro),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.16),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'Horas trabajadas: ${_fmtDur(total)}',
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Marcas del día:',
              style: TextStyle(
                color: AppColors.oscuro,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            // ⬇️ FIX: lista ordenada + map<Widget>() + toList()
            ...sorted
                .map<Widget>(
                  (m) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          m.tipo == 'entrada' ? Icons.login : Icons.logout,
                          size: 18,
                          color: AppColors.oscuro,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${m.codigo ?? '${m.tipo}${m.orden ?? ''}'} — ${_fmtHora(m.ts)}',
                          style: const TextStyle(color: AppColors.oscuro),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _err(String msg) => Center(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        msg,
        style: const TextStyle(color: Colors.redAccent),
        textAlign: TextAlign.center,
      ),
    ),
  );

  // ---- Fondo y logo (como tu TurnoScreen) ----
  Widget _logo() {
    return Container(
      margin: const EdgeInsets.only(top: 50),
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
