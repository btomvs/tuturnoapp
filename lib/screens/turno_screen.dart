import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:tuturnoapp/core/app_colors.dart';

/// Modelo simple del turno diario
class TurnoDia {
  final DateTime fecha; // solo la fecha (00:00)
  final String? entrada; // ej. "08:00"
  final String? salida; // ej. "17:00"
  final String? estado; // ej. "asignado"
  final TimeOfDay? colacionInicio; // ej. "13:00"
  final int? colacionMinutos; // ej. 60
  final String id; // docId

  TurnoDia({
    required this.id,
    required this.fecha,
    this.entrada,
    this.salida,
    this.estado,
    this.colacionInicio,
    this.colacionMinutos,
  });

  static DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  factory TurnoDia.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime? f;
    if (data['fechaTs'] is Timestamp) {
      f = (data['fechaTs'] as Timestamp).toDate();
    } else if (data['fecha'] is String) {
      try {
        f = DateTime.parse(data['fecha']);
      } catch (_) {}
    }
    f ??= DateTime.now();
    final fecha = _onlyDate(f);

    TimeOfDay? _toTime(String? hhmm) {
      if (hhmm == null || hhmm.isEmpty) return null;
      final parts = hhmm.split(':');
      if (parts.length < 2) return null;
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: h, minute: m);
    }

    return TurnoDia(
      id: doc.id,
      fecha: fecha,
      entrada: data['entrada'] as String?,
      salida: data['salida'] as String?,
      estado: data['estado'] as String?,
      colacionInicio: _toTime(data['colacion_inicio'] as String?),
      colacionMinutos: (data['colacion_minutos'] as num?)?.toInt(),
    );
  }
}

/// Screen: Calendario de turnos diarios (sin card, solo fondo)
class TurnoScreen extends StatefulWidget {
  const TurnoScreen({super.key});

  @override
  State<TurnoScreen> createState() => _TurnoScreenState();
}

class _TurnoScreenState extends State<TurnoScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<TurnoDia>> _turnosByDay = {};

  DateTime _dOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Stream<List<TurnoDia>> _streamTurnosMes(DateTime month) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream<List<TurnoDia>>.empty();

    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1); // exclusivo

    return _db
        .collection('turnos_diarios')
        .where('usuarioId', isEqualTo: uid)
        .where('fechaTs', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('fechaTs', isLessThan: Timestamp.fromDate(end))
        .orderBy('fechaTs', descending: false)
        .snapshots()
        .map((qs) => qs.docs.map((d) => TurnoDia.fromDoc(d)).toList());
  }

  Map<DateTime, List<TurnoDia>> _groupByDay(List<TurnoDia> items) {
    final map = <DateTime, List<TurnoDia>>{};
    for (final t in items) {
      final k = _dOnly(t.fecha);
      map.putIfAbsent(k, () => []).add(t);
    }
    return map;
  }

  List<TurnoDia> _eventsForDay(DateTime day) {
    return _turnosByDay[_dOnly(day)] ?? const [];
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _dOnly(DateTime.now());
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
            // Contenido sin card: colocamos desde debajo del logo
            Positioned.fill(
              top: 240, // despega del logo
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: StreamBuilder<List<TurnoDia>>(
                  stream: _streamTurnosMes(_focusedDay),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Error al cargar turnos: ${snap.error}',
                            style: const TextStyle(color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    final items = snap.data ?? const <TurnoDia>[];
                    _turnosByDay = _groupByDay(items);
                    final seleccionados = _eventsForDay(
                      _selectedDay ?? _focusedDay,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Mis turnos',
                          textAlign: TextAlign.center,
                          style: titleStyle,
                        ),
                        const SizedBox(height: 8),
                        _buildLegend(),
                        const SizedBox(height: 8),
                        _buildCalendar(),
                        const Divider(height: 24, color: AppColors.oscuro),
                        if (seleccionados.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: Text(
                                'No hay turno asignado para este día',
                                style: TextStyle(color: AppColors.oscuro),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.only(top: 4),
                              itemCount: seleccionados.length,
                              itemBuilder: (_, i) =>
                                  _buildTurnoCard(seleccionados[i]),
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

  /// Calendario principal (texto claro para fondo con gradiente)
  Widget _buildCalendar() {
    return TableCalendar<TurnoDia>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2035, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
      eventLoader: _eventsForDay,
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
      onPageChanged: (focusedDay) {
        setState(() => _focusedDay = focusedDay);
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          if (events.isEmpty) return const SizedBox.shrink();
          return Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _buildMarkerDot(events.length),
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

  Widget _buildMarkerDot(int count) {
    return Container(
      width: 22,
      height: 18,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: count > 1
          ? const Text('•', style: TextStyle(color: AppColors.oscuro))
          : const SizedBox.shrink(),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _LegendDot(color: AppColors.primary, label: 'Asignado'),
        SizedBox(width: 16),
        _LegendDot(color: AppColors.secondary, label: 'Seleccionado'),
        SizedBox(width: 16),
        _LegendDot(color: Colors.grey, label: 'Hoy'),
      ],
    );
  }

  Widget _buildTurnoCard(TurnoDia t) {
    String colacionStr = '-';
    if (t.colacionInicio != null && (t.colacionMinutos ?? 0) > 0) {
      final ci = t.colacionInicio!;
      colacionStr =
          '${ci.hour.toString().padLeft(2, '0')}:${ci.minute.toString().padLeft(2, '0')} (${t.colacionMinutos} min)';
    }

    final fechaStr = _formatFechaCorta(t.fecha);

    return Card(
      color: Colors.white.withOpacity(0.35),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.schedule, color: AppColors.primary),
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
                    'Entrada: ${t.entrada ?? "-"}    ·    Salida: ${t.salida ?? "-"}',
                    style: const TextStyle(color: AppColors.oscuro),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Colación: $colacionStr',
                    style: const TextStyle(color: AppColors.oscuro),
                  ),
                  if ((t.estado ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        t.estado!,
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFechaCorta(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    return '$dd/$mm/$yy';
  }

  // ---- Fondo y logo (sin card) ----
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

/// Pequeño ítem de leyenda
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.oscuro)),
      ],
    );
  }
}
