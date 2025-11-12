// lib/widgets/enrolar_trabajador_screen.dart
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imglib;

import 'package:tuturnoapp/core/app_colors.dart';
import 'package:tuturnoapp/services/biometria_service.dart';

class EnrolarTrabajadorScreen extends StatefulWidget {
  const EnrolarTrabajadorScreen({super.key});

  @override
  State<EnrolarTrabajadorScreen> createState() =>
      _EnrolarTrabajadorScreenState();
}

class _EnrolarTrabajadorScreenState extends State<EnrolarTrabajadorScreen> {
  final _bio = BiometriaService();
  CameraController? _cam;
  bool _busy = true;
  String _msg = 'Inicializando cámara…';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
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
      await _bio.loadModel();
      setState(() {
        _busy = false;
        _msg = 'Centra tu rostro y presiona ENROLAR';
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

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Colors.red.shade600 : AppColors.oscuro,
        content: Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: error ? Colors.white : AppColors.claro,
            fontWeight: FontWeight.w700,
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _enrolar() async {
    if (_cam == null || !_cam!.value.isInitialized) return;

    setState(() {
      _busy = true;
      _msg = 'Capturando…';
    });

    try {
      final shot = await _cam!.takePicture();
      final bytes = await shot.readAsBytes();

      final face = await _bio.cropFaceFromJpeg(bytes);
      if (face == null) {
        _toast('No se detectó rostro. Mejora la luz/encuadre.', error: true);
        setState(() {
          _busy = false;
          _msg = 'Intenta nuevamente';
        });
        return;
      }

      // Calcula embedding
      final emb = _bio.embed(face);

      // Sube foto recortada como referencia
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final ref = FirebaseStorage.instance.ref('biometria/$uid/ref.jpg');
      final jpg = imglib.encodeJpg(face, quality: 92);
      await ref.putData(Uint8List.fromList(jpg));
      final url = await ref.getDownloadURL();

      // Guarda embedding en usuarios/{uid}
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'biometria': {
          'embedding': emb,
          'version': 1,
          'model': 'mobilefacenet_112',
          'fotoRef': url,
          'createdAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      _toast('¡Enrolamiento exitoso!');
      if (!mounted) return;
      Navigator.of(context).pop(true); // <- devolver éxito al caller
    } catch (e) {
      _toast('Error: $e', error: true);
      if (mounted) {
        setState(() {
          _busy = false;
          _msg = 'Intenta nuevamente';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.claro,
      appBar: AppBar(
        backgroundColor: AppColors.oscuro,
        foregroundColor: AppColors.claro,
        title: const Text('Enrolar rostro'),
        elevation: 0,
      ),
      body: _busy
          ? _CenteredMessage(message: _msg)
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AspectRatio(
                        aspectRatio: _cam!.value.aspectRatio,
                        child: CameraPreview(_cam!),
                      ),
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
                          onPressed: _enrolar,
                          icon: const Icon(Icons.verified_user),
                          label: const Text('Enrolar'),
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

class _CenteredMessage extends StatelessWidget {
  final String message;
  const _CenteredMessage({required this.message});

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
