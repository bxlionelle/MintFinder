// ═══════════════════════════════════════════════════════════════════
//  APP FLOW MAP (this file is the TRUE root - set as MaterialApp's
//  `home:` in main.dart)
//
//   [App launches]
//         |
//         v
//   AppEntryPage  <-- YOU ARE HERE
//         |
//    loads saved language/fontScale/onboardingDone from disk
//         |
//    onboardingDone == false?  ──yes──> LanguagePage
//         |no                              |
//         v                                v
//     MenuPage                    (full onboarding chain -
//                                   see language_page.dart's header)
// ═══════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'app_settings.dart';
import 'language_page.dart';
import 'menu_page.dart';

class AppEntryPage extends StatefulWidget {
  const AppEntryPage({super.key});

  @override
  State<AppEntryPage> createState() => _AppEntryPageState();
}

class _AppEntryPageState extends State<AppEntryPage> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    await AppSettings.instance.loadFromDisk();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AppSettings.instance.onboardingDone
            ? const MenuPage()
            : const LanguagePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF456F1F),
      body: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}