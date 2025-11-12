// lib/services/biometria_service.dart
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:camera/camera.dart' show XFile;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as imglib;
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

class BiometriaService {
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableLandmarks: true,
      enableClassification: true,
    ),
  );

  tfl.Interpreter? _interpreter;

  Future<void> loadModel() async {
    if (_interpreter != null) return;
    final opts = tfl.InterpreterOptions()
      ..threads = 2
      ..useNnApiForAndroid = false; // CPU/XNNPACK
    _interpreter = await tfl.Interpreter.fromAsset(
      'assets/models/mobilefacenet.tflite',
      options: opts,
    );
  }

  Future<void> dispose() async {
    await _detector.close();
    _interpreter?.close();
    _interpreter = null;
  }

  Future<imglib.Image?> cropFaceFromJpeg(Uint8List bytes) async {
    final tmp = await XFile.fromData(bytes);
    final input = InputImage.fromFilePath(tmp.path);

    final faces = await _detector.processImage(input);
    if (faces.isEmpty) return null;

    final img = imglib.decodeImage(bytes);
    if (img == null) return null;

    final face = faces.reduce(
      (a, b) => a.boundingBox.size.longestSide > b.boundingBox.size.longestSide
          ? a
          : b,
    );

    final rect = face.boundingBox.inflate(20);
    final crop = _safeCrop(img, rect);
    if (crop == null) return null;

    return imglib.copyResize(
      crop,
      width: 112,
      height: 112,
      interpolation: imglib.Interpolation.average,
    );
  }

  /// Embedding 128-D normalizado L2 (MobileFaceNet 112x112 RGB en [-1, 1])
  List<double> embed(imglib.Image face112) {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError(
        'Interpreter TFLite no inicializado. Llama loadModel() antes.',
      );
    }

    final Float32List input = Float32List(1 * 112 * 112 * 3);
    int i = 0;
    for (int y = 0; y < 112; y++) {
      for (int x = 0; x < 112; x++) {
        // En image >=4, getPixel devuelve Pixel (no int)
        final imglib.Pixel pix = face112.getPixel(x, y);
        input[i++] = (pix.r.toDouble() / 127.5) - 1.0;
        input[i++] = (pix.g.toDouble() / 127.5) - 1.0;
        input[i++] = (pix.b.toDouble() / 127.5) - 1.0;
      }
    }

    final output = List.filled(128, 0.0).reshape([1, 128]);
    interpreter.run(input.reshape([1, 112, 112, 3]), output);
    final emb = List<double>.from(output[0]);

    final norm = math.sqrt(emb.fold<double>(0, (s, v) => s + v * v));
    return emb.map((v) => v / (norm == 0 ? 1 : norm)).toList();
  }

  double cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0, na = 0, nb = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      na += a[i] * a[i];
      nb += b[i] * b[i];
    }
    return dot / (math.sqrt(na) * math.sqrt(nb));
  }

  bool isMatch(double cosine, {double threshold = 0.62}) => cosine >= threshold;

  imglib.Image? _safeCrop(imglib.Image src, Rect r) {
    final x = r.left.floor().clamp(0, src.width - 1);
    final y = r.top.floor().clamp(0, src.height - 1);
    final w = r.width.ceil().clamp(1, src.width - x);
    final h = r.height.ceil().clamp(1, src.height - y);
    if (w <= 0 || h <= 0) return null;
    return imglib.copyCrop(src, x: x, y: y, width: w, height: h);
  }
}
