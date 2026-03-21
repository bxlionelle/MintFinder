import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../data/plant_info.dart';

class ResultPage extends StatelessWidget {
  final String label;
  final double confidence;
  final Uint8List previewBytes;

  const ResultPage({
    super.key,
    required this.label,
    required this.confidence,
    required this.previewBytes,
  });

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.85) return Colors.greenAccent;
    if (confidence >= 0.65) return Colors.yellowAccent;
    return Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    final data = plantInfo[label];
    final screenWidth = MediaQuery.of(context).size.width;
    final confColor = _confidenceColor(confidence);
    final confPercent = confidence * 100;

    return Scaffold(
      backgroundColor: const Color(0xFF2E4F10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E4F10),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Result",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: data == null
          ? const Center(
              child: Text(
                "No plant information found",
                style: TextStyle(color: Colors.white70),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── Hero image (full width, tall) ─────────────────────
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                        child: Image.memory(
                          previewBytes,
                          width: screenWidth,
                          height: 300,
                          fit: BoxFit.cover,
                        ),
                      ),

                      // Gradient overlay at bottom of image
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(32),
                              bottomRight: Radius.circular(32),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.6),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Confidence badge on top-right of image
                      Positioned(
                        top: 14,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, color: confColor, size: 16),
                              const SizedBox(width: 5),
                              Text(
                                "${confPercent.toStringAsFixed(1)}%",
                                style: TextStyle(
                                  color: confColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Plant name card ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            data['name'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['scientific'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.greenAccent.withOpacity(0.85),
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                            ),
                          ),

                          const SizedBox(height: 16),
                          Divider(color: Colors.white.withOpacity(0.15)),
                          const SizedBox(height: 16),

                          // Confidence bar
                          Row(
                            children: [
                              const Text(
                                "Confidence",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "${confPercent.toStringAsFixed(2)}%",
                                style: TextStyle(
                                  color: confColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: confidence,
                              minHeight: 8,
                              backgroundColor: Colors.white.withOpacity(0.15),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(confColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Description card ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.info_outline,
                                  color: Colors.white70, size: 18),
                              SizedBox(width: 8),
                              Text(
                                "About",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            data['description'],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Other names card ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.label_outline,
                                  color: Colors.white70, size: 18),
                              SizedBox(width: 8),
                              Text(
                                "Other Names",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (data['otherNames'] as List)
                                .map(
                                  (e) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Text(
                                      e,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}