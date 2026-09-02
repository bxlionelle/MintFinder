import 'package:flutter/material.dart';
import 'skeu_theme.dart';
import 'capture_page.dart';
import 'almanac_page.dart';
import 'developers_page.dart';

/// A single skeuomorphic "photo tile" menu entry - gradient panel standing
/// in for a real photo (see note below), large watermark icon, diagonal
/// dark-to-transparent overlay, and a bold label set into the bottom-left
/// corner, matching the mockup's Camera/Almanac/Developers tiles.
///
/// NOTE: the mockup uses real photographs for these tiles (binoculars,
/// potted plants, hands on laptops). Those image assets aren't in the
/// project yet, so this uses a gradient + icon placeholder instead of
/// referencing files that don't exist. To use real photos, replace the
/// DecoratedBox's gradient with a DecorationImage(image: AssetImage(...))
/// once the images are added to assets/images/ and declared in pubspec.yaml.
class MenuTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const MenuTile({
    super.key,
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            height: 130,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  offset: Offset(0, 6),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 2,
                  left: 16,
                  right: 16,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withOpacity(0.14),
                    ),
                  ),
                ),
                Positioned(
                  right: -10,
                  bottom: -14,
                  child: Icon(icon, size: 110, color: Colors.white.withOpacity(0.16)),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                        colors: [Colors.black.withOpacity(0.35), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: 16,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 3)],
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 14,
                  child: Icon(icon, size: 22, color: Colors.white.withOpacity(0.85)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  APP FLOW MAP
//
//   TutorialWalkthroughPage  (or AppEntryPage directly, on repeat launches)
//         |
//         v
//   MenuPage  <-- YOU ARE HERE  (hub - buttons vertically centered)
//         |
//    ┌────┴────┐
//    v         v
//  CapturePage  AlmanacPage
// ═══════════════════════════════════════════════════════════════════

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPaper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "MintFinder",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: kGreenDark,
                ),
              ),
              const SizedBox(height: 28),
              MenuTile(
                label: "Camera",
                icon: Icons.camera_alt,
                gradient: const [Color(0xFF2F6B5A), Color(0xFF1A3D33)],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CapturePage()),
                ),
              ),
              MenuTile(
                label: "Almanac",
                icon: Icons.local_florist,
                gradient: const [kGreenLight, kGreenDark],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlmanacPage()),
                ),
              ),
              // Kept hidden to match current app behavior - flip
              // `visible` to true to show the Developers tile again.
              Visibility(
                visible: false,
                child: MenuTile(
                  label: "Developers",
                  icon: Icons.code,
                  gradient: const [Color(0xFF5B4B8A), Color(0xFF352A54)],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DevelopersPage()),
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