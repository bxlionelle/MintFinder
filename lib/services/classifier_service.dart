import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class PlantPrediction {
  final bool accepted;
  final String label;
  final double confidence;
  final double secondBest;
  final double greenRatio;
  final Uint8List previewBytes;
  final double hue;  
  final double saturation; 
  final double value;      

  PlantPrediction({
    required this.accepted,
    required this.label,
    required this.confidence,
    required this.secondBest,
    required this.greenRatio,
    required this.previewBytes,
    required this.hue,
    required this.saturation,
    required this.value,
  });
}

class PlantClassifierService {
  late Interpreter _interpreter;
  late List<String> _labels;

  static const int inputSize = 224;

  static const double confidenceThreshold = 0.65;
  static const double marginThreshold = 0.15;
  static const double greenRatioThreshold = 0.06;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/m8.tflite');
      final rawLabels = await rootBundle.loadString('assets/models/labels.txt');
      _labels = rawLabels
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .map((s) => s.replaceFirst(RegExp(r'^\d+\s+'), ''))
          .toList();

      print("Model and Labels loaded successfully. Classes: ${_labels.length}");
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  Future<PlantPrediction> predict(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      return _invalidPrediction("Invalid image");
    }

    final img.Image cropped = _centerCropSquare(decoded);
    final double greenRatio = _computeGreenRatio(cropped);

    final resized = img.copyResize(
      cropped,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    // ── RGB → HSV conversion ──────────────────────────────────────────────
    double sumR = 0, sumG = 0, sumB = 0;
    final int totalPixels = resized.width * resized.height;

    for (int y = 0; y < resized.height; y++) {
      for (int x = 0; x < resized.width; x++) {
        final p = resized.getPixel(x, y);
        sumR += p.r;
        sumG += p.g;
        sumB += p.b;
      }
    }

    final double r = (sumR / totalPixels) / 255.0;
    final double g = (sumG / totalPixels) / 255.0;
    final double b = (sumB / totalPixels) / 255.0;

    final double cmax = math.max(r, math.max(g, b));
    final double cmin = math.min(r, math.min(g, b));
    final double delta = cmax - cmin;

    double h = 0.0;
    if (delta != 0) {
      if (cmax == r) {
        h = 60.0 * (((g - b) / delta) % 6);
      } else if (cmax == g) {
        h = 60.0 * (((b - r) / delta) + 2);
      } else {
        h = 60.0 * (((r - g) / delta) + 4);
      }
    }
    if (h < 0) h += 360.0;

    final double s = cmax == 0 ? 0.0 : delta / cmax;
    final double v = cmax;
    // ─────────────────────────────────────────────────────────────────────

    final input = _imageToRgbTensor(resized);

    final output = List.generate(1, (_) => List.filled(_labels.length, 0.0));
    _interpreter.run(input, output);

    final probs = List<double>.from(output[0]);
    final sorted = [...probs]..sort((a, b) => b.compareTo(a));

    final maxIndex = _argMax(probs);
    final confidence = probs[maxIndex];
    final secondBest = sorted.length > 1 ? sorted[1] : 0.0;
    final margin = confidence - secondBest;
    final label = _labels[maxIndex];

    final bool isConfident = confidence >= confidenceThreshold;
    final bool isDistinct = margin >= marginThreshold;
    final bool isGreenEnough = greenRatio >= greenRatioThreshold;

    final accepted = isConfident && isDistinct && isGreenEnough;

    return PlantPrediction(
      accepted: accepted,
      label: accepted
          ? label
          : _getFailureReason(isGreenEnough, isConfident),
      confidence: confidence,
      secondBest: secondBest,
      greenRatio: greenRatio,
      previewBytes: Uint8List.fromList(img.encodeJpg(resized, quality: 85)),
      hue: h,
      saturation: s,
      value: v,
    );
  }

  List<List<List<List<double>>>> _imageToRgbTensor(img.Image image) {
    return [
      List.generate(inputSize, (y) {
        return List.generate(inputSize, (x) {
          final p = image.getPixel(x, y);
          return [
            (p.r - 127.5) / 127.5,
            (p.g - 127.5) / 127.5,
            (p.b - 127.5) / 127.5,
          ];
        });
      }),
    ];
  }

  double _computeGreenRatio(img.Image image) {
    int greenPixels = 0;
    final totalPixels = image.width * image.height;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        if (p.g > 35 && p.g > p.r * 1.05 && p.g > p.b * 1.05) greenPixels++;
      }
    }
    return totalPixels == 0 ? 0 : greenPixels / totalPixels;
  }

  img.Image _centerCropSquare(img.Image image) {
    final size = math.min(image.width, image.height);
    final x = (image.width - size) ~/ 2;
    final y = (image.height - size) ~/ 2;
    return img.copyCrop(image, x: x, y: y, width: size, height: size);
  }

  int _argMax(List<double> values) {
    int index = 0;
    double maxVal = values[0];
    for (int i = 1; i < values.length; i++) {
      if (values[i] > maxVal) {
        maxVal = values[i];
        index = i;
      }
    }
    return index;
  }

  String _getFailureReason(bool green, bool confident) {
    if (!green) return "No plant detected. Please center the leaf.";
    if (!confident) return "Low confidence. Try better lighting.";
    return "Plant not recognized.";
  }

  PlantPrediction _invalidPrediction(String message) {
    return PlantPrediction(
      accepted: false,
      label: message,
      confidence: 0,
      secondBest: 0,
      greenRatio: 0,
      previewBytes: Uint8List(0),
      hue: 0,
      saturation: 0,
      value: 0,
    );
  }

  void close() => _interpreter.close();
}