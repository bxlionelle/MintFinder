// capture_page.dart
import 'dart:async';
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
  bool _predicting = false;
  Uint8List? _previewBytes;

  late AnimationController _scanController;

  // ── Focus (tap-to-focus) state ──────────────────────────────────────────
  Offset? _focusIndicatorPosition; // in preview-local coordinates
  Timer? _focusIndicatorTimer;

  // ── Exposure / brightness state ─────────────────────────────────────────
  double _minExposureOffset = 0.0;
  double _maxExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;

  // ── Zoom state ───────────────────────────────────────────────────────────
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;
  double _baseZoomOnGestureStart = 1.0;
  bool _showZoomIndicator = false;
  Timer? _zoomIndicatorTimer;

  // ── Flash state ──────────────────────────────────────────────────────────
  bool _flashOn = false;

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

    // Real exposure-offset range this device/camera supports.
    try {
      _minExposureOffset = await _cameraController!.getMinExposureOffset();
      _maxExposureOffset = await _cameraController!.getMaxExposureOffset();
    } catch (_) {
      _minExposureOffset = 0.0;
      _maxExposureOffset = 0.0;
    }
    _currentExposureOffset = 0.0;

    // Real zoom range this device/camera supports.
    try {
      _minZoom = await _cameraController!.getMinZoomLevel();
      _maxZoom = await _cameraController!.getMaxZoomLevel();
    } catch (_) {
      _minZoom = 1.0;
      _maxZoom = 1.0;
    }
    _currentZoom = _minZoom;

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
        final isNoLeaf = prediction.rejectionReason == "no_leaf_detected";

        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF2E4F10),
            title: Text(
              isNoLeaf ? "No Leaf Detected" : "Not Recognized",
              style: const TextStyle(color: Colors.white),
            ),
            content: Text(
              "${prediction.label}\n\n"
              "Confidence: ${(prediction.confidence * 100).toStringAsFixed(1)}%\n"
              "Green ratio: ${(prediction.greenRatio * 100).toStringAsFixed(1)}%\n"
              "Shape coverage: ${(prediction.shapeScore * 100).toStringAsFixed(1)}%",
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK",
                    style: TextStyle(color: Colors.lightGreenAccent)),
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
            accepted: true,
            rejectionReason: null,
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

  void _openHelpPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HelpPage()),
    );
  }

  // ── Tap-to-focus ─────────────────────────────────────────────────────────
  Future<void> _onTapToFocus(Offset localPosition, Size previewSize) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    final normalized = Offset(
      (localPosition.dx / previewSize.width).clamp(0.0, 1.0),
      (localPosition.dy / previewSize.height).clamp(0.0, 1.0),
    );

    try {
      await _cameraController!.setFocusPoint(normalized);
      await _cameraController!.setExposurePoint(normalized);
    } catch (_) {}

    _focusIndicatorTimer?.cancel();
    setState(() => _focusIndicatorPosition = localPosition);
    _focusIndicatorTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _focusIndicatorPosition = null);
    });
  }

  // ── Pinch-to-zoom ────────────────────────────────────────────────────────
  void _onScaleStart(ScaleStartDetails details) {
    _baseZoomOnGestureStart = _currentZoom;
  }

  Future<void> _onScaleUpdate(ScaleUpdateDetails details) async {
    if (_cameraController == null || _maxZoom <= _minZoom) return;
    final newZoom =
        (_baseZoomOnGestureStart * details.scale).clamp(_minZoom, _maxZoom);
    if ((newZoom - _currentZoom).abs() < 0.01) return;

    setState(() {
      _currentZoom = newZoom;
      _showZoomIndicator = true;
    });
    try {
      await _cameraController!.setZoomLevel(newZoom);
    } catch (_) {}

    _zoomIndicatorTimer?.cancel();
    _zoomIndicatorTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _showZoomIndicator = false);
    });
  }

  // ── Flash toggle ─────────────────────────────────────────────────────────
  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    final turnOn = !_flashOn;
    try {
      await _cameraController!
          .setFlashMode(turnOn ? FlashMode.torch : FlashMode.off);
      setState(() => _flashOn = turnOn);
    } catch (_) {}
  }

  Widget _buildSquarePreview() {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return CameraPreview(_cameraController!);
  }

  /// A leaf-shaped outline guide - no dark vignette, just a clean stroke
  /// (with a soft dark backing stroke for visibility over any live
  /// background) plus a faint midrib line down the center.
  Widget _buildFrameGuide() {
    return const IgnorePointer(
      child: CustomPaint(
        painter: _LeafFrameGuidePainter(),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildFocusIndicator() {
    if (_focusIndicatorPosition == null) return const SizedBox.shrink();
    final pos = _focusIndicatorPosition!;
    return Positioned(
      left: pos.dx - 34,
      top: pos.dy - 34,
      child: IgnorePointer(
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.yellowAccent, width: 1.5),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  Widget _buildExposureSlider() {
    if (_maxExposureOffset <= _minExposureOffset) {
      return const SizedBox.shrink();
    }
    return Positioned(
      right: 6,
      top: 20,
      bottom: 20,
      child: IgnorePointer(
        ignoring: false,
        child: Column(
          children: [
            const Icon(Icons.wb_sunny, color: Colors.white70, size: 16),
            Expanded(
              child: RotatedBox(
                quarterTurns: 3,
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: SliderComponentShape.noOverlay,
                    activeTrackColor: Colors.lightGreenAccent,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: _currentExposureOffset.clamp(
                        _minExposureOffset, _maxExposureOffset),
                    min: _minExposureOffset,
                    max: _maxExposureOffset,
                    onChanged: (v) async {
                      setState(() => _currentExposureOffset = v);
                      try {
                        await _cameraController?.setExposureOffset(v);
                      } catch (_) {}
                    },
                  ),
                ),
              ),
            ),
            const Icon(Icons.wb_sunny_outlined,
                color: Colors.white38, size: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomIndicator() {
    if (!_showZoomIndicator) return const SizedBox.shrink();
    return Positioned(
      top: 12,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "${_currentZoom.toStringAsFixed(1)}x",
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
        ),
      ),
    );
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
    _focusIndicatorTimer?.cancel();
    _zoomIndicatorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF456F1F),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF456F1F),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 56),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.lightGreenAccent, width: 2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                color: Colors.black12,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final previewSize = Size(
                                        constraints.maxWidth,
                                        constraints.maxHeight);
                                    final liveFeedActive =
                                        _previewBytes == null && !_predicting;

                                    return GestureDetector(
                                      onTapUp: liveFeedActive
                                          ? (details) => _onTapToFocus(
                                              details.localPosition,
                                              previewSize)
                                          : null,
                                      onScaleStart:
                                          liveFeedActive ? _onScaleStart : null,
                                      onScaleUpdate: liveFeedActive
                                          ? _onScaleUpdate
                                          : null,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          if (_previewBytes != null)
                                            Image.memory(_previewBytes!,
                                                fit: BoxFit.cover)
                                          else
                                            _buildSquarePreview(),
                                          if (liveFeedActive)
                                            _buildFrameGuide(),
                                          if (liveFeedActive)
                                            _buildExposureSlider(),
                                          if (liveFeedActive)
                                            _buildFocusIndicator(),
                                          if (liveFeedActive)
                                            _buildZoomIndicator(),
                                          if (_predicting)
                                            _buildScannerOverlay(),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildBottomIconRow(),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  "Position the leaf within the frame",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 20),
              ],
            ),
            _buildTopFloatingButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopFloatingButtons() {
    return Positioned(
      top: 8,
      left: 28,
      right: 28,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF2E4F10),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          GestureDetector(
            onTap: _openHelpPage,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF456F1F),
                border: Border.all(color: Colors.lightGreenAccent, width: 2),
              ),
              child: const Icon(Icons.question_mark,
                  color: Colors.lightGreenAccent, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomIconRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _outlineIconButton(
          icon: Icons.photo_library_outlined,
          shape: BoxShape.rectangle,
          onTap: _predicting ? null : _pickFromGallery,
        ),
        _captureButton(),
        _outlineIconButton(
          icon: _flashOn ? Icons.flash_on : Icons.flash_off,
          onTap: _toggleFlash,
          highlighted: _flashOn,
        ),
      ],
    );
  }

  Widget _outlineIconButton({
    required IconData icon,
    VoidCallback? onTap,
    BoxShape shape = BoxShape.circle,
    bool highlighted = false,
  }) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: shape,
            borderRadius:
                shape == BoxShape.rectangle ? BorderRadius.circular(10) : null,
            border: Border.all(
              color: highlighted ? Colors.yellowAccent : Colors.white,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: highlighted ? Colors.yellowAccent : Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _captureButton() {
    return GestureDetector(
      onTap: _predicting ? null : _captureFromCamera,
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
          child: const Icon(Icons.camera_alt,
              color: Color(0xFF456F1F), size: 30),
        ),
      ),
    );
  }
}

/// Leaf-shaped outline guide (pointed tip, wide middle, tapered base at
/// a small "stem" point), drawn directly over the live feed with no
/// dark vignette - a soft dark backing stroke plus a white outline on
/// top for visibility over any background, and a faint midrib line.
class _LeafFrameGuidePainter extends CustomPainter {
  const _LeafFrameGuidePainter();

  Path _buildLeafPath(Rect bounds) {
    final path = Path();
    final cx = bounds.center.dx;
    final top = bounds.top;
    final bottom = bounds.bottom;
    final halfW = bounds.width / 2;
    final h = bounds.height;

    path.moveTo(cx, top);
    path.cubicTo(
      cx + halfW * 1.05, top + h * 0.12,
      cx + halfW,        top + h * 0.52,
      cx,                bottom,
    );
    path.cubicTo(
      cx - halfW,        top + h * 0.52,
      cx - halfW * 1.05, top + h * 0.12,
      cx, top,
    );
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final bounds = Rect.fromCenter(
      center: center,
      width: size.width * 0.68,
      height: size.height * 0.58,
    );
    final leafPath = _buildLeafPath(bounds);

    // Soft dark backing stroke for visibility over light backgrounds...
    canvas.drawPath(
      leafPath,
      Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    // ...then a crisp white outline on top, visible over dark backgrounds.
    canvas.drawPath(
      leafPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );

    // Faint midrib guide line down the center.
    canvas.drawLine(
      Offset(center.dx, bounds.top + bounds.height * 0.10),
      Offset(center.dx, bounds.bottom - bounds.height * 0.05),
      Paint()
        ..color = Colors.white.withOpacity(0.85)
        ..strokeWidth = 3.5,
    );
  }

  @override
  bool shouldRepaint(covariant _LeafFrameGuidePainter oldDelegate) => false;
}