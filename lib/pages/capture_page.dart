// capture_page.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart';
import '../services/classifier_service.dart';
import 'result_page.dart';
import 'help_page.dart';

class CapturePage extends StatefulWidget {
  const CapturePage({super.key});

  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  final ImagePicker _picker = ImagePicker();
  final PlantClassifierService _classifier = PlantClassifierService();

  bool _loading = true;
  bool _modelReady = false; // ← NEW: tracks if model finished loading
  bool _predicting = false;
  Uint8List? _previewBytes;

  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _initAll();
  }

  Future<void> _initAll() async {
    // Initialize camera and model in parallel for faster startup.
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await Future.wait([
      _cameraController!.initialize(),
      _classifier.loadModel(),
    ]);

    if (!mounted) return;

    setState(() {
      _loading = false;
      _modelReady = true; // ← both camera and model are ready
      print("Camera and model ready");
    });
  }

  // ── Camera capture ────────────────────────────────────────────────
  Future<void> _captureFromCamera() async {
    if (!_modelReady) {
      _showNotReadySnackbar();
      return;
    }
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _predicting = true;
      _previewBytes = null;
    });

    _scanController.repeat();
    await Future.delayed(const Duration(milliseconds: 60));

    final photo = await _cameraController!.takePicture();
    final file = File(photo.path);

    await _processImage(file, deleteAfter: true);
  }

  // ── Gallery pick ──────────────────────────────────────────────────
  Future<void> _pickFromGallery() async {
    if (!_modelReady) {
      _showNotReadySnackbar();
      return;
    }

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1280,
      maxHeight: 1280,
    );

    if (picked == null) return;

    setState(() {
      _predicting = true;
      _previewBytes = null;
    });

    _scanController.repeat();
    await Future.delayed(const Duration(milliseconds: 60));

    await _processImage(File(picked.path), deleteAfter: false);
  }

  // ── Core image processing ─────────────────────────────────────────
  Future<void> _processImage(File file, {required bool deleteAfter}) async {
    try {
      final prediction = await _classifier.predict(file);

      if (!mounted) return;

      setState(() {
        _previewBytes = prediction.previewBytes;
        _predicting = false;
      });

      _scanController.stop();

      final String cleanKey = prediction.label
          .toLowerCase()
          .replaceFirst(RegExp(r'^\d+\s+'), '')
          .replaceAll(' ', '_')
          .trim();

      if (!prediction.accepted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF2E4F10),
            title: const Text(
              "Not Recognized",
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              "Could not identify the plant clearly. Please try again with a clear leaf image.\n\n"
              "Confidence: ${(prediction.confidence * 100).toStringAsFixed(1)}%\n"
              "Green ratio: ${(prediction.greenRatio * 100).toStringAsFixed(1)}%",
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "OK",
                  style: TextStyle(color: Colors.lightGreenAccent),
                ),
              ),
            ],
          ),
        );

        if (!mounted) return;
        setState(() => _previewBytes = null);
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(
            label: cleanKey,
            confidence: prediction.confidence,
            previewBytes: prediction.previewBytes,
          ),
        ),
      );

      if (!mounted) return;
      setState(() => _previewBytes = null);
    } finally {
      if (deleteAfter) {
        try {
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
      if (mounted) {
        setState(() => _predicting = false);
      }
      _scanController.stop();
    }
  }

  // ── Snackbar shown when buttons are tapped before model is ready ──
  void _showNotReadySnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Model is still loading, please wait..."),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF2E4F10),
      ),
    );
  }

  // ── Navigate to the full Help page ───────────────────────────────
  void _openHelpPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HelpPage()),
    );
  }

  // ── Camera preview ────────────────────────────────────────────────
  Widget _buildSquarePreview() {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return CameraPreview(_cameraController!);
  }

  // ── Scanning animation overlay ────────────────────────────────────
  Widget _buildScannerOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _scanController,
          builder: (_, __) {
            final y = constraints.maxHeight * _scanController.value;
            return Stack(
              children: [
                Container(color: Colors.black.withOpacity(0.25)),
                Positioned(
                  top: y,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.lightGreenAccent,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.lightGreenAccent.withOpacity(0.8),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    "AI ANALYZING...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _classifier.close();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF456F1F),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                "Loading model...",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF456F1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF456F1F),
        elevation: 0,
        title: const Text(
          "Identify Plant",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: double.infinity,
                  color: Colors.black12,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_previewBytes != null && _previewBytes!.isNotEmpty)
                        Image.memory(_previewBytes!, fit: BoxFit.cover)
                      else
                        _buildSquarePreview(),
                      if (_predicting) _buildScannerOverlay(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Center the leaf in the frame",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          _buildActionButtonBar(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildActionButtonBar() {
    // Buttons are visually dimmed while predicting OR model not ready.
    final bool buttonsEnabled = !_predicting && _modelReady;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _iconActionButton(
            icon: Icons.image_search_outlined,
            label: "Gallery",
            onTap: buttonsEnabled ? _pickFromGallery : null,
          ),
          _captureButton(enabled: buttonsEnabled),
          _iconActionButton(
            icon: Icons.info_outline,
            label: "Help",
            onTap: _openHelpPage, // help is always accessible
          ),
        ],
      ),
    );
  }

  Widget _iconActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final bool enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4, // dim when disabled
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _captureButton({bool enabled = true}) {
    return GestureDetector(
      onTap: enabled ? _captureFromCamera : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4, // dim when disabled
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt,
              color: Color(0xFF456F1F),
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}