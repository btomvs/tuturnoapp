import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:tuturnoapp/core/app_colors.dart';
import 'package:tuturnoapp/widgets/reloj.dart'; // JornadaService

/// =========================
///  GEO-FENCE (top-level)
/// =========================
class _GeoCfg {
  final double lat;
  final double lng;
  final double radiusM; // radio en metros
  final double toleranciaM; // tolerancia adicional
  final bool enabled;

  const _GeoCfg({
    required this.lat,
    required this.lng,
    required this.radiusM,
    required this.toleranciaM,
    required this.enabled,
  });

  static _GeoCfg? fromMap(Map<String, dynamic>? g) {
    if (g == null) return null;
    final enabled = (g['enabled'] == true) || (g['activa'] == true);
    if (!enabled) return null;

    final tipo = (g['tipo'] as String?)?.toLowerCase();
    if (tipo != null && tipo != 'circle') return null; // solo círculo

    // center como GeoPoint o como {lat,lng}
    double? lat;
    double? lng;
    final centerAny = g['center'];
    if (centerAny is GeoPoint) {
      lat = centerAny.latitude;
      lng = centerAny.longitude;
    } else if (centerAny is Map) {
      final m = centerAny.cast<String, dynamic>();
      final latAny = m['lat'] ?? m['latitude'];
      final lngAny = m['lng'] ?? m['longitude'];
      if (latAny is num) lat = latAny.toDouble();
      if (lngAny is num) lng = lngAny.toDouble();
      if (lat == null && latAny is String) lat = double.tryParse(latAny);
      if (lng == null && lngAny is String) lng = double.tryParse(lngAny);
    }

    final rawRadius = (g['radius_m'] ?? g['radius']);
    final rawTol = (g['tolerancia_m'] ?? g['tolerancia'] ?? 0);
    final radius = rawRadius is num ? rawRadius.toDouble() : null;
    final tol = rawTol is num ? rawTol.toDouble() : 0.0;

    if (lat == null || lng == null || radius == null || radius <= 0) {
      return null;
    }

    return _GeoCfg(
      lat: lat,
      lng: lng,
      radiusM: radius,
      toleranciaM: tol,
      enabled: true,
    );
  }

  double distanceTo(double plat, double plng) =>
      Geolocator.distanceBetween(plat, plng, lat, lng);

  bool contains(double plat, double plng) =>
      distanceTo(plat, plng) <= (radiusM + toleranciaM);
}

class BotonEntrada extends StatefulWidget {
  const BotonEntrada({
    super.key,
    this.altura = 55,
    this.separacion = 25,
    this.borderRadius = 55,
    this.labelEntrada = 'Entrada',
    this.labelSalida = 'Salida',
    this.iconEntrada,
    this.iconSalida,
    this.onDone,
  });

  final double altura;
  final double separacion;
  final double borderRadius;

  final String labelEntrada;
  final String labelSalida;
  final IconData? iconEntrada;
  final IconData? iconSalida;

  final void Function(String tipo, bool ok, String? error)? onDone;

  @override
  State<BotonEntrada> createState() => _BotonEntradaState();
}

class _BotonEntradaState extends State<BotonEntrada> {
  final _srv = JornadaService();
  bool _cargando = false;

  // ====== POLÍTICAS LOCALES ======
  static const int _LIMITE_MARCAS_DIA = 4;
  static const double _ACCURACY_MAX_M = 50;

  // ====== Cloud Function opcional para log ======
  final HttpsCallable _fnLogFallo = FirebaseFunctions.instance.httpsCallable(
    'logMarcaFallida',
  );

  // ====== Registro local de fallos en /marcas_fallidas ======
  Future<void> _guardarFalloLocal({
    required String uid,
    required String tipo, // 'entrada' | 'salida'
    required String motivo, // texto visible
    String?
    errorCode, // E_GEOFENCE_OUT | E_GPS_ACCURACY | E_DAILY_LIMIT | E_NO_SHIFT
    Position? pos,
    double? distM,
    int? limitPolicy,
    String? empresaId,
    String? sucursalId,
  }) async {
    try {
      final data = <String, dynamic>{
        'uid': uid,
        'tipo': tipo,
        'motivo': motivo,
        if (errorCode != null) 'error_code': errorCode,
        if (pos != null) 'ubicacion': GeoPoint(pos.latitude, pos.longitude),
        if (pos != null) 'precision': pos.accuracy,
        if (distM != null) 'dist_m': distM,
        if (limitPolicy != null) 'limit_policy': limitPolicy,
        if (empresaId != null) 'empresaId': empresaId,
        if (sucursalId != null) 'sucursalId': sucursalId,
        'creadoEn': FieldValue.serverTimestamp(),
        'fuente': 'mobile',
      };
      await FirebaseFirestore.instance.collection('marcas_fallidas').add(data);
    } catch (e) {
      debugPrint('No se pudo guardar en marcas_fallidas: $e');
    }
  }

  Future<void> _logFallo({
    required String uid,
    required String errorCode,
    String? reason,
    double? lat,
    double? lng,
    double? accuracyM,
    double? distM,
    double? faceScore,
    int? limitPolicy,
    String? empresaId,
    String? sucursalId,
  }) async {
    try {
      final tsCliente = DateTime.now().toIso8601String();
      await _fnLogFallo.call({
        "uid": uid,
        "empresaId": empresaId,
        "sucursalId": sucursalId,
        "error_code": errorCode,
        "reason": reason,
        "context": {
          if (lat != null) "lat": lat,
          if (lng != null) "lng": lng,
          if (accuracyM != null) "accuracy_m": accuracyM,
          if (distM != null) "dist_m": distM,
          if (faceScore != null) "faceScore": faceScore,
          if (limitPolicy != null) "limit_policy": limitPolicy,
        },
        "tsCliente": tsCliente,
      });
    } catch (e) {
      debugPrint('No se pudo registrar marca fallida (CF): $e');
    }
  }

  // ================== Helpers de alerta centrada ==================
  double _snackWidthFor(String msg, {double min = 220, double max = 520}) {
    const textStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);
    final tp = TextPainter(
      text: TextSpan(text: msg, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 3,
    )..layout(maxWidth: max);
    final w = tp.size.width + 32;
    return w.clamp(min, max);
  }

  double _snackHeightFor(String msg) {
    const textStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);
    final tp = TextPainter(
      text: TextSpan(text: msg, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 3,
    )..layout(maxWidth: 520);
    return tp.size.height + 28;
  }

  double _centerBottomOffset(double snackHeight) {
    final h = MediaQuery.of(context).size.height;
    final kb = MediaQuery.of(context).viewInsets.bottom;
    return (h - snackHeight) / 2 + kb;
  }

  void _showSnackCenter(
    String msg, {
    required Color baseColor,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return;

    final screenW = MediaQuery.of(context).size.width;
    final desiredW = _snackWidthFor(msg);
    final height = _snackHeightFor(msg);
    final bottom = _centerBottomOffset(height);
    final sideRaw = (screenW - desiredW) / 2;
    final side = sideRaw.clamp(16.0, screenW * 0.2);
    final Color bgColor = isError ? AppColors.claro : baseColor;
    final Color textColor = isError ? Colors.red.shade700 : Colors.white;
    final BorderSide sideBorder = isError
        ? BorderSide(color: Colors.red.shade600, width: 1.2)
        : BorderSide.none;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(
          side.toDouble(),
          0,
          side.toDouble(),
          bottom,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        backgroundColor: bgColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: sideBorder,
        ),
        content: Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
        ),
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  void _showSuccess(String msg) =>
      _showSnackCenter(msg, baseColor: AppColors.oscuro);
  void _showInfo(String msg) => _showSnackCenter(msg, baseColor: Colors.indigo);
  void _showError(String msg) => _showSnackCenter(
    msg,
    baseColor: Colors.red,
    isError: true,
    duration: const Duration(seconds: 4),
  );

  // ================== Ubicación ==================
  Future<Position> _obtenerPosicion() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'GPS desactivado. Enciende la ubicación del dispositivo.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Permiso de ubicación denegado.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permiso de ubicación denegado permanentemente.');
    }
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 12),
    );
  }

  // ================== GEO-FENCE ==================
  Future<_GeoCfg?> _leerGeocerca(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();
      if (!doc.exists) return null;
      final data = doc.data() ?? <String, dynamic>{};
      final g = (data['geocerca'] as Map?)?.cast<String, dynamic>();
      return _GeoCfg.fromMap(g);
    } catch (e) {
      debugPrint('No se pudo leer geocerca: $e');
      return null; // si falla la lectura, no bloqueamos localmente
    }
  }

  // ================== Perfil ==================
  Future<String> _obtenerNombreSeguro(User user) async {
    String nombre = (user.displayName ?? '').trim();
    if (nombre.isEmpty) nombre = 'Usuario';

    try {
      final q = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (q.docs.isNotEmpty) {
        final data = q.docs.first.data();
        final n = (data['nombres'] as String? ?? '').trim();
        final a = (data['apellido'] as String? ?? '').trim();
        final full = [n, a].where((s) => s.isNotEmpty).join(' ');
        if (full.isNotEmpty) nombre = full;
      }
    } catch (e) {
      debugPrint('Aviso: lectura de "usuarios" falló: $e');
      _showInfo('No se pudo leer tu perfil. Usaremos un nombre genérico.');
    }
    return nombre;
  }

  // ================== Reglas locales previas ==================
  Future<int> _contarMarcasHoy(String uid) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final qs = await FirebaseFirestore.instance
        .collection('marcaje')
        .where('uid', isEqualTo: uid)
        .where('creadoEn', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('creadoEn', isLessThan: Timestamp.fromDate(end))
        .get();
    return qs.size;
  }

  // ======= ¿Está en turno hoy? (turnos_diarios con usuarioId + fechaTs) =======
  Future<bool> _estaEnTurnoHoy(String uid) async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));
      final qs = await FirebaseFirestore.instance
          .collection('turnos_diarios')
          .where('usuarioId', isEqualTo: uid)
          .where('fechaTs', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('fechaTs', isLessThan: Timestamp.fromDate(end))
          .limit(1)
          .get();
      return qs.docs.isNotEmpty;
    } catch (e) {
      debugPrint('No se pudo verificar turno: $e');
      // Si falla la lectura, por seguridad bloqueamos
      return false;
    }
  }

  Future<void> _registrar(String tipo) async {
    if (_cargando) return;
    setState(() => _cargando = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No autenticado.');

      // ===== -1) Debe estar en turno =====
      final enTurno = await _estaEnTurnoHoy(user.uid);
      if (!enTurno) {
        await _guardarFalloLocal(
          uid: user.uid,
          tipo: tipo,
          motivo: 'No se encuentra en turno',
          errorCode: 'E_NO_SHIFT',
        );
        _showError('No tienes un turno asignado para hoy.');
        widget.onDone?.call(tipo, false, 'E_NO_SHIFT');
        return;
      }

      final pos = await _obtenerPosicion();
      final nombre = await _obtenerNombreSeguro(user);

      // ===== 0) LÍMITE DIARIO =====
      final marcasHoy = await _contarMarcasHoy(user.uid);
      if (marcasHoy >= _LIMITE_MARCAS_DIA) {
        await _guardarFalloLocal(
          uid: user.uid,
          tipo: tipo,
          motivo: 'Límite diario de marcas excedido',
          errorCode: 'E_DAILY_LIMIT',
          limitPolicy: _LIMITE_MARCAS_DIA,
          pos: pos,
        );
        await _logFallo(
          uid: user.uid,
          errorCode: 'E_DAILY_LIMIT',
          reason: 'Se superó el límite diario',
          limitPolicy: _LIMITE_MARCAS_DIA,
        );
        _showError('Límite diario de marcas excedido.');
        widget.onDone?.call(tipo, false, 'E_DAILY_LIMIT');
        return;
      }

      // ===== 1) GPS PRECISIÓN =====
      if (pos.accuracy > _ACCURACY_MAX_M) {
        await _guardarFalloLocal(
          uid: user.uid,
          tipo: tipo,
          motivo: 'Precisión GPS insuficiente',
          errorCode: 'E_GPS_ACCURACY',
          pos: pos,
        );
        await _logFallo(
          uid: user.uid,
          errorCode: 'E_GPS_ACCURACY',
          reason: 'accuracy > $_ACCURACY_MAX_M m',
          lat: pos.latitude,
          lng: pos.longitude,
          accuracyM: pos.accuracy,
        );
        _showError(
          'Señal GPS débil (precisión ${pos.accuracy.toStringAsFixed(0)} m).',
        );
        widget.onDone?.call(tipo, false, 'E_GPS_ACCURACY');
        return;
      }

      // ===== 2) GEOFENCE =====
      final geo = await _leerGeocerca(user.uid);
      if (geo != null && geo.enabled) {
        final distM = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          geo.lat,
          geo.lng,
        );
        final maxM = geo.radiusM + geo.toleranciaM;

        if (distM > maxM) {
          await _guardarFalloLocal(
            uid: user.uid,
            tipo: tipo,
            motivo: 'Fuera de geocerca',
            errorCode: 'E_GEOFENCE_OUT',
            pos: pos,
            distM: distM,
          );
          await _logFallo(
            uid: user.uid,
            errorCode: 'E_GEOFENCE_OUT',
            reason:
                'Fuera de geocerca (dist=${distM.toStringAsFixed(1)}m > ${maxM.toStringAsFixed(0)}m)',
            lat: pos.latitude,
            lng: pos.longitude,
            accuracyM: pos.accuracy,
            distM: distM,
          );
          _showError(
            'Estás fuera del perímetro permitido para marcar.\n'
            'Distancia ${distM.toStringAsFixed(0)} m (máx ${maxM.toStringAsFixed(0)} m).',
          );
          widget.onDone?.call(tipo, false, 'E_GEOFENCE_OUT');
          return;
        }
      }

      // ===== 3) Escritura en MARCAJE =====
      try {
        await FirebaseFirestore.instance.collection('marcaje').add({
          'uid': user.uid,
          'nombre': nombre,
          'tipo': tipo, // 'entrada' | 'salida'
          'ubicacion': GeoPoint(pos.latitude, pos.longitude),
          'precision': pos.accuracy,
          'creadoEn': FieldValue.serverTimestamp(),
          'fuente': 'mobile',
        });
      } catch (e) {
        _showError('Permiso denegado al escribir "marcaje".');
        rethrow;
      }

      // ===== 4) Escritura en JORNADAS =====
      try {
        if (tipo == 'entrada') {
          await _srv.entrada(user.uid);
        } else {
          await _srv.salida(user.uid);
        }
      } catch (e) {
        _showError('Permiso denegado en "jornadas".');
        rethrow;
      }

      _showSuccess('¡Tu marca de $tipo ha sido exitosa!');
      widget.onDone?.call(tipo, true, null);
    } catch (e) {
      _showError('Error al marcar $tipo: $e');
      widget.onDone?.call(tipo, false, e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ================== UI ==================
  Widget _buildFilled(
    String label,
    IconData? icon,
    VoidCallback onTap, {
    required Color bg,
    required Color fg,
  }) {
    final child = _cargando
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : (icon == null
              ? Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ));

    return SizedBox(
      height: widget.altura,
      child: FilledButton(
        onPressed: _cargando ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _buildFilled(
            widget.labelEntrada,
            widget.iconEntrada,
            () => _registrar('entrada'),
            bg: AppColors.secondary,
            fg: AppColors.claro,
          ),
        ),
        SizedBox(width: widget.separacion),
        Expanded(
          child: _buildFilled(
            widget.labelSalida,
            widget.iconSalida,
            () => _registrar('salida'),
            bg: Colors.deepOrange,
            fg: scheme.onSecondaryContainer,
          ),
        ),
      ],
    );
  }
}
