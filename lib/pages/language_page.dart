import 'package:flutter/material.dart';
import 'skeu_theme.dart';
import 'menu_page.dart';

/// NOTE: this screen captures the user's language *preference* visually,
/// matching the mockup. It does not yet wire up actual app-wide
/// localization (i18n) - that's a separate, larger piece of work
/// (translated strings throughout every page). Treat the selection here
/// as a UI placeholder until real localization is implemented.
class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  String _selected = "English";

  Widget _choiceButton(String label) {
    final isSelected = _selected == label;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => setState(() => _selected = label),
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
              if (isSelected)
                const BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 1),
                  blurRadius: 1,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPaper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: SkeuCornerDots(),
              ),
              const Spacer(flex: 2),
              const Text(
                "What language\ndo you prefer?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: kGreenDark,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 40),
              _choiceButton("English"),
              _choiceButton("Tagalog"),
              const Spacer(flex: 1),
              SkeuButton(
                label: "Next",
                fontSize: 18,
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MenuPage()),
                  );
                },
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}