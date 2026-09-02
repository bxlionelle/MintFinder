import 'package:flutter/material.dart';
import 'skeu_theme.dart';
import 'language_page.dart';

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  bool _understood = false;

  static const _reminders = [
    "MintFinder works fully offline - no internet connection needed to identify a plant.",
    "For best results, photograph a single, clearly-lit leaf against a plain background.",
    "Results are for educational reference only, not a substitute for professional medical advice.",
    "Some leaf conditions (glare, clustered leaves, unusual angles) may affect accuracy.",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGreenMid,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: SkeuCornerDots(),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: BoxDecoration(
                    color: kPaper,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black38,
                        offset: Offset(0, 8),
                        blurRadius: 18,
                      ),
                    ],
                    border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "REMINDER",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: kGreenDark,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _reminders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (_, i) => Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: kGreenMid,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _reminders[i],
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    height: 1.45,
                                    color: Color(0xFF3A3A3A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => setState(() => _understood = !_understood),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              _SkeuCheckbox(checked: _understood),
                              const SizedBox(width: 10),
                              const Text(
                                "I understand",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: kGreenDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SkeuButton(
                label: "Next",
                fontSize: 18,
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
                onPressed: _understood
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LanguagePage()),
                        );
                      }
                    : null,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small embossed checkbox - filled + inset shadow when checked, so it
/// reads as a pressed physical switch rather than a flat Material checkbox.
class _SkeuCheckbox extends StatelessWidget {
  final bool checked;
  const _SkeuCheckbox({required this.checked});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: checked ? kGreenMid : Colors.white,
        border: Border.all(color: kGreenDark, width: 1.5),
        boxShadow: checked
            ? const [BoxShadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 2)]
            : null,
      ),
      child: checked
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }
}