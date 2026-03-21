// capture_page.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart';
import '../services/classifier_service.dart';
import 'result_page.dart';

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
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _cameraController!.initialize();
    await _classifier.loadModel();

    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  Future<void> _captureFromCamera() async {
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

  Future<void> _pickFromGallery() async {
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

  Future<void> _processImage(File file, {required bool deleteAfter}) async {
    try {
      final prediction = await _classifier.predict(file);

      if (!mounted) return;

      setState(() {
        _previewBytes = prediction.previewBytes;
        _predicting = false;
      });

      _scanController.stop();

      if (!prediction.accepted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Not Recognized"),
            content: Text(
              "Not recognized. Please capture a clear leaf image.\n\n"
              "Confidence: ${(prediction.confidence * 100).toStringAsFixed(2)}%\n"
              "Green ratio: ${(prediction.greenRatio * 100).toStringAsFixed(2)}%",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );

        if (!mounted) return;
        setState(() {
          _previewBytes = null;
        });
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(
            label: prediction.label,
            confidence: prediction.confidence,
            previewBytes: prediction.previewBytes,
          ),
        ),
      );

      if (!mounted) return;
      setState(() {
        _previewBytes = null;
      });
    } finally {
      if (deleteAfter) {
        try {
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _predicting = false;
        });
      }
      _scanController.stop();
    }
  }

  Widget _buildSquarePreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return CameraPreview(_cameraController!);
  }

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
                    "Scanning...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF456F1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF456F1F),
        elevation: 0,
        title: const Text(
          "Capture Leaf",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // ── Camera Preview (fills available space) ──────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_previewBytes != null)
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

          const SizedBox(height: 12),

          // ── Hint text ───────────────────────────────────────────
          const Text(
            "Point at a leaf and tap capture",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),

          const SizedBox(height: 8),

          // ── Bottom action bar ───────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery button
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      iconSize: 54,
                      color: Colors.white,
                      onPressed: _predicting ? null : _pickFromGallery,
                      icon: const Icon(Icons.image_outlined),
                    ),
                    const Text(
                      "Gallery",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),

                // Capture button
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _predicting ? null : _captureFromCamera,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white54,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Color(0xFF456F1F),
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Capture",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}