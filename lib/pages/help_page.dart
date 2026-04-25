// lib/pages/help_page.dart
import 'package:flutter/material.dart';
import '../data/instruction_info.dart';

// ─── Color palette (matches app) ─────────────────────────────────────────────
const _bgDark   = Color(0xFF2E4F10);
const _bgMid    = Color(0xFF3A5C18);
const _cardBg   = Color(0xFF243D0C);
const _green    = Colors.greenAccent;

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Scanning Guide",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.greenAccent,
          indicatorWeight: 3,
          labelColor: Colors.greenAccent,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "How To Scan"),
            Tab(text: "Do's & Don'ts"),
            Tab(text: "Confidence"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _StepsTab(),
          _TipsTab(),
          _ConfidenceTab(),
        ],
      ),
    );
  }
}

// ─── Tab 1: Step-by-step guide ────────────────────────────────────────────────
class _StepsTab extends StatelessWidget {
  const _StepsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        // Header illustration area
        _SectionHeader(
          icon: Icons.camera_alt_outlined,
          title: "How to scan a plant",
          subtitle: "Follow these 6 steps for the most accurate result",
        ),
        const SizedBox(height: 24),

        // Steps
        ...scanSteps.map((step) => _StepCard(
          stepNumber: step["step"]!,
          title: step["title"]!,
          body: step["body"]!,
          isLast: step["step"] == "${scanSteps.length}",
        )),

        const SizedBox(height: 24),

        // Supported plants note
        _InfoBanner(
          icon: Icons.eco,
          color: Colors.greenAccent,
          text: supportedPlantsNote,
        ),
      ],
    );
  }
}

// ─── Tab 2: Do's and Don'ts ───────────────────────────────────────────────────
class _TipsTab extends StatelessWidget {
  const _TipsTab();

  static const Map<String, IconData> _iconMap = {
    "eco":                Icons.eco_outlined,
    "wb_sunny":           Icons.wb_sunny_outlined,
    "straighten":         Icons.straighten_outlined,
    "filter_center_focus": Icons.filter_center_focus,
    "flip":               Icons.flip_outlined,
    "water_drop":         Icons.water_drop_outlined,
    "broken_image":       Icons.broken_image_outlined,
    "blur_on":            Icons.blur_on,
    "layers":             Icons.layers_outlined,
    "nights_stay":        Icons.nights_stay_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: instructionSections.map((section) {
        final isDo = section.tips.first.category == "do";
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section label
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDo
                        ? Colors.greenAccent.withOpacity(0.15)
                        : Colors.orangeAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDo
                          ? Colors.greenAccent.withOpacity(0.4)
                          : Colors.orangeAccent.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDo ? Icons.check_circle_outline : Icons.cancel_outlined,
                        color: isDo ? Colors.greenAccent : Colors.orangeAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        section.sectionTitle,
                        style: TextStyle(
                          color: isDo ? Colors.greenAccent : Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            ...section.tips.map((tip) => _TipCard(
              icon: _iconMap[tip.icon] ??
                  (isDo ? Icons.check : Icons.close),
              category: tip.category,
              title: tip.title,
              body: tip.body,
            )),

            const SizedBox(height: 28),
          ],
        );
      }).toList(),
    );
  }
}

// ─── Tab 3: Confidence guide ──────────────────────────────────────────────────
class _ConfidenceTab extends StatelessWidget {
  const _ConfidenceTab();

  Color _colorFor(String colorKey) {
    switch (colorKey) {
      case "green":  return Colors.greenAccent;
      case "yellow": return Colors.yellowAccent;
      case "orange": return Colors.orangeAccent;
      default:       return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        _SectionHeader(
          icon: Icons.analytics_outlined,
          title: "Understanding confidence",
          subtitle:
              "The confidence score shows how certain the AI is about its identification",
        ),
        const SizedBox(height: 24),

        // Visual confidence bar
        _ConfidenceBarVisual(),

        const SizedBox(height: 28),

        // Cards for each range
        ...confidenceGuide.map((entry) {
          final color = _colorFor(entry["color"]!);
          return _ConfidenceCard(
            range: entry["range"]!,
            label: entry["label"]!,
            body: entry["body"]!,
            accentColor: color,
          );
        }),

        const SizedBox(height: 24),

        _InfoBanner(
          icon: Icons.tips_and_updates_outlined,
          color: Colors.yellowAccent,
          text:
              "Tip: If confidence is below 85%, try stepping closer, improving lighting, or choosing a different leaf.",
        ),
      ],
    );
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.greenAccent, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final String stepNumber;
  final String title;
  final String body;
  final bool isLast;

  const _StepCard({
    required this.stepNumber,
    required this.title,
    required this.body,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number + connector line
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.greenAccent.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    stepNumber,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.greenAccent.withOpacity(0.2),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String category;
  final String title;
  final String body;

  const _TipCard({
    required this.icon,
    required this.category,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final isDo = category == "do";
    final accent = isDo ? Colors.greenAccent : Colors.orangeAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceBarVisual extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Confidence scale",
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Expanded(
                  flex: 35,
                  child: Container(height: 16, color: Colors.orangeAccent.withOpacity(0.85)),
                ),
                Expanded(
                  flex: 20,
                  child: Container(height: 16, color: Colors.yellowAccent.withOpacity(0.85)),
                ),
                Expanded(
                  flex: 45,
                  child: Container(height: 16, color: Colors.greenAccent.withOpacity(0.85)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("0%", style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11)),
              Text("65%", style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11)),
              Text("85%", style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11)),
              Text("100%", style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfidenceCard extends StatelessWidget {
  final String range;
  final String label;
  final String body;
  final Color accentColor;

  const _ConfidenceCard({
    required this.range,
    required this.label,
    required this.body,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.25),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color dot
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        range,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 13,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}