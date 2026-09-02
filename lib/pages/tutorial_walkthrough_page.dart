// ═══════════════════════════════════════════════════════════════════
//  APP FLOW MAP
//
//   ReminderPage
//         |
//         v
//   TutorialWalkthroughPage  <-- YOU ARE HERE
//     (real camera - demo capture, demo upload, real zoom/focus/
//      brightness. Vibrates + asks to retry if the captured/picked
//      photo fails the SAME green-ratio/shape checks the real
//      capture flow uses.)
//         |
//    calls AppSettings.markOnboardingComplete()
//         |
//         v
//   MenuPage
// ═══════════════════════════════════════════════════════════════════
import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:image_picker/image_picker.dart';

import '../main.dart';
import '../services/classifier_service.dart';
import 'skeu_theme.dart';
import 'app_settings.dart';
import 'menu_page.dart';

enum _TutStep { captureDemo, uploadDemo, controlsInfo, finish }

class TutorialWalkthroughPage extends StatefulWidget {
  const TutorialWalkthroughPage({super.key});

  @override
  State<TutorialWalkthroughPage> createState() =>
      _TutorialWalkthroughPageState();
}

class _TutorialWalkthroughPageState extends State<TutorialWalkthroughPage> {
  CameraController? _cameraController;
  final PlantClassifierService _classifier = PlantClassifierService();
  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  bool _checking = false;
  _TutStep _step = _TutStep.captureDemo;

  // null = no feedback shown; true = success (green); false = error (red)
  bool? _feedbackIsSuccess;
  String? _feedbackTextKey;

  double _minExposureOffset = 0.0;
  double _maxExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;

  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;
  double _baseZoomOnGestureStart = 1.0;
  bool _showZoomIndicator = false;
  Timer? _zoomIndicatorTimer;

  Offset? _focusIndicatorPosition;
  Timer? _focusIndicatorTimer;

  @override
  void initState() {
    super.initState();
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

    try {
      _minExposureOffset = await _cameraController!.getMinExposureOffset();
      _maxExposureOffset = await _cameraController!.getMaxExposureOffset();
    } catch (_) {
      _minExposureOffset = 0.0;
      _maxExposureOffset = 0.0;
    }
    _currentExposureOffset = 0.0;

    try {
      _minZoom = await _cameraController!.getMinZoomLevel();
      _maxZoom = await _cameraController!.getMaxZoomLevel();
    } catch (_) {
      _minZoom = 1.0;
      _maxZoom = 1.0;
    }
    _currentZoom = _minZoom;

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _runAlignmentCheck(File file, {required bool isCapture}) async {
    setState(() {
      _checking = true;
      _feedbackIsSuccess = null;
      _feedbackTextKey = null;
    });

    final result = await _classifier.checkFrameAlignment(file);

    if (!mounted) return;

    if (result.passed) {
      HapticFeedback.lightImpact();
      setState(() {
        _checking = false;
        _feedbackIsSuccess = true;
        _feedbackTextKey =
            isCapture ? "tut_capture_success" : "tut_upload_success";
      });
      // Give the user a moment to see the success message, then
      // advance to the next step.
      Timer(const Duration(milliseconds: 1100), () {
        if (!mounted) return;
        setState(() {
          _feedbackIsSuccess = null;
          _feedbackTextKey = null;
          _step = isCapture ? _TutStep.uploadDemo : _TutStep.controlsInfo;
        });
      });
    } else {
      // Real vibration alert, per request, when the photo doesn't
      // pass the SAME green-ratio/shape checks the real capture flow
      // uses - not a fake/illustrative check.
      HapticFeedback.heavyImpact();
      setState(() {
        _checking = false;
        _feedbackIsSuccess = false;
        _feedbackTextKey =
            isCapture ? "tut_capture_retry" : "tut_upload_retry";
      });
    }
  }

  Future<void> _demoCapture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    final photo = await _cameraController!.takePicture();
    final file = File(photo.path);
    await _runAlignmentCheck(file, isCapture: true);
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<void> _demoUpload() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (picked == null) return;
    await _runAlignmentCheck(File(picked.path), isCapture: false);
  }

  void _finishOnboarding() {
    AppSettings.instance.markOnboardingComplete();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MenuPage()),
    );
  }

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

  @override
  void dispose() {
    _cameraController?.dispose();
    _classifier.close();
    _focusIndicatorTimer?.cancel();
    _zoomIndicatorTimer?.cancel();
    super.dispose();
  }

  Widget _buildExposureSlider() {
    if (_maxExposureOffset <= _minExposureOffset) return const SizedBox.shrink();
    return Positioned(
      right: 6,
      top: 20,
      bottom: 20,
      child: Column(
        children: [
          const Icon(Icons.wb_sunny, color: Colors.white70, size: 16),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
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
          const Icon(Icons.wb_sunny_outlined, color: Colors.white38, size: 12),
        ],
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
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
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

  Widget _buildInstructionBanner(AppSettings s) {
    String textKey;
    switch (_step) {
      case _TutStep.captureDemo:
        textKey = "tut_capture_instruction";
        break;
      case _TutStep.uploadDemo:
        textKey = "tut_upload_instruction";
        break;
      case _TutStep.controlsInfo:
        textKey = "tut_controls_body";
        break;
      case _TutStep.finish:
        textKey = "tut_finish";
        break;
    }

    final showingFeedback = _feedbackTextKey != null;
    final bannerColor = showingFeedback
        ? (_feedbackIsSuccess == true
            ? Colors.green.withOpacity(0.85)
            : Colors.red.withOpacity(0.8))
        : Colors.black.withOpacity(0.55);

    return Positioned(
      left: 12,
      right: 12,
      top: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bannerColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          _checking
              ? s.t("checking")
              : s.t(showingFeedback ? _feedbackTextKey! : textKey),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: s.scaled(14),
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildActionArea(AppSettings s) {
    switch (_step) {
      case _TutStep.captureDemo:
        return GestureDetector(
          onTap: _checking ? null : _demoCapture,
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
                  color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt,
                  color: Color(0xFF456F1F), size: 30),
            ),
          ),
        );
      case _TutStep.uploadDemo:
        return GestureDetector(
          onTap: _checking ? null : _demoUpload,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_library_outlined,
                    color: Color(0xFF456F1F)),
                const SizedBox(width: 10),
                Text(
                  s.language == "tl" ? "Piliin Larawan" : "Choose Photo",
                  style: TextStyle(
                    color: const Color(0xFF456F1F),
                    fontWeight: FontWeight.bold,
                    fontSize: s.scaled(15),
                  ),
                ),
              ],
            ),
          ),
        );
      case _TutStep.controlsInfo:
        return SkeuButton(
          label: s.t("next"),
          fontSize: s.scaled(17),
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
          onPressed: () => setState(() => _step = _TutStep.finish),
        );
      case _TutStep.finish:
        return SkeuButton(
          label: s.t("got_it"),
          fontSize: s.scaled(17),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          onPressed: _finishOnboarding,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF456F1F),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final s = AppSettings.instance;
        return Scaffold(
          backgroundColor: const Color(0xFF456F1F),
          body: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        s.t("skip"),
                        style:
                            TextStyle(color: Colors.white70, fontSize: s.scaled(14)),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.lightGreenAccent, width: 2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          color: Colors.black12,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final previewSize = Size(
                                  constraints.maxWidth, constraints.maxHeight);
                              return GestureDetector(
                                onTapUp: (details) => _onTapToFocus(
                                    details.localPosition, previewSize),
                                onScaleStart: _onScaleStart,
                                onScaleUpdate: _onScaleUpdate,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CameraPreview(_cameraController!),
                                    _buildExposureSlider(),
                                    _buildFocusIndicator(),
                                    _buildZoomIndicator(),
                                    _buildInstructionBanner(s),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: _buildActionArea(s),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}