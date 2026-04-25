// lib/pages/almanac_page.dart
import 'package:flutter/material.dart';
import '../data/plant_info.dart' show plantInfo;

// Image paths are stored inside plant_info.dart under the "image" key.
// No separate map needed here.

// ─── Color palette (matches existing app) ────────────────────────────────────
const _bgDark    = Color(0xFF2D4A10);
const _bgMid     = Color(0xFF3A5C18);
const _cardBg    = Color(0xFFF4F0E8);   // warm off-white card
const _accent    = Color(0xFF5A8A1F);
const _textDark  = Color(0xFF1E3205);
const _textMuted = Color(0xFF607040);

// ─── AlmanacPage ─────────────────────────────────────────────────────────────
class AlmanacPage extends StatelessWidget {
  const AlmanacPage({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = plantInfo.entries.toList();

    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Almanac',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Organic blob shape at the bottom (matches app style)
          Positioned(
            bottom: -60,
            left: -40,
            child: _GreenBlob(size: 220),
          ),
          Positioned(
            bottom: -30,
            right: -50,
            child: _GreenBlob(size: 160),
          ),

          GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.78,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final key  = entries[index].key;
              final data = entries[index].value;
              return _PlantCard(
                plantKey: key,
                data: data,
                onTap: () => _openDetail(context, key, data),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, String key, Map<String, dynamic> data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _AlmanacDetailPage(plantKey: key, data: data),
      ),
    );
  }
}

// ─── Plant Card ───────────────────────────────────────────────────────────────
class _PlantCard extends StatelessWidget {
  final String plantKey;
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _PlantCard({
    required this.plantKey,
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = data['image'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFDDE8C4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image area
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Container(
                  color: const Color(0xFFC8D9A0),
                  child: imagePath != null
                      ? Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const _PlantPlaceholder(),
                        )
                      : const _PlantPlaceholder(),
                ),
              ),
            ),

            // Name row
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'],
                          style: const TextStyle(
                            color: _textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data['scientific'],
                          style: const TextStyle(
                            color: _textMuted,
                            fontStyle: FontStyle.italic,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Share / open icon
                  Icon(Icons.open_in_new, color: _textMuted, size: 16),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Almanac Detail Page ──────────────────────────────────────────────────────
class _AlmanacDetailPage extends StatefulWidget {
  final String plantKey;
  final Map<String, dynamic> data;

  const _AlmanacDetailPage({required this.plantKey, required this.data});

  @override
  State<_AlmanacDetailPage> createState() => _AlmanacDetailPageState();
}

class _AlmanacDetailPageState extends State<_AlmanacDetailPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // In a real app you'd have multiple images; we demo with one.
  List<String> get _images {
    final path = widget.data['image'] as String?;
    return path != null ? [path] : [];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final List uses           = data['uses']          as List? ?? [];
    final List safetyMeasures = data['safetyMeasures'] as List? ?? [];
    final List otherNames     = data['otherNames']    as List? ?? [];

    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          data['name'],
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          // Background blobs
          Positioned(bottom: -40, left: -30, child: _GreenBlob(size: 180)),
          Positioned(top: 200,   right: -50, child: _GreenBlob(size: 140)),

          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Image carousel ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC8D9A0),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _accent, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            onPageChanged: (i) => setState(() => _currentPage = i),
                            itemCount: _images.isEmpty ? 1 : _images.length,
                            itemBuilder: (_, i) {
                              if (_images.isEmpty) return const _PlantPlaceholder();
                              return Image.asset(
                                _images[i],
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const _PlantPlaceholder(),
                              );
                            },
                          ),
                          // Left arrow
                          if (_images.length > 1) ...[
                            Positioned(
                              left: 6,
                              top: 0, bottom: 0,
                              child: Center(
                                child: _CarouselArrow(
                                  icon: Icons.arrow_left,
                                  onTap: () {
                                    if (_currentPage > 0) {
                                      _pageController.previousPage(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              right: 6,
                              top: 0, bottom: 0,
                              child: Center(
                                child: _CarouselArrow(
                                  icon: Icons.arrow_right,
                                  onTap: () {
                                    if (_currentPage < _images.length - 1) {
                                      _pageController.nextPage(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Page dots
                if (_images.length > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_images.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _currentPage ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _currentPage ? Colors.greenAccent : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  )
                else
                  // Two static dots as in mockup design (decorative)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Dot(active: true),
                        const SizedBox(width: 6),
                        _Dot(active: false),
                      ],
                    ),
                  ),

                // ── Name & scientific ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    '${data['name']} (${data['scientific']})',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // ── Two-column: Definition + Other Names ────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Definition
                        Expanded(
                          child: _DetailCard(
                            title: 'Definition',
                            titleColor: _accent,
                            child: Text(
                              data['definition'] ?? data['description'] ?? '',
                              style: const TextStyle(
                                color: _textDark,
                                fontSize: 13,
                                height: 1.55,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Other Names + Uses
                        Expanded(
                          child: Column(
                            children: [
                              _DetailCard(
                                title: 'Also Known As',
                                titleColor: _textDark,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: otherNames.map((n) => _BulletItem(text: n)).toList(),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _DetailCard(
                                title: 'Uses / Remedies',
                                titleColor: _textDark,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: uses.map((u) => _BulletItem(text: u)).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── Safety Measures (full width) ────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _DetailCard(
                    title: '⚠ Safety Measures',
                    titleColor: const Color(0xFFD4762A),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: safetyMeasures
                          .map((s) => _BulletItem(text: s, bulletColor: const Color(0xFFD4762A)))
                          .toList(),
                    ),
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

// ─── Small reusable widgets ───────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final String title;
  final Color titleColor;
  final Widget child;

  const _DetailCard({
    required this.title,
    required this.titleColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  final Color bulletColor;

  const _BulletItem({required this.text, this.bulletColor = _textMuted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 6),
            child: CircleAvatar(radius: 3, backgroundColor: bulletColor),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: _textDark, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CarouselArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.25),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 20 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: active ? Colors.greenAccent : const Color(0xFF8BAF50),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

class _PlantPlaceholder extends StatelessWidget {
  const _PlantPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.eco, color: Color(0xFF6A9B35), size: 64),
    );
  }
}

class _GreenBlob extends StatelessWidget {
  final double size;
  const _GreenBlob({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _bgMid.withOpacity(0.6),
      ),
    );
  }
}