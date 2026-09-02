import 'package:flutter/material.dart';
import 'skeu_theme.dart';
import 'app_settings.dart';
import 'menu_page.dart';
import 'tutorial_walkthrough_page.dart';

class TutorialPromptPage extends StatelessWidget {
  const TutorialPromptPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGreenMid,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: AppSettings.instance,
          builder: (context, _) {
            final s = AppSettings.instance;
            return Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: kGreenLight,
                    ),
                    child: const Icon(Icons.help_outline,
                        color: Colors.white, size: 42),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    s.t("tutorial_prompt_title"),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: s.scaled(24),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    s.t("tutorial_prompt_body"),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: s.scaled(15),
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SkeuButton(
                    label: s.t("yes"),
                    fontSize: s.scaled(18),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 14),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TutorialWalkthroughPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const MenuPage()),
                      );
                    },
                    child: Text(
                      s.t("cancel"),
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: s.scaled(15),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}