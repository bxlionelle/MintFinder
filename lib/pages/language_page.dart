// ═══════════════════════════════════════════════════════════════════
//  APP FLOW MAP
//
//   AppEntryPage
//         |
//         v
//   LanguagePage  <-- YOU ARE HERE  (first onboarding screen)
//         |
//         v
//   DisclaimerPage
//         |
//         v
//   ReminderPage
//         |
//         v
//   TutorialWalkthroughPage
//         |  (also calls AppSettings.markOnboardingComplete() here)
//         v
//   MenuPage
// ═══════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'skeu_theme.dart';
import 'disclaimer_page.dart';
import 'app_settings.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  Widget _choiceButton(String label, String langCode) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final isSelected = AppSettings.instance.language == langCode;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () => AppSettings.instance.setLanguage(langCode),
            borderRadius: BorderRadius.circular(26),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                color: isSelected ? kGreenMid : Colors.white,
                border: Border.all(
                  color: kGreenDark,
                  width: isSelected ? 0 : 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isSelected ? 0.3 : 0.12),
                    offset: const Offset(0, 3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : kGreenDark,
                ),
              ),
            ),
          ),
        );
      },
    );
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
            return SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: SkeuCornerDots(),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    s.t("language_title"),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: s.scaled(26),
                      fontWeight: FontWeight.bold,
                      color: kGreenDark,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _choiceButton("English", "en"),
                  _choiceButton("Tagalog", "tl"),
                  const SizedBox(height: 32),
                  Divider(color: kGreenDark.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text(
                    s.t("font_size_title"),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: s.scaled(20),
                      fontWeight: FontWeight.bold,
                      color: kGreenDark,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text("A",
                          style: TextStyle(fontSize: 14, color: kGreenDark)),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: kGreenMid,
                            inactiveTrackColor: kGreenMid.withOpacity(0.2),
                            thumbColor: kGreenDark,
                          ),
                          child: Slider(
                            value: s.fontScale,
                            min: 0.85,
                            max: 1.4,
                            divisions: 11,
                            onChanged: (v) => s.setFontScale(v),
                          ),
                        ),
                      ),
                      const Text("A",
                          style: TextStyle(fontSize: 26, color: kGreenDark)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Real-time preview - updates immediately as the
                  // language/font-size selections above change.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kGreenDark.withOpacity(0.2)),
                    ),
                    child: Text(
                      s.t("font_size_preview"),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: s.scaled(15),
                        color: const Color(0xFF3A3A3A),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  SkeuButton(
                    label: s.t("next"),
                    fontSize: s.scaled(18),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 60, vertical: 14),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const DisclaimerPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}