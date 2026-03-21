import 'package:flutter/material.dart';
import 'capture_page.dart';
import 'almanac_page.dart';
import 'developers_page.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  Widget menuButton(
    BuildContext context,
    String title,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF456F1F),
          minimumSize: const Size(260, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: onTap,
        child: Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF456F1F),
      body: SafeArea(
        child: Center(                              // 👈 added
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // 👈 added
            children: [
              menuButton(
                context,
                "Capture",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CapturePage()),
                ),
              ),
              menuButton(
                context,
                "Almanac",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlmanacPage()),
                ),
              ),
              menuButton(
                context,
                "Developers",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DevelopersPage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}