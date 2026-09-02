import 'package:flutter/material.dart';
import 'app_settings.dart';
import '../data/plant_info.dart';

class AlmanacDetailPage extends StatelessWidget {
  final String plantKey;
  const AlmanacDetailPage({super.key, required this.plantKey});

  String _loc(Map<String, dynamic> data, String baseKey, AppSettings s) {
    if (s.isTagalog) {
      final tlKey = '${baseKey}_tl';
      if (data.containsKey(tlKey)) return data[tlKey] as String;
    }
    return data[baseKey] as String;
  }

  List<String> _locList(Map<String, dynamic> data, String baseKey, AppSettings s) {
    if (s.isTagalog) {
      final tlKey = '${baseKey}_tl';
      if (data.containsKey(tlKey)) {
        return List<String>.from(data[tlKey] as List);
      }
    }
    return List<String>.from(data[baseKey] as List);
  }

  @override
  Widget build(BuildContext context) {
    final data = plantInfo[plantKey];

    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final s = AppSettings.instance;

        if (data == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF2E4F10),
            appBar: AppBar(
              backgroundColor: const Color(0xFF2E4F10),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: Center(
              child: Text(
                "Plant data not found for '$plantKey'",
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        final name = (s.isTagalog && data.containsKey('name_tl'))
            ? data['name_tl'] as String
            : data['name'] as String;
        final description = _loc(data, 'description', s);
        final uses = _locList(data, 'uses', s);
        final safety = _locList(data, 'safetyMeasures', s);
        final otherNames = List<String>.from(data['otherNames'] as List);

        return Scaffold(
          backgroundColor: const Color(0xFF2E4F10),
          appBar: AppBar(
            backgroundColor: const Color(0xFF2E4F10),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  child: Image.asset(
                    data['image'] as String,
                    width: double.infinity,
                    height: 260,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: s.scaled(26),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data['scientific'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.greenAccent.withOpacity(0.85),
                            fontSize: s.scaled(15),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: s.t("about"),
                  titleFontSize: s.scaled(16),
                  icon: Icons.info_outline,
                  content: Text(
                    description,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: s.scaled(15),
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: s.t("uses_remedies"),
                  titleFontSize: s.scaled(16),
                  icon: Icons.healing_outlined,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: uses
                        .map((u) => _bullet(u, s, Colors.white70))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: s.t("safety_measures"),
                  titleFontSize: s.scaled(16),
                  icon: Icons.warning_amber_rounded,
                  iconColor: Colors.orangeAccent,
                  titleColor: Colors.orangeAccent,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: safety
                        .map((sf) => _bullet(sf, s, Colors.white70,
                            bulletColor: Colors.orangeAccent))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: s.t("common_names"),
                  titleFontSize: s.scaled(16),
                  icon: Icons.label_outline,
                  content: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: otherNames
                        .map((n) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Text(
                                n,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: s.scaled(13)),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _bullet(String text, AppSettings s, Color color,
      {Color bulletColor = Colors.white70}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: CircleAvatar(radius: 3, backgroundColor: bulletColor),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: s.scaled(14), height: 1.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required double titleFontSize,
    required IconData icon,
    required Widget content,
    Color iconColor = Colors.white70,
    Color titleColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }
}