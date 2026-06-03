import 'package:flutter/material.dart';
import 'package:mintfinder_1/pages/landing_page.dart';

class DisclaimerPage extends StatelessWidget {
  const DisclaimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Capture guide image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/capture_guide.jpg',
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'MintFinder',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Herbal Plant Identifier',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 24),

              // Disclaimer card
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
                      children: const [
                        Text('⚠️', style: TextStyle(fontSize: 22)),
                        SizedBox(width: 8),
                        Text(
                          'Disclaimer',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This application is not a medical device. '
                      'It identifies herbal plants for educational and reference purposes only. '
                      'Users should remain vigilant and consult health professionals '
                      'before using any plant medicinally.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Color(0xFF4E342E),
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFFFCA28)),
                    const SizedBox(height: 8),
                    const Text(
                      'By continuing, you acknowledge that you have read '
                      'and understood this disclaimer.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Accept button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LandingPage()),
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
                  child: const Text(
                    'I Understand, Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
