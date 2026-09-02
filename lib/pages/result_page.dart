import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ADD
import '../data/plant_info.dart';

class ResultPage extends StatefulWidget {
  final String label;
  final double confidence;
  final Uint8List previewBytes;

  // NEW: from PlantPrediction. `accepted` decides up front whether to try
  // a plantInfo lookup at all - when false, `label` is a full sentence
  // (the rejection message), not a short class key, so we must NOT run
  // it through _normalizeLabel()/plantInfo lookup like before, or it
  // renders as a garbled "key not found" error instead of the intended
  // friendly message.
  final bool accepted;
  final String? rejectionReason; // "no_leaf_detected" | "species_unmatched" | null

  const ResultPage({
    super.key,
    required this.label,
    required this.confidence,
    required this.previewBytes,
    required this.accepted,
    this.rejectionReason,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  @override
  void initState() {
    super.initState();
    // NOTE: this writes every scan to Firestore, including rejected
    // ones. This is live network activity on every scan - worth
    // confirming this is intentional given the thesis's stated
    // offline-only requirement, or gating it behind an explicit
    // opt-in/connectivity check.
    _saveScanToFirebase();
  }

  Future<void> _saveScanToFirebase() async {
    await FirebaseFirestore.instance.collection('scan_history').add({
      'label': widget.label,
      'confidence': widget.confidence,
      'accepted': widget.accepted,
      'rejectionReason': widget.rejectionReason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  String _normalizeLabel(String rawLabel) {
    return rawLabel
        .toLowerCase()
        .replaceFirst(RegExp(r'^\d+\s+'), '')
        .replaceAll(' ', '_')
        .trim();
  }

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.85) return Colors.greenAccent;
    if (confidence >= 0.65) return Colors.yellowAccent;
    return Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final confColor = _confidenceColor(widget.confidence);
    final confPercent = widget.confidence * 100;

    // Only attempt a plantInfo lookup when the model actually accepted a
    // species. When rejected, `widget.label` holds the full human-readable
    // rejection message and must never be run through _normalizeLabel().
    final data = widget.accepted
        ? plantInfo[_normalizeLabel(widget.label)]
        : null;

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
      body: !widget.accepted
          ? _buildNotRecognizedState()
          : data == null
              ? _buildErrorState(_normalizeLabel(widget.label))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(32),
                              bottomRight: Radius.circular(32),
                            ),
                            child: Image.memory(
                              widget.previewBytes,
                              width: screenWidth,
                              height: 300,
                              fit: BoxFit.cover,
                            ),
                          ),
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
                                  value: widget.confidence,
                                  minHeight: 8,
                                  backgroundColor: Colors.white.withOpacity(0.15),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    confColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (data['description'] != null)
                        _buildSectionCard(
                          title: "About",
                          icon: Icons.info_outline,
                          content: Text(
                            data['description'],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      if (data['uses'] != null)
                        _buildSectionCard(
                          title: "Uses / Remedies",
                          icon: Icons.healing_outlined,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: (data['uses'] as List)
                                .map((use) => _BulletRow(text: use))
                                .toList(),
                          ),
                        ),

                      const SizedBox(height: 16),

                      if (data['safetyMeasures'] != null)
                        _buildSectionCard(
                          title: "⚠ Safety Measures",
                          icon: Icons.warning_amber_rounded,
                          iconColor: Colors.orangeAccent,
                          titleColor: Colors.orangeAccent,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: (data['safetyMeasures'] as List)
                                .map(
                                  (s) => _BulletRow(
                                    text: s,
                                    bulletColor: Colors.orangeAccent,
                                  ),
                                )
                                .toList(),
                          ),
                        ),

                      const SizedBox(height: 16),

                      _buildSectionCard(
                        title: "Common Names",
                        icon: Icons.label_outline,
                        content: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (data['otherNames'] as List)
                              .map(
                                (name) => Container(
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
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )
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

  /// Shown when the model rejected the image (accepted == false). Uses
  /// widget.label directly - which is now the full, friendly rejection
  /// message from classifier_service.dart's _rejectionMessages map - and
  /// picks an icon based on WHY it was rejected, so the two failure modes
  /// (no leaf detected at all vs. leaf detected but species unmatched)
  /// read as visually distinct, not identical generic "error" screens.
  Widget _buildNotRecognizedState() {
    final isNoLeaf = widget.rejectionReason == "no_leaf_detected";
    final icon = isNoLeaf ? Icons.photo_camera_back_outlined : Icons.help_outline;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white38, size: 64),
            const SizedBox(height: 20),
            Text(
              isNoLeaf ? "No Leaf Detected" : "Species Not Recognized",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              widget.label, // the full rejection message
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
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
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}