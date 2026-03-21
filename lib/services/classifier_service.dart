import 'dart:convert';
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

  PlantPrediction({
    required this.accepted,
    required this.label,
    required this.confidence,
    required this.secondBest,
    required this.greenRatio,
    required this.previewBytes,
  });
}

class PlantClassifierService {
  late Interpreter _interpreter;
  late List<String> _labels;

  static const int inputSize = 224;

  // stricter thresholds to reduce false predictions
  static const double confidenceThreshold = 0.65;
  static const double marginThreshold = 0.15;
  static const double greenRatioThreshold = 0.06;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/models/mf_m2.tflite');
    final raw = await rootBundle.loadString('assets/models/mf_labels.json');
    final List<dynamic> decoded = jsonDecode(raw);
    _labels = decoded.map((e) => e.toString()).toList();
  }

  Future<PlantPrediction> predict(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      return PlantPrediction(
        accepted: false,
        label: "Invalid image",
        confidence: 0,
        secondBest: 0,
        greenRatio: 0,
        previewBytes: Uint8List(0),
      );
    }

    /// =========================
    /// OLD BOUNDING BOX METHOD
    /// =========================
    /*
    final processed = _detectAndCropPlant(decoded);
    final img.Image cropped = processed['cropped'] as img.Image;
    final img.Image preview = processed['preview'] as img.Image;
    final double greenRatio = processed['greenRatio'] as double;
    */

    /// =========================
    /// NEW SIMPLER PIPELINE
    /// =========================

    final img.Image cropped = _centerCropSquare(decoded);
    final img.Image preview =
        img.copyResize(cropped, width: cropped.width, height: cropped.height);

    final double greenRatio = _computeGreenRatio(cropped);

    final resized = img.copyResize(
      cropped,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    final input = _imageToHsvTensor(resized);

    final output = List.generate(1, (_) => List.filled(_labels.length, 0.0));
    _interpreter.run(input, output);

    final probs = List<double>.from(output[0]);
    final sorted = [...probs]..sort((a, b) => b.compareTo(a));

    final maxIndex = _argMax(probs);
    final confidence = probs[maxIndex];
    final secondBest = sorted.length > 1 ? sorted[1] : 0.0;
    final margin = confidence - secondBest;
    final label = _labels[maxIndex];

    /// DEBUG (very helpful)
    print("Prediction scores: $probs");
    print("Predicted label: $label");
    print("Confidence: $confidence");
    print("Second best: $secondBest");
    print("Green ratio: $greenRatio");

    final accepted = greenRatio >= greenRatioThreshold &&
        confidence >= confidenceThreshold &&
        margin >= marginThreshold;

    return PlantPrediction(
      accepted: accepted,
      label: accepted
          ? label
          : "Plant not recognized. Please capture a clear leaf image.",
      confidence: confidence,
      secondBest: secondBest,
      greenRatio: greenRatio,
      previewBytes: Uint8List.fromList(img.encodeJpg(preview, quality: 85)),
    );
  }

  /// =========================
  /// GREEN RATIO CALCULATION
  /// =========================

  double _computeGreenRatio(img.Image image) {
    int greenPixels = 0;
    final totalPixels = image.width * image.height;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        final r = p.r.toDouble();
        final g = p.g.toDouble();
        final b = p.b.toDouble();

        //final isGreen = g > 55 && g > r * 1.08 && g > b * 1.08;
        final isGreen = g > 35 && g > r * 1.05 && g > b * 1.05; // improves the dark leaf detection if may shadow/shade

        if (isGreen) greenPixels++;
      }
    }

    return totalPixels == 0 ? 0 : greenPixels / totalPixels;
  }

  /// =========================
  /// OLD PLANT DETECTOR
  /// (kept for reference)
  /// =========================
  /*
  Map<String, dynamic> _detectAndCropPlant(img.Image image) {
    ...
  }
  */

  img.Image _centerCropSquare(img.Image image) {
    final size = math.min(image.width, image.height);
    final x = (image.width - size) ~/ 2;
    final y = (image.height - size) ~/ 2;

    return img.copyCrop(image, x: x, y: y, width: size, height: size);
  }

  List<List<List<List<double>>>> _imageToHsvTensor(img.Image image) {
    return [
      List.generate(inputSize, (y) {
        return List.generate(inputSize, (x) {
          final p = image.getPixel(x, y);

          final r = p.r / 255.0;
          final g = p.g / 255.0;
          final b = p.b / 255.0;

          final hsv = _rgbToHsv(r, g, b);

          return [hsv[0], hsv[1], hsv[2]];
        });
      }),
    ];
  }

  List<double> _rgbToHsv(double r, double g, double b) {
    final maxVal = math.max(r, math.max(g, b));
    final minVal = math.min(r, math.min(g, b));
    final delta = maxVal - minVal;

    double h = 0;
    double s = maxVal == 0 ? 0 : delta / maxVal;
    double v = maxVal;

    if (delta != 0) {
      if (maxVal == r) {
        h = ((g - b) / delta) % 6;
      } else if (maxVal == g) {
        h = ((b - r) / delta) + 2;
      } else {
        h = ((r - g) / delta) + 4;
      }

      h /= 6;
      if (h < 0) h += 1;
    }

    return [h, s, v];
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

  void close() {
    _interpreter.close();
  }
}