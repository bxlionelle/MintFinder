// classifier_service.dart
//
// Runs the ACTUAL trained MintFinder algorithm:
//   MobileNetV2 branch (deep features) + Hu Moments/Canny branch (classical
//   features), matching train_model.py / predict.py exactly.
//
// Public API (PlantClassifierService, PlantPrediction, loadModel(), predict())
// is kept the same as the previous version so capture_page.dart and
// result_page.dart don't need to change.
//
// NOTE on opencv_dart: exact function signatures can shift between package
// versions. Hu Moments are computed manually here (from the Moments object's
// nu20/nu11/nu02/nu30/nu21/nu12/nu03 properties) rather than calling a
// top-level huMoments() function, since that function's name/availability
// varies between opencv_dart versions - this approach is version-proof.
// If cvtColor/createCLAHE/threshold/bitwiseAND/moments/canny don't compile
// against the version you install, check that package's example app on
// pub.dev and adjust those specific calls.

import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'feature_scaler.dart';

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
  static const int _imgSize = 224;
  static const int _featureSize = 23;

  Interpreter? _interpreter;
  FeatureScaler? _scaler;
  Map<int, String> _labels = {};
  int _imageInputIndex = 0;
  int _classicalInputIndex = 1;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
      _scaler = await FeatureScaler.loadFromAsset('assets/models/scaler.json');

      final labelRaw =
          await rootBundle.loadString('assets/models/label_map.json');
      final Map<String, dynamic> labelJson = jsonDecode(labelRaw);
      _labels = labelJson.map((k, v) => MapEntry(int.parse(k), v as String));

      // Match inputs by name (same approach as predict.py) in case tensor
      // order ever changes between exports.
      final inputTensors = _interpreter!.getInputTensors();
      for (var i = 0; i < inputTensors.length; i++) {
        final name = inputTensors[i].name.toLowerCase();
        if (name.contains('classical')) {
          _classicalInputIndex = i;
        } else if (name.contains('image')) {
          _imageInputIndex = i;
        }
      }

      print("Model, scaler, and labels loaded. Classes: ${_labels.length}");
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  Future<PlantPrediction> predict(File imageFile) async {
    if (_interpreter == null || _scaler == null) {
      print("[MintFinder] predict() aborted - model/scaler not loaded");
      return _invalidPrediction("Model not loaded yet");
    }

    print("[MintFinder] predict() start");
    final bytes = await imageFile.readAsBytes();
    print("[MintFinder] read ${bytes.length} bytes from file");

    // ── Preview / color-info decode (image package) ──────────────────────
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      print("[MintFinder] img.decodeImage returned null");
      return _invalidPrediction("Invalid image");
    }
    print("[MintFinder] preview decode OK");
    final cropped = _centerCropSquare(decoded);
    final greenRatio = _computeGreenRatio(cropped);
    print("[MintFinder] green ratio computed: $greenRatio");
    final previewResized = img.copyResize(
      cropped,
      width: _imgSize,
      height: _imgSize,
      interpolation: img.Interpolation.linear,
    );
    final (h, s, v) = _averageHsv(previewResized);
    print("[MintFinder] preview/HSV done");

    // ── Actual classification (opencv_dart) ───────────────────────────────
    print("[MintFinder] cv.imdecode starting...");
    final original = cv.imdecode(bytes, cv.IMREAD_COLOR);
    print("[MintFinder] cv.imdecode done");
    final resized = cv.resize(original, (_imgSize, _imgSize));
    print("[MintFinder] cv.resize done");
    final gray = cv.cvtColor(resized, cv.COLOR_BGR2GRAY);
    print("[MintFinder] cv.cvtColor (gray) done");

    final imageInput = _buildImageInput(gray);
    print("[MintFinder] _buildImageInput done");
    final classicalRaw = _extractClassicalFeatures(gray);
    print("[MintFinder] _extractClassicalFeatures done: $classicalRaw");
    final classicalScaled = _scaler!.transform(classicalRaw);
    print("[MintFinder] scaler.transform done");

    final output =
        List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);

    final inputs = List<Object>.filled(2, imageInput);
    inputs[_imageInputIndex] = imageInput.reshape([1, _imgSize, _imgSize, 3]);
    inputs[_classicalInputIndex] =
        Float32List.fromList(classicalScaled).reshape([1, _featureSize]);

    final outputs = <int, Object>{0: output};
    print("[MintFinder] calling interpreter.runForMultipleInputs...");
    _interpreter!.runForMultipleInputs(inputs, outputs);
    print("[MintFinder] interpreter run done, output: ${output[0]}");

    final scores = (output[0] as List).cast<double>();
    final sorted = [...scores]..sort((a, b) => b.compareTo(a));

    final topIdx = _argMax(scores);
    final confidence = scores[topIdx];
    final secondBest = sorted.length > 1 ? sorted[1] : 0.0;
    final label = _labels[topIdx] ?? 'unknown';
    print("[MintFinder] predicted: $label ($confidence)");

    // "unknown" is a trained class now, not a threshold heuristic - so the
    // model itself decides, no extra gating needed.
    final accepted = label != 'unknown';

    return PlantPrediction(
      accepted: accepted,
      label: accepted ? label : "Not recognized as a target species.",
      confidence: confidence,
      secondBest: secondBest,
      greenRatio: greenRatio,
      previewBytes:
          Uint8List.fromList(img.encodeJpg(previewResized, quality: 85)),
      hue: h,
      saturation: s,
      value: v,
    );
  }

  /// Grayscale -> stack to 3 channels -> normalize [0,1].
  /// Must match load_image()/preprocess_image() in the Python scripts.
  ///
  /// Reads the whole pixel buffer at once instead of calling .at<>() per
  /// pixel (which was ~50,000 individual FFI calls, blocking the UI thread
  /// long enough that "analyzing" looked frozen).
  Float32List _buildImageInput(cv.Mat gray) {
    final rgb = cv.cvtColor(gray, cv.COLOR_GRAY2RGB);
    final bytes = rgb.data; // Uint8List, length = imgSize*imgSize*3, RGB interleaved
    final data = Float32List(_imgSize * _imgSize * 3);
    for (var i = 0; i < data.length; i++) {
      data[i] = bytes[i] / 255.0;
    }
    return data;
  }

  /// CLAHE + Otsu -> Hu Moments (7) + Canny grid density (16) = 23 features.
  /// Must match extract_classical_features() in train_model.py / predict.py.
  List<double> _extractClassicalFeatures(cv.Mat gray) {
    final clahe = cv.createCLAHE(clipLimit: 2.0, tileGridSize: (8, 8));
    final enhanced = clahe.apply(gray);

    final (_, mask) = cv.threshold(
      enhanced, 0, 255, cv.THRESH_BINARY | cv.THRESH_OTSU,
    );
    final masked = cv.bitwiseAND(enhanced, enhanced, mask: mask);

    final (_, binaryForHu) = cv.threshold(masked, 127, 255, cv.THRESH_BINARY);
    final moments = cv.moments(binaryForHu);
    final huRawValues = _computeHuMoments(moments);
    final hu = List<double>.generate(7, (i) {
      final val = huRawValues[i];
      final sign = val == 0 ? 0.0 : (val > 0 ? 1.0 : -1.0);
      return -sign * (_log10(val.abs() + 1e-10));
    });

    final edges = cv.canny(masked, 50, 150);
    final edgeBytes = edges.data; // Uint8List, single channel, 0 or 255 per pixel
    final canny = <double>[];
    final cellH = _imgSize ~/ 4;
    final cellW = _imgSize ~/ 4;
    for (var i = 0; i < 4; i++) {
      for (var j = 0; j < 4; j++) {
        var sum = 0.0;
        for (var y = i * cellH; y < (i + 1) * cellH; y++) {
          final rowOffset = y * _imgSize;
          for (var x = j * cellW; x < (j + 1) * cellW; x++) {
            sum += edgeBytes[rowOffset + x] > 0 ? 255.0 : 0.0;
          }
        }
        canny.add(sum / (cellH * cellW + 1e-10));
      }
    }

    return [...hu, ...canny];
  }

  double _log10(double x) => x <= 0 ? 0.0 : math.log(x) / math.ln10;

  /// Computes the 7 raw Hu Moment invariants directly from the central
  /// normalized moments (nu20, nu11, nu02, nu30, nu21, nu12, nu03).
  /// This is the same formula OpenCV's cv2.HuMoments() uses internally -
  /// implementing it manually here avoids depending on opencv_dart exposing
  /// a specific top-level huMoments() function, whose name/availability can
  /// vary between package versions.
  List<double> _computeHuMoments(cv.Moments m) {
    final n20 = m.nu20, n11 = m.nu11, n02 = m.nu02;
    final n30 = m.nu30, n21 = m.nu21, n12 = m.nu12, n03 = m.nu03;

    final t0 = n30 + n12;      // η30 + η12
    final t1 = n21 + n03;      // η21 + η03
    final q0 = t0 * t0;        // (η30 + η12)²
    final q1 = t1 * t1;        // (η21 + η03)²
    final a = n30 - 3 * n12;   // η30 - 3η12
    final b = 3 * n21 - n03;   // 3η21 - η03

    final h1 = n20 + n02;
    final h2 = (n20 - n02) * (n20 - n02) + 4 * n11 * n11;
    final h3 = a * a + b * b;
    final h4 = q0 + q1;
    final h5 = a * t0 * (q0 - 3 * q1) + b * t1 * (3 * q0 - q1);
    final h6 = (n20 - n02) * (q0 - q1) + 4 * n11 * t0 * t1;
    final h7 = b * t0 * (q0 - 3 * q1) - a * t1 * (3 * q0 - q1);

    return [h1, h2, h3, h4, h5, h6, h7];
  }

  int _argMax(List<double> values) {
    var index = 0;
    var maxVal = values[0];
    for (var i = 1; i < values.length; i++) {
      if (values[i] > maxVal) {
        maxVal = values[i];
        index = i;
      }
    }
    return index;
  }

  // ── Kept from the original file - display-only helpers ─────────────────
  img.Image _centerCropSquare(img.Image image) {
    final size = math.min(image.width, image.height);
    final x = (image.width - size) ~/ 2;
    final y = (image.height - size) ~/ 2;
    return img.copyCrop(image, x: x, y: y, width: size, height: size);
  }

  double _computeGreenRatio(img.Image image) {
    int greenPixels = 0;
    final total = image.width * image.height;
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        if (p.g > 35 && p.g > p.r * 1.05 && p.g > p.b * 1.05) greenPixels++;
      }
    }
    return total == 0 ? 0 : greenPixels / total;
  }

  (double, double, double) _averageHsv(img.Image image) {
    double sumR = 0, sumG = 0, sumB = 0;
    final total = image.width * image.height;
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        sumR += p.r;
        sumG += p.g;
        sumB += p.b;
      }
    }
    final r = (sumR / total) / 255.0;
    final g = (sumG / total) / 255.0;
    final b = (sumB / total) / 255.0;
    final cmax = math.max(r, math.max(g, b));
    final cmin = math.min(r, math.min(g, b));
    final delta = cmax - cmin;
    double hh = 0.0;
    if (delta != 0) {
      if (cmax == r) {
        hh = 60.0 * (((g - b) / delta) % 6);
      } else if (cmax == g) {
        hh = 60.0 * (((b - r) / delta) + 2);
      } else {
        hh = 60.0 * (((r - g) / delta) + 4);
      }
    }
    if (hh < 0) hh += 360.0;
    final ss = cmax == 0 ? 0.0 : delta / cmax;
    return (hh, ss, cmax);
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

  void close() => _interpreter?.close();
}