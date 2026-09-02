// classifier_service.dart
//
// v8 update: implements the LATE-FUSION architecture, matching the
// updated train_model.py / mintfinder_utils.py / predict.py exactly.
//
// What changed from the previous (early-fusion) version:
//   1. The TFLite model now has TWO outputs (branch_a_output,
//      branch_b_output) instead of one fused output. Branch A
//      (MobileNetV2) LEADS the decision; Branch B (Hu+Canny) only
//      needs to SUPPORT (not independently re-derive) A's guess.
//   2. Two cheap pre-filters run BEFORE the model: green ratio (HSV
//      color check) and leaf shape (contour-coverage check),
//      combined with OR. If BOTH fail, the image is rejected as
//      "unknown" WITHOUT running the model at all.
//   3. fusion_thresholds.json (bundled as an asset, same as
//      scaler.json/label_map.json) holds all four empirically-derived
//      thresholds - nothing here is hardcoded/guessed.
//
// Public API (PlantClassifierService, PlantPrediction, loadModel(),
// predict()) keeps the same core fields as before so existing pages
// don't break; a few new fields were ADDED (shapeScore,
// rejectionReason) which callers can use or ignore.
//
// NOTE on opencv_dart function availability: findContours,
// contourArea, inRange, and countNonZero were verified to exist in
// opencv_dart's public API (pub.dev docs) before writing this code -
// unlike huMoments() previously, these did NOT need a manual
// workaround. cvtColor/createCLAHE/threshold/bitwiseAND/moments/canny
// are unchanged from before and were already working.

import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'feature_scaler.dart';

/// Result of checkFrameAlignment() - just the pre-filter verdict, no
/// species prediction involved.
class FrameAlignmentResult {
  final bool passed;
  final double greenRatio;
  final double shapeScore;
  FrameAlignmentResult({
    required this.passed,
    required this.greenRatio,
    required this.shapeScore,
  });
}

class PlantPrediction {
  final bool accepted;
  final String label;
  final double confidence;
  final double secondBest;
  final double greenRatio;
  final double shapeScore;
  final String? rejectionReason; // "not_recognized" | null - merged into a
                                   // single outcome (was previously two:
                                   // "no_leaf_detected" and "species_unmatched")
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
    required this.shapeScore,
    required this.rejectionReason,
    required this.previewBytes,
    required this.hue,
    required this.saturation,
    required this.value,
  });
}

/// User-facing messages for the two different "unknown" reasons -
/// mirrors mintfinder_utils.py's REJECTION_MESSAGES exactly.
/// Fixed, short status label - NOT translated (same treatment as
/// "SCANNING"), shown regardless of chosen language, per request.
const Map<String, String> _rejectionMessages = {
  "not_recognized": "NOT RECOGNIZE",
};

class PlantClassifierService {
  static const int _imgSize = 224;
  static const int _featureSize = 23;

  Interpreter? _interpreter;
  FeatureScaler? _scaler;
  Map<int, String> _labels = {};
  int _imageInputIndex = 0;
  int _classicalInputIndex = 1;
  int _branchAOutputIndex = 0;
  int _branchBOutputIndex = 1;

  // Loaded from fusion_thresholds.json - all empirically derived during
  // training, none of these are guessed/hardcoded.
  double _thresholdA = 0.9;
  double _thresholdBSupport = 0.2;
  // Combiner strategy - mirrors mintfinder_utils.py's combine_predictions()
  // exactly. "gate" (default) = hard veto, Branch B can reject outright.
  // "blend" = weighted score, Branch B can only nudge, never veto. See
  // that Python docstring for the full trade-off explanation before
  // switching this to "blend".
  String _combinerMode = "gate";
  double _combinerWeightA = 0.75;
  double _combinerCombinedThreshold = 0.6;
  double? _greenRatioThreshold;
  double? _leafShapeThreshold;
  int _unknownIdx = 0;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
      _scaler = await FeatureScaler.loadFromAsset('assets/models/scaler.json');

      final labelRaw =
          await rootBundle.loadString('assets/models/label_map.json');
      final Map<String, dynamic> labelJson = jsonDecode(labelRaw);
      _labels = labelJson.map((k, v) => MapEntry(int.parse(k), v as String));

      final thresholdRaw =
          await rootBundle.loadString('assets/models/fusion_thresholds.json');
      final Map<String, dynamic> thresholdJson = jsonDecode(thresholdRaw);
      _thresholdA = (thresholdJson['branch_a_threshold'] as num).toDouble();
      _thresholdBSupport =
          (thresholdJson['branch_b_threshold'] as num).toDouble();
      _unknownIdx = (thresholdJson['unknown_class_index'] as num).toInt();
      _combinerMode =
          (thresholdJson['combiner_mode'] as String?) ?? "gate";
      _combinerWeightA =
          (thresholdJson['combiner_weight_a'] as num?)?.toDouble() ?? 0.75;
      _combinerCombinedThreshold =
          (thresholdJson['combiner_combined_threshold'] as num?)
                  ?.toDouble() ??
              0.6;
      _greenRatioThreshold = thresholdJson['green_ratio_threshold'] == null
          ? null
          : (thresholdJson['green_ratio_threshold'] as num).toDouble();
      _leafShapeThreshold = thresholdJson['leaf_shape_threshold'] == null
          ? null
          : (thresholdJson['leaf_shape_threshold'] as num).toDouble();

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

      // Match the TWO outputs by name too - falls back to index 0/1
      // (the dict insertion order used in train_model.py's serving_fn)
      // if names weren't preserved through TFLite export, same fallback
      // logic as mintfinder_utils.py's _find_output_index().
      final outputTensors = _interpreter!.getOutputTensors();
      var foundA = false, foundB = false;
      for (var i = 0; i < outputTensors.length; i++) {
        final name = outputTensors[i].name.toLowerCase();
        if (name.contains('branch_a')) {
          _branchAOutputIndex = i;
          foundA = true;
        } else if (name.contains('branch_b')) {
          _branchBOutputIndex = i;
          foundB = true;
        }
      }
      if (!foundA || !foundB) {
        _branchAOutputIndex = 0;
        _branchBOutputIndex = 1;
      }

      print(">>> COMBINER CONFIG LOADED: mode=$_combinerMode "
          "weightA=$_combinerWeightA "
          "combinedThr=$_combinerCombinedThreshold <<<");
      print("Model, scaler, labels, and fusion thresholds loaded. "
          "Classes: ${_labels.length}, thrA=$_thresholdA, "
          "thrBSupport=$_thresholdBSupport, "
          "greenThr=$_greenRatioThreshold, shapeThr=$_leafShapeThreshold");
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  /// Runs ONLY the two cheap pre-filters (green ratio + leaf shape) - no
  /// TFLite inference at all - against a captured/picked photo. Used by
  /// the interactive tutorial to give real, immediate "well aligned" /
  /// "try again" feedback using the EXACT same check the real capture
  /// flow uses, without running a full prediction.
  Future<FrameAlignmentResult> checkFrameAlignment(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final original = cv.imdecode(bytes, cv.IMREAD_COLOR);
    final resized = cv.resize(original, (_imgSize, _imgSize));

    final greenRatio = _computeGreenRatioHsv(resized);
    final gray = cv.cvtColor(resized, cv.COLOR_BGR2GRAY);
    final shapeScore = _computeLeafShapeScore(gray);

    final checks = <bool>[];
    if (_greenRatioThreshold != null) {
      checks.add(greenRatio >= _greenRatioThreshold!);
    }
    if (_leafShapeThreshold != null) {
      checks.add(shapeScore >= _leafShapeThreshold!);
    }
    final passed = checks.isEmpty || checks.any((c) => c);

    return FrameAlignmentResult(
      passed: passed,
      greenRatio: greenRatio,
      shapeScore: shapeScore,
    );
  }

  Future<PlantPrediction> predict(File imageFile) async {
    if (_interpreter == null || _scaler == null) {
      print("[MintFinder] predict() aborted - model/scaler not loaded");
      return _invalidPrediction("Model not loaded yet", null);
    }

    print("[MintFinder] predict() start");
    final bytes = await imageFile.readAsBytes();
    print("[MintFinder] read ${bytes.length} bytes from file");

    // ── Preview decode (image package) - display only ────────────────────
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      print("[MintFinder] img.decodeImage returned null");
      return _invalidPrediction("Invalid image", null);
    }
    final cropped = _centerCropSquare(decoded);
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

    // ── Pre-filter 1: green ratio (HSV) ───────────────────────────────────
    // Mirrors mintfinder_utils.py's compute_green_ratio() exactly, so the
    // threshold loaded from fusion_thresholds.json means the same thing
    // here as it did when it was calibrated in Python.
    final greenRatio = _computeGreenRatioHsv(resized);
    print("[MintFinder] green ratio (HSV): $greenRatio");

    // ── Pre-filter 2: leaf shape (contour coverage) ───────────────────────
    final gray = cv.cvtColor(resized, cv.COLOR_BGR2GRAY);
    print("[MintFinder] cv.cvtColor (gray) done");
    final shapeScore = _computeLeafShapeScore(gray);
    print("[MintFinder] shape score: $shapeScore");

    final checks = <bool>[];
    if (_greenRatioThreshold != null) {
      checks.add(greenRatio >= _greenRatioThreshold!);
    }
    if (_leafShapeThreshold != null) {
      checks.add(shapeScore >= _leafShapeThreshold!);
    }
    final prefilterPassed = checks.isEmpty || checks.any((c) => c);

    if (!prefilterPassed) {
      print("[MintFinder] REJECTED by pre-filter (not_recognized) - "
          "model not run");
      return PlantPrediction(
        accepted: false,
        label: _rejectionMessages["not_recognized"]!,
        confidence: 0.0, // model never ran - no Branch A confidence exists
        secondBest: 0.0,
        greenRatio: greenRatio,
        shapeScore: shapeScore,
        rejectionReason: "not_recognized",
        previewBytes:
            Uint8List.fromList(img.encodeJpg(previewResized, quality: 85)),
        hue: h,
        saturation: s,
        value: v,
      );
    }

    final imageInput = _buildImageInput(gray);
    print("[MintFinder] _buildImageInput done");
    final classicalRaw = _extractClassicalFeatures(gray);
    print("[MintFinder] _extractClassicalFeatures done: $classicalRaw");
    final classicalScaled = _scaler!.transform(classicalRaw);
    print("[MintFinder] scaler.transform done");

    // Two separate output buffers now, one per branch.
    final outputA =
        List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);
    final outputB =
        List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);

    final inputs = List<Object>.filled(2, imageInput);
    inputs[_imageInputIndex] = imageInput.reshape([1, _imgSize, _imgSize, 3]);
    inputs[_classicalInputIndex] =
        Float32List.fromList(classicalScaled).reshape([1, _featureSize]);

    final outputs = <int, Object>{
      _branchAOutputIndex: outputA,
      _branchBOutputIndex: outputB,
    };
    print("[MintFinder] calling interpreter.runForMultipleInputs...");
    _interpreter!.runForMultipleInputs(inputs, outputs);
    print("[MintFinder] interpreter run done. "
        "A: ${outputA[0]}  B: ${outputB[0]}");

    final predA = (outputA[0] as List).cast<double>();
    final predB = (outputB[0] as List).cast<double>();

    final (finalIdx, finalConf, agreed) = _combinePredictions(predA, predB);
    final label = _labels[finalIdx] ?? 'unknown';
    final secondBest = () {
      final sortedA = [...predA]..sort((a, b) => b.compareTo(a));
      return sortedA.length > 1 ? sortedA[1] : 0.0;
    }();

    // Displayed confidence is now ALWAYS Branch A's own confidence in its
    // top pick - the combiner's blended finalConf is still used
    // internally (above) to decide accept/reject, but is no longer what
    // gets shown to the user.
    final branchAConfidence = predA[_argMax(predA)];

    print("[MintFinder] Branch A top: ${_labels[_argMax(predA)]} "
        "(${predA[_argMax(predA)]})  "
        "B support for A's guess: ${predB[_argMax(predA)]}  "
        "mode=$_combinerMode  agreed: $agreed  "
        "finalConf(internal): $finalConf  "
        "displayedConf(BranchA): $branchAConfidence");
    print("[MintFinder] FINAL: $label ($branchAConfidence)");

    // IMPORTANT: `agreed` can be true even when finalIdx == _unknownIdx -
    // that happens when Branch A's own top pick genuinely IS the
    // "unknown" class and Branch B supports that same belief (both
    // branches correctly agreeing this ISN'T one of the 3 species).
    // That is a real, valid "not accepted" outcome, not an accepted
    // prediction whose species happens to be named "unknown" - so
    // `accepted` must check the class itself, not just `agreed`.
    final accepted = agreed && finalIdx != _unknownIdx;
    // Merged single outcome - was previously "no_leaf_detected" vs
    // "species_unmatched" as two separate reasons. Now just one.
    final rejectionReason = accepted ? null : "not_recognized";

    return PlantPrediction(
      accepted: accepted,
      label: accepted ? label : _rejectionMessages["not_recognized"]!,
      confidence: branchAConfidence,
      secondBest: secondBest,
      greenRatio: greenRatio,
      shapeScore: shapeScore,
      rejectionReason: rejectionReason,
      previewBytes:
          Uint8List.fromList(img.encodeJpg(previewResized, quality: 85)),
      hue: h,
      saturation: s,
      value: v,
    );
  }

  /// ASYMMETRIC late fusion: Branch A (MobileNetV2) LEADS, Branch B
  /// (Hu+Canny) SUPPORTS. Direct port of combine_predictions() from
  /// train_model.py / mintfinder_utils.py - see those files for the
  /// full rationale and the gate-vs-blend trade-off explanation.
  (int, double, bool) _combinePredictions(List<double> predA, List<double> predB) {
    final topA = _argMax(predA);
    final confA = predA[topA];
    final bSupportForA = predB[topA];

    if (_combinerMode == "blend") {
      final combinedConf = _combinerWeightA * confA +
          (1 - _combinerWeightA) * bSupportForA;
      if (combinedConf >= _combinerCombinedThreshold && topA != _unknownIdx) {
        return (topA, combinedConf, true);
      } else {
        return (_unknownIdx, combinedConf, false);
      }
    }

    // mode == "gate" (default)
    if (confA >= _thresholdA &&
        bSupportForA >= _thresholdBSupport &&
        topA != _unknownIdx) {
      final combinedConf = 0.7 * confA + 0.3 * bSupportForA;
      return (topA, combinedConf, true);
    } else {
      return (_unknownIdx, confA, false);
    }
  }

  /// Green ratio via HSV, matching mintfinder_utils.py's
  /// compute_green_ratio() exactly: hue 35-85, saturation/value >= 40.
  /// Uses cv.inRange + cv.countNonZero, both confirmed present in
  /// opencv_dart's public API.
  ///
  /// NOTE: unlike Python's cv2.inRange (which accepts a raw tuple/Scalar
  /// directly), opencv_dart's inRange requires the bounds to be Mat
  /// (InputArray), not Scalar - confirmed via a compile error during
  /// testing ("argument type 'Scalar' can't be assigned to parameter
  /// type 'InputArray'"). This matches a known limitation shared by
  /// most OpenCV language bindings (e.g. the same issue exists in
  /// JavaCV). Fix: wrap each Scalar in a 1x1 Mat of the same type as
  /// the image being thresholded via Mat.fromScalar() - OpenCV
  /// broadcasts a 1x1 Mat against the full image automatically.
  double _computeGreenRatioHsv(cv.Mat resizedColor) {
    final hsv = cv.cvtColor(resizedColor, cv.COLOR_BGR2HSV);
    final lower = cv.Scalar(35, 40, 40, 0);
    final upper = cv.Scalar(85, 255, 255, 255);
    final lowerMat = cv.Mat.fromScalar(1, 1, hsv.type, lower);
    final upperMat = cv.Mat.fromScalar(1, 1, hsv.type, upper);
    final greenMask = cv.inRange(hsv, lowerMat, upperMat);
    final greenPixels = cv.countNonZero(greenMask);
    final totalPixels = _imgSize * _imgSize;
    return totalPixels == 0 ? 0.0 : greenPixels / totalPixels;
  }

  /// Leaf shape score via contour coverage, matching
  /// mintfinder_utils.py's compute_leaf_shape_score() exactly: CLAHE +
  /// Otsu -> largest external contour's area / frame area. Uses
  /// cv.findContours + cv.contourArea, both confirmed present in
  /// opencv_dart's public API.
  double _computeLeafShapeScore(cv.Mat gray) {
    final clahe = cv.createCLAHE(clipLimit: 2.0, tileGridSize: (8, 8));
    final enhanced = clahe.apply(gray);
    final (_, mask) = cv.threshold(
      enhanced, 0, 255, cv.THRESH_BINARY | cv.THRESH_OTSU,
    );

    final (contours, _) =
        cv.findContours(mask, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);
    if (contours.isEmpty) return 0.0;

    var largestArea = 0.0;
    for (final c in contours) {
      final area = cv.contourArea(c);
      if (area > largestArea) largestArea = area;
    }
    final frameArea = (_imgSize * _imgSize).toDouble();
    return frameArea == 0 ? 0.0 : largestArea / frameArea;
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

  PlantPrediction _invalidPrediction(String message, String? reason) {
    return PlantPrediction(
      accepted: false,
      label: message,
      confidence: 0,
      secondBest: 0,
      greenRatio: 0,
      shapeScore: 0,
      rejectionReason: reason,
      previewBytes: Uint8List(0),
      hue: 0,
      saturation: 0,
      value: 0,
    );
  }

  void close() => _interpreter?.close();
}