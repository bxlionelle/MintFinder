import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
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
  Interpreter? _interpreter; // nullable — safe before loadModel() completes
  List<String> _labels = [];
  bool _isInitialized = false;
  bool _isRunning = false; // prevents concurrent predict() calls

  static const int inputSize = 224;
  static const double confidenceThreshold = 0.65;
  static const double marginThreshold = 0.15;
  static const double greenRatioThreshold = 0.06;

  final List<double> means = [
    2.70941439848556, 6.413811314639813, 8.91005550941648, 9.156944765089087,
    3.7475510584679834, 2.563189279653074, -0.2409821434246219, 16.584304214312564,
    21.242152021665913, 20.97771875170915, 16.359401501887085, 26.332583301416275,
    47.88247780680488, 47.04557811730435, 24.756665652185028, 25.47475566969335,
    51.09448093915692, 50.59010299830218, 26.872858476499726, 19.37026385621214,
    25.68912174454152, 25.34243003501587, 19.748202146139345, 106.35394982494523,
    93.25522395002542, 107.91020054448569, 92.86673911109658, 99.96252497731653,
    95.73633728415419, 108.0010101885511, 92.56539189745402, 64.39860213941472,
    97.21151199274055, 89.77767628813415, 103.37667418714616, 65.88707130703321,
    100.08392025269428, 89.97815556978493, 103.32109529058161
  ];

  final List<double> stds = [
    0.5181952868224002, 1.4420517591993374, 1.7279415485945149, 1.7408585370392726,
    9.116390195803158, 9.472996396787458, 9.856057201236622, 28.37028074941613,
    29.25900957481639, 29.814713853536823, 29.042224498385167, 29.747698519001943,
    26.850249410234618, 27.146629327214562, 30.149598530164997, 29.89730949653603,
    26.180656842171622, 27.606663325426652, 30.852116965490406, 31.791685386469922,
    31.8641787235787, 31.721328566319368, 32.34177066386079, 76.08946949962336,
    23.123953419680632, 76.63583358959644, 23.88355555576983, 72.45336029347663,
    18.883266806596914, 76.97901708031327, 24.04060004196954, 36.28196809936799,
    17.29863541778685, 55.04186817548383, 13.891275708869065, 36.00253859581564,
    16.610095648041934, 55.34571290632443, 13.700281726348837
  ];

  // ── Model loading ─────────────────────────────────────────────────
  Future<void> loadModel() async {
    print("Means count: ${means.length}, Stds count: ${stds.length}");
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/HybridModel.tflite');

      // Allocate tensors once here — not on every inference call.
      _interpreter!.allocateTensors();

      print(_interpreter!.getInputTensors());

      final rawLabels = await rootBundle.loadString('assets/models/labels.txt');
      _labels = rawLabels
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .map((s) => s.replaceFirst(RegExp(r'^\d+\s+'), ''))
          .toList();

      _isInitialized = true;
      print("HybridModel loaded. Classes: ${_labels.length}");
    } catch (e) {
      _isInitialized = false;
      print("Error loading model: $e");
    }
  }

  // ── Inference ─────────────────────────────────────────────────────
  Future<PlantPrediction> predict(File imageFile) async {
    // Guard 1: model not ready yet
    if (!_isInitialized || _interpreter == null) {
      return _invalidPrediction("Model not ready. Please wait.");
    }

    // Guard 2: another prediction is already running (prevents concurrent calls)
    if (_isRunning) {
      return _invalidPrediction("Still processing previous image.");
    }

    _isRunning = true;

    try {
      final bytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return _invalidPrediction("Invalid image");

      final cropped = _centerCropSquare(decoded);
      final resized = img.copyResize(cropped, width: inputSize, height: inputSize);
      final double greenRatio = _computeGreenRatio(resized);

      // Image tensor
      final imageTensor = _imageToRgbTensor(resized);

      // Real classical features: Hu(7) + Canny(16) + Gabor(16) = 39
      final small = img.copyResize(resized, width: 64, height: 64);
      final gray = _toGrayscaleNormalized(small);
      final huFeatures = _extractHuMoments(gray);
      final cannyFeatures = _extractCannyFeatures(gray);
      final gaborFeatures = _extractGaborFeatures(gray);

      final classicalFeaturesRaw = [...huFeatures, ...cannyFeatures, ...gaborFeatures];
      final classicalFeatures = _scaleFeatures(classicalFeaturesRaw);
      final classicalTensor = [classicalFeatures];

      // Output shape is [1, numClasses] to match model's [1, 4] output
      final outputBuffer = [List.filled(_labels.length, 0.0)];
      final outputMap = <int, Object>{0: outputBuffer};

      // Order must match the model's input tensor names from getInputTensors():
      // index 0 → serving_default_classical_input:0  (shape [1, 39])
      // index 1 → serving_default_image_input:0      (shape [1, 224, 224, 3])
      _interpreter!.runForMultipleInputs(
        [classicalTensor, imageTensor],
        outputMap,
      );

      // Unwrap batch dimension [1, 4] → [4]
      final probs = List<double>.from(outputBuffer[0]);

      // DEBUG
      print("=== DEBUG ===");
      print("Output probs: $probs");
      print("Labels count: ${_labels.length}");
      print("Classical features sample: ${classicalFeatures.take(5).toList()}");
      print("Green ratio: $greenRatio");
      print("=============");
      final sorted = [...probs]..sort((a, b) => b.compareTo(a));
      final maxIndex = _argMax(probs);
      final confidence = probs[maxIndex];
      final secondBest = sorted.length > 1 ? sorted[1] : 0.0;
      final margin = confidence - secondBest;
      final rawLabel = _labels[maxIndex];

      // Known plant classes — must match your labels.txt entries (lowercased, spaces→underscores)
      const knownPlants = {'cats_whiskers', 'lemon_basil', 'mojito_mint'};
      final labelKey = rawLabel
          .toLowerCase()
          .replaceFirst(RegExp(r'^\d+\s+'), '')
          .replaceAll(' ', '_')
          .trim();

      final isKnownPlant = knownPlants.contains(labelKey);

      print("Confidence: $confidence, Green: $greenRatio, Label: $rawLabel, Key: $labelKey, Known: $isKnownPlant");

      // Green ratio NOT used — model is morphology-only (grayscale features)
      final accepted = isKnownPlant &&
          confidence >= confidenceThreshold &&
          margin >= marginThreshold;
      return PlantPrediction(
        accepted: accepted,
        label: accepted ? labelKey : 'not_recognized',
        confidence: confidence,
        secondBest: secondBest,
        greenRatio: greenRatio,
        previewBytes: Uint8List.fromList(img.encodeJpg(resized, quality: 85)),
      );
    } catch (e, stack) {
      print("Prediction error: $e");
      print(stack);
      return _invalidPrediction("Error: $e");
    } finally {
      // Always release the lock, even if an exception was thrown.
      _isRunning = false;
    }
  }

  // ── Grayscale conversion (normalized 0.0–1.0) ────────────────────
  List<List<double>> _toGrayscaleNormalized(img.Image image) {
    return List.generate(image.height, (y) {
      return List.generate(image.width, (x) {
        final p = image.getPixel(x, y);
        return 0.299 * p.r + 0.587 * p.g + 0.114 * p.b; // 0–255, matches Python cv2
      });
    });
  }

  // ── Hu Moments (7 features) ───────────────────────────────────────
  List<double> _extractHuMoments(List<List<double>> gray) {
    final h = gray.length;
    final w = gray[0].length;

    double m00 = 0, m10 = 0, m01 = 0, m20 = 0, m02 = 0, m11 = 0,
        m30 = 0, m03 = 0, m21 = 0, m12 = 0;

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final v = gray[y][x] > 127.0 ? 1.0 : 0.0;
        m00 += v;
        m10 += x * v;
        m01 += y * v;
        m20 += x * x * v;
        m02 += y * y * v;
        m11 += x * y * v;
        m30 += x * x * x * v;
        m03 += y * y * y * v;
        m21 += x * x * y * v;
        m12 += x * y * y * v;
      }
    }

    if (m00 == 0) return List.filled(7, 0.0);

    final cx = m10 / m00;
    final cy = m01 / m00;

    double mu20 = 0, mu02 = 0, mu11 = 0, mu30 = 0, mu03 = 0, mu21 = 0, mu12 = 0;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final v = gray[y][x] > 127.0 ? 1.0 : 0.0;
        final dx = x - cx;
        final dy = y - cy;
        mu20 += dx * dx * v;
        mu02 += dy * dy * v;
        mu11 += dx * dy * v;
        mu30 += dx * dx * dx * v;
        mu03 += dy * dy * dy * v;
        mu21 += dx * dx * dy * v;
        mu12 += dx * dy * dy * v;
      }
    }

    final inv = 1.0 / (m00 * m00);
    final n20 = mu20 * inv;
    final n02 = mu02 * inv;
    final n11 = mu11 * inv;
    final inv25 = 1.0 / math.pow(m00, 2.5);
    final n30 = mu30 * inv25;
    final n03 = mu03 * inv25;
    final n21 = mu21 * inv25;
    final n12 = mu12 * inv25;

    final hu = List<double>.filled(7, 0.0);
    hu[0] = n20 + n02;
    hu[1] = math.pow(n20 - n02, 2).toDouble() + 4 * n11 * n11;
    hu[2] = math.pow(n30 - 3 * n12, 2).toDouble() + math.pow(3 * n21 - n03, 2).toDouble();
    hu[3] = math.pow(n30 + n12, 2).toDouble() + math.pow(n21 + n03, 2).toDouble();
    hu[4] = (n30 - 3 * n12) * (n30 + n12) *
            (math.pow(n30 + n12, 2).toDouble() - 3 * math.pow(n21 + n03, 2).toDouble()) +
        (3 * n21 - n03) *
            (n21 + n03) *
            (3 * math.pow(n30 + n12, 2).toDouble() - math.pow(n21 + n03, 2).toDouble());
    hu[5] = (n20 - n02) * (math.pow(n30 + n12, 2).toDouble() - math.pow(n21 + n03, 2).toDouble()) +
        4 * n11 * (n30 + n12) * (n21 + n03);
    hu[6] = (3 * n21 - n03) * (n30 + n12) *
            (math.pow(n30 + n12, 2).toDouble() - 3 * math.pow(n21 + n03, 2).toDouble()) -
        (n30 - 3 * n12) *
            (n21 + n03) *
            (3 * math.pow(n30 + n12, 2).toDouble() - math.pow(n21 + n03, 2).toDouble());

    return hu.map((v) {
      if (v == 0) return 0.0;
      return -v.sign * math.log(v.abs() + 1e-10) / math.ln10;
    }).toList();
  }

  // ── Canny Edge Features (16 features, 4×4 grid) ───────────────────
  List<double> _extractCannyFeatures(List<List<double>> gray) {
    final h = gray.length;
    final w = gray[0].length;

    // Match Python: cv2.Canny outputs 0 or 255 per pixel, then np.sum(cell)/cell.size
    final edges = List.generate(h, (_) => List.filled(w, 0.0));
    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final gx = -gray[y-1][x-1] - 2*gray[y][x-1] - gray[y+1][x-1]
                  + gray[y-1][x+1] + 2*gray[y][x+1] + gray[y+1][x+1];
        final gy = -gray[y-1][x-1] - 2*gray[y-1][x] - gray[y-1][x+1]
                  + gray[y+1][x-1] + 2*gray[y+1][x] + gray[y+1][x+1];
        final mag = math.sqrt(gx * gx + gy * gy);
        // Binary like cv2.Canny: edge=255, non-edge=0
        edges[y][x] = mag > 50.0 ? 255.0 : 0.0;
      }
    }

    const grid = 4;
    final cellH = h ~/ grid;
    final cellW = w ~/ grid;
    final features = <double>[];

    for (int i = 0; i < grid; i++) {
      for (int j = 0; j < grid; j++) {
        double sum = 0.0;
        int count = 0;
        for (int y = i * cellH; y < (i + 1) * cellH; y++) {
          for (int x = j * cellW; x < (j + 1) * cellW; x++) {
            sum += edges[y][x];
            count++;
          }
        }
        // Match Python: np.sum(cell) / (cell.size + 1e-10)
        features.add(sum / (count + 1e-10));
      }
    }

    return features;
  }

  // ── Gabor Features (16 features: 2 sigmas × 4 angles × mean+std) ──
  List<double> _extractGaborFeatures(List<List<double>> gray) {
    final h = gray.length;
    final w = gray[0].length;
    final features = <double>[];

    const sigmas = [4.0, 8.0];
    const anglesDeg = [0, 45, 90, 135];
    const kSize = 31;
    const lambda = 10.0;
    const gamma = 0.5;

    for (final sigma in sigmas) {
      for (final angleDeg in anglesDeg) {
        final theta = angleDeg * math.pi / 180.0;
        final kernel = _makeGaborKernel(kSize, sigma, theta, lambda, gamma);
        final filtered = _convolve2D(gray, kernel, kSize);

        double sum = 0.0;
        for (int y = 0; y < h; y++) {
          for (int x = 0; x < w; x++) {
            sum += filtered[y][x];
          }
        }
        final mean = sum / (h * w);

        double varSum = 0.0;
        for (int y = 0; y < h; y++) {
          for (int x = 0; x < w; x++) {
            final d = filtered[y][x] - mean;
            varSum += d * d;
          }
        }
        final std = math.sqrt(varSum / (h * w));

        features.add(mean);
        features.add(std);
      }
    }

    return features;
  }

  List<List<double>> _makeGaborKernel(
      int kSize, double sigma, double theta, double lambda, double gamma) {
    final half = kSize ~/ 2;
    final kernel = List.generate(kSize, (_) => List.filled(kSize, 0.0));
    final cosT = math.cos(theta);
    final sinT = math.sin(theta);

    for (int y = -half; y <= half; y++) {
      for (int x = -half; x <= half; x++) {
        final xp = x * cosT + y * sinT;
        final yp = -x * sinT + y * cosT;
        final gauss = math.exp(-(xp * xp + gamma * gamma * yp * yp) / (2 * sigma * sigma));
        final wave = math.cos(2 * math.pi * xp / lambda);
        kernel[y + half][x + half] = gauss * wave;
      }
    }
    return kernel;
  }

  List<List<double>> _convolve2D(
      List<List<double>> image, List<List<double>> kernel, int kSize) {
    final h = image.length;
    final w = image[0].length;
    final half = kSize ~/ 2;
    final result = List.generate(h, (_) => List.filled(w, 0.0));

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        double sum = 0.0;
        for (int ky = 0; ky < kSize; ky++) {
          for (int kx = 0; kx < kSize; kx++) {
            final iy = (y + ky - half).clamp(0, h - 1);
            final ix = (x + kx - half).clamp(0, w - 1);
            sum += image[iy][ix] * kernel[ky][kx];
          }
        }
        result[y][x] = sum.abs().clamp(0.0, 255.0); // match cv2.filter2D CV_8UC3 clamping
      }
    }
    return result;
  }

  // ── Feature scaling ───────────────────────────────────────────────
  List<double> _scaleFeatures(List<double> raw) {
    return List.generate(raw.length, (i) {
      if (i >= means.length || i >= stds.length) return raw[i];
      return (raw[i] - means[i]) / stds[i];
    });
  }

  // ── Image preprocessing ───────────────────────────────────────────
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

  String _getFailureReason(double green, double confidence) {
    if (green < greenRatioThreshold) return "No plant detected. Please center the leaf.";
    if (confidence < confidenceThreshold) return "Low confidence. Try better lighting.";
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
    );
  }

  void close() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}