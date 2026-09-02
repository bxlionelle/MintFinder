import 'package:flutter/material.dart';
import 'skeu_theme.dart';
import 'app_settings.dart';
import 'menu_page.dart';

class TutorialWalkthroughPage extends StatefulWidget {
  const TutorialWalkthroughPage({super.key});

  @override
  State<TutorialWalkthroughPage> createState() =>
      _TutorialWalkthroughPageState();
}

class _TutorialWalkthroughPageState extends State<TutorialWalkthroughPage> {
  final _controller = PageController();
  int _page = 0;

  // Each step maps directly to a real control in capture_page.dart:
  // the leaf frame guide, tap-to-focus/pinch-zoom, the shutter button,
  // and the gallery upload button.
  static const _steps = [
    (
      icon: Icons.filter_vintage_outlined,
      titleKey: "tutorial_step1_title",
      bodyKey: "tutorial_step1_body",
    ),
    (
      icon: Icons.touch_app_outlined,
      titleKey: "tutorial_step2_title",
      bodyKey: "tutorial_step2_body",
    ),
    (
      icon: Icons.camera_alt_outlined,
      titleKey: "tutorial_step3_title",
      bodyKey: "tutorial_step3_body",
    ),
    (
      icon: Icons.photo_library_outlined,
      titleKey: "tutorial_step4_title",
      bodyKey: "tutorial_step4_body",
    ),
  ];

  void _finish() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MenuPage()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPaper,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: AppSettings.instance,
          builder: (context, _) {
            final s = AppSettings.instance;
            return Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextButton(
                      onPressed: _finish,
                      child: Text(
                        s.t("skip"),
                        style: TextStyle(
                            color: kGreenDark, fontSize: s.scaled(14)),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _steps.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) {
                      final step = _steps[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: kGreenMid.withOpacity(0.12),
                                border: Border.all(color: kGreenMid, width: 2),
                              ),
                              child:
                                  Icon(step.icon, size: 64, color: kGreenDark),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              s.t(step.titleKey),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: s.scaled(22),
                                fontWeight: FontWeight.bold,
                                color: kGreenDark,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              s.t(step.bodyKey),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: s.scaled(15),
                                color: const Color(0xFF3A3A3A),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_steps.length, (i) {
                    final active = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active
                            ? kGreenMid
                            : kGreenMid.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: SkeuButton(
                    label: _page == _steps.length - 1
                        ? s.t("got_it")
                        : s.t("next"),
                    fontSize: s.scaled(17),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    onPressed: () {
                      if (_page == _steps.length - 1) {
                        _finish();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}