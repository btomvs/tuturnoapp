import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:tuturnoapp/core/app_colors.dart';
import 'package:tuturnoapp/services/biometria_service.dart';

/// Pantalla de verificación biométrica.
/// - Muestra la cámara frontal.
/// - Captura una foto, recorta el rostro, genera embedding y compara contra Firestore.
/// - Si verifica, ejecuta onVerified() y hace pop(true). Si falla, muestra motivo.
class VerificarBiometriaScreen extends StatefulWidget {
  final Future<void> Function() onVerified;

  const VerificarBiometriaScreen({super.key, required this.onVerified});

  @override
  State<VerificarBiometriaScreen> createState() =>
      _VerificarBiometriaScreenState();
}

class _VerificarBiometriaScreenState extends State<VerificarBiometriaScreen> {
  final _bio = BiometriaService();

  CameraController? _cam;
  bool _busy = true;
  String _msg = 'Inicializando…';
  List<double>? _refEmbedding;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // 1) Verificar enrolamiento
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _busy = true;
          _msg = 'No autenticado.';
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();
      final emb = (doc.data()?['biometria']?['embedding'] as List?)
          ?.map((e) => (e as num).toDouble())
          .toList();
      if (emb == null || emb.length != 128) {
        setState(() {
          _busy = true;
          _msg = 'No tienes enrolamiento biométrico.';
        });
        return;
      }
      _refEmbedding = emb;

      // 2) Cámara frontal
      final cams = await availableCameras();
      final front = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );
      _cam = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cam!.initialize();

      // 3) Modelo
      await _bio.loadModel();

      setState(() {
        _busy = false;
        _msg = 'Acomoda tu rostro dentro del recuadro y presiona VERIFICAR';
      });
    } catch (e) {
      setState(() {
        _busy = true;
        _msg = 'Error: $e';
      });
    }
  }

  @override
  void dispose() {
    _cam?.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _verificar() async {
    if (_cam == null || !_cam!.value.isInitialized || _refEmbedding == null)
      return;

    setState(() {
      _busy = true;
      _msg = 'Capturando…';
    });

    try {
      final shot = await _cam!.takePicture();
      final bytes = await shot.readAsBytes();

      // recorte de rostro y resize 112x112
      final face = await _bio.cropFaceFromJpeg(bytes);
      if (face == null) {
        _toast(
          'No se detectó rostro. Asegúrate de estar centrado y con buena luz.',
          error: true,
        );
        setState(() {
          _busy = false;
          _msg = 'Intenta nuevamente.';
        });
        return;
      }

      // embedding + similitud
      final emb = _bio.embed(face);
      final cos = _bio.cosineSimilarity(emb, _refEmbedding!);
      final ok = _bio.isMatch(cos, threshold: 0.62);

      if (!mounted) return;
      if (ok) {
        _toast('Verificado ✔  (similitud ${cos.toStringAsFixed(3)})');
        await widget.onVerified();
        Navigator.of(context).pop(true);
      } else {
        _toast(
          'No coincide ❌  (similitud ${cos.toStringAsFixed(3)})',
          error: true,
        );
        setState(() {
          _busy = false;
          _msg = 'Ajusta luz/encuadre y vuelve a intentar.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      _toast('Error: $e', error: true);
      setState(() {
        _busy = false;
        _msg = 'Intenta nuevamente.';
      });
    }
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Colors.red.shade600 : AppColors.oscuro,
        content: Text(
          msg,
          style: TextStyle(
            color: error ? Colors.white : AppColors.claro,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.claro,
      appBar: AppBar(
        backgroundColor: AppColors.oscuro,
        foregroundColor: AppColors.claro,
        title: const Text('Verificar rostro'),
        elevation: 0,
      ),
      body: _busy
          ? _BuildCenteredMessage(message: _msg)
          : Column(
              children: [
                // Vista de cámara con un marco suave para guiar el rostro
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AspectRatio(
                        aspectRatio: _cam!.value.aspectRatio,
                        child: CameraPreview(_cam!),
                      ),
                      // Overlay de guía
                      IgnorePointer(
                        child: Center(
                          child: Container(
                            width: 240,
                            height: 320,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: AppColors.secondary.withOpacity(0.9),
                                width: 3,
                              ),
                              color: Colors.black.withOpacity(0.05),
                            ),
                          ),
                        ),
                      ),
                      // Mensaje superior
                      Positioned(
                        top: 12,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _msg,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Barra de acciones
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  decoration: BoxDecoration(
                    color: AppColors.claro,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 14,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _verificar,
                          icon: const Icon(Icons.face_retouching_natural),
                          label: const Text('Verificar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: AppColors.claro,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(false),
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Cancelar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.oscuro,
                            side: BorderSide(
                              color: AppColors.oscuro.withOpacity(0.25),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// Mensaje centrado consistente con la paleta
class _BuildCenteredMessage extends StatelessWidget {
  final String message;
  const _BuildCenteredMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.oscuro.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.oscuro.withOpacity(0.12)),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.oscuro,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
