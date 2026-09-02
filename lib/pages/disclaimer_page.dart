// ═══════════════════════════════════════════════════════════════════
//  APP FLOW MAP
//
//   LanguagePage
//         |
//         v
//   DisclaimerPage  <-- YOU ARE HERE  (content vertically centered)
//         |
//         v
//   ReminderPage
// ═══════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'app_settings.dart';
import 'reminder_page.dart';

class DisclaimerPage extends StatelessWidget {
  const DisclaimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final s = AppSettings.instance;
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            // Centered vertically, per request ("put it in the middle").
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'MintFinder',
                      style: TextStyle(
                        fontSize: s.scaled(28),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Herbal Plant Identifier',
                      style: TextStyle(
                        fontSize: s.scaled(14),
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        border: Border.all(
                          color: const Color(0xFFFFCA28),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('⚠️', style: TextStyle(fontSize: 22)),
                              const SizedBox(width: 8),
                              Text(
                                s.t("disclaimer_heading"),
                                style: TextStyle(
                                  fontSize: s.scaled(18),
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF5D4037),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            s.t("disclaimer_body"),
                            style: TextStyle(
                              fontSize: s.scaled(14),
                              height: 1.6,
                              color: const Color(0xFF4E342E),
                            ),
                            textAlign: TextAlign.justify,
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFFFCA28)),
                          const SizedBox(height: 8),
                          Text(
                            s.t("disclaimer_footer"),
                            style: TextStyle(
                              fontSize: s.scaled(12),
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (_) => const ReminderPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          s.t("disclaimer_continue"),
                          style: TextStyle(
                              fontSize: s.scaled(16),
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}