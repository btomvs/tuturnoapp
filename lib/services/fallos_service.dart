import 'package:cloud_functions/cloud_functions.dart';

enum MotivoFallo { geocerca, biometria, gps, limite }

String _code(MotivoFallo m) {
  switch (m) {
    case MotivoFallo.geocerca:
      return "E_GEOFENCE_OUT";
    case MotivoFallo.biometria:
      return "E_FACE_MISMATCH";
    case MotivoFallo.gps:
      return "E_GPS_ACCURACY";
    case MotivoFallo.limite:
      return "E_DAILY_LIMIT";
  }
}

class FallosService {
  FallosService._();
  static final FallosService _i = FallosService._();
  factory FallosService() => _i;

  final _fn = FirebaseFunctions.instance.httpsCallable('logMarcaFallida');

  Future<void> registrar({
    required String uid,
    required MotivoFallo motivo,
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
    final tsCliente = DateTime.now().toIso8601String();
    await _fn.call({
      "uid": uid,
      "empresaId": empresaId,
      "sucursalId": sucursalId,
      "error_code": _code(motivo),
      "reason": reason,
      "context": {
        if (lat != null) "lat": lat,
        if (lng != null) "lng": lng,
        if (accuracyM != null) "accuracy_m": accuracyM,
        if (distM != null) "dist_m": distM, // geocerca
        if (faceScore != null) "faceScore": faceScore, // biometría
        if (limitPolicy != null) "limit_policy": limitPolicy,
      },
      "tsCliente": tsCliente,
    });
  }
}
