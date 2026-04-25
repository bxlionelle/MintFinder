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

  // Helper to clean the label into a key for plantInfo lookup
  String _normalizeLabel(String rawLabel) {
    return rawLabel
        .toLowerCase()
        .replaceFirst(RegExp(r'^\d+\s+'), '') // Removes "0 ", "1 ", etc.
        .replaceAll(' ', '_')                 // "lemon basil" -> "lemon_basil"
        .trim();
  }

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.85) return Colors.greenAccent;
    if (confidence >= 0.65) return Colors.yellowAccent;
    return Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    final String cleanKey = _normalizeLabel(label);
    final data = plantInfo[cleanKey];

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
          ? _buildErrorState(cleanKey)
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Hero image ────────────────────────────────────────
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
                      // Gradient overlay
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
                      // Confidence badge
                      Positioned(
                        top: 14,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

                  // ── Plant Name Card ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
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
                          Row(
                            children: [
                              const Text(
                                "Confidence Score",
                                style: TextStyle(color: Colors.white70, fontSize: 13),
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
                              valueColor: AlwaysStoppedAnimation<Color>(confColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── About ─────────────────────────────────────────────
                  _buildSectionCard(
                    title: "About",
                    icon: Icons.info_outline,
                    content: Text(
                      data['description'],
                      style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Uses / Remedies ───────────────────────────────────
                  if (data['uses'] != null)
                    _buildSectionCard(
                      title: "Uses / Remedies",
                      icon: Icons.healing_outlined,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: (data['uses'] as List).map((use) => _BulletRow(text: use)).toList(),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // ── Safety Measures ───────────────────────────────────
                  if (data['safetyMeasures'] != null)
                    _buildSectionCard(
                      title: "⚠ Safety Measures",
                      icon: Icons.warning_amber_rounded,
                      iconColor: Colors.orangeAccent,
                      titleColor: Colors.orangeAccent,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: (data['safetyMeasures'] as List)
                            .map((s) => _BulletRow(text: s, bulletColor: Colors.orangeAccent))
                            .toList(),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // ── Common Names ──────────────────────────────────────
                  _buildSectionCard(
                    title: "Common Names",
                    icon: Icons.label_outline,
                    content: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (data['otherNames'] as List)
                          .map((name) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: Text(
                                  name,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                ),
                              ))
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget content,
    Color iconColor = Colors.white70,
    Color titleColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String attemptedKey) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, color: Colors.white30, size: 64),
          const SizedBox(height: 16),
          const Text(
            "Plant data not found",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            "Looked for key: '$attemptedKey'",
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Reusable bullet row ───────────────────────────────────────────────────────
class _BulletRow extends StatelessWidget {
  final String text;
  final Color bulletColor;

  const _BulletRow({required this.text, this.bulletColor = Colors.white70});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: CircleAvatar(radius: 3, backgroundColor: bulletColor),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}