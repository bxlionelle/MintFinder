import 'package:flutter/material.dart';
import 'skeu_theme.dart';
import 'app_settings.dart';
import '../data/plant_info.dart';
import 'almanac_detail_page.dart';

/// Same visual language as MenuPage's MenuTile, but using a REAL photo
/// (DecorationImage) instead of a gradient+icon placeholder, since real
/// plant photos already exist in assets/plants/ for the Almanac.
class AlmanacTile extends StatelessWidget {
  final String label;
  final String imagePath;
  final double fontScale;
  final VoidCallback onTap;

  const AlmanacTile({
    super.key,
    required this.label,
    required this.imagePath,
    required this.fontScale,
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
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Colors.black38, offset: Offset(0, 6), blurRadius: 12),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                        colors: [
                          Colors.black.withOpacity(0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: 16,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 22 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: const [
                        Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AlmanacPage extends StatelessWidget {
  const AlmanacPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final s = AppSettings.instance;
        return Scaffold(
          backgroundColor: kPaper,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: kGreenDark,
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.t("almanac_title"),
                    style: TextStyle(
                      fontSize: s.scaled(26),
                      fontWeight: FontWeight.bold,
                      color: kGreenDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.t("almanac_subtitle"),
                    style: TextStyle(fontSize: s.scaled(14), color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      children: plantInfo.entries.map((entry) {
                        final key = entry.key;
                        final data = entry.value;
                        final label = (s.isTagalog && data.containsKey('name_tl'))
                            ? data['name_tl'] as String
                            : data['name'] as String;
                        return AlmanacTile(
                          label: label,
                          imagePath: data['image'] as String,
                          fontScale: s.fontScale,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AlmanacDetailPage(plantKey: key),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}