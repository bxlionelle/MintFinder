// Replaces scikit-learn's StandardScaler. Loads the mean/scale arrays
// exported by train_model.py (scaler.json) and applies the same
// (x - mean) / scale transform used during training.

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class FeatureScaler {
  final int featureSize;
  final List<double> mean;
  final List<double> scale;

  FeatureScaler({
    required this.featureSize,
    required this.mean,
    required this.scale,
  });

  static Future<FeatureScaler> loadFromAsset(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> j = jsonDecode(raw);
    return FeatureScaler(
      featureSize: j['feature_size'] as int,
      mean: (j['mean'] as List).map((e) => (e as num).toDouble()).toList(),
      scale: (j['scale'] as List).map((e) => (e as num).toDouble()).toList(),
    );
  }

  List<double> transform(List<double> raw) {
    if (raw.length != featureSize) {
      throw ArgumentError('Expected $featureSize features, got ${raw.length}');
    }
    return List<double>.generate(featureSize, (i) {
      final s = scale[i];
      return s == 0 ? 0.0 : (raw[i] - mean[i]) / s;
    });
  }
}