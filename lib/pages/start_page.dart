import 'package:flutter/material.dart';
import 'skeu_theme.dart';
import 'reminder_page.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: kPaper),
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [kGreenLight, kGreenMid, kGreenDark],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(90),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 6),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    const Positioned(
                      top: 16,
                      left: 16,
                      child: SkeuCornerDots(),
                    ),
                    Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 24,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 200,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Center(
                child: SkeuButton(
                  label: "Start",
                  colorTop: kGreenLight,
                  colorBottom: kGreenDark,
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const ReminderPage()),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}