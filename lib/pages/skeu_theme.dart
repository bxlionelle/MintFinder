import 'package:flutter/material.dart';

// ── Shared skeuomorphic tokens, reused across the onboarding + menu flow ──
const kGreenDark = Color(0xFF2E4F10);
const kGreenMid = Color(0xFF456F1F);
const kGreenLight = Color(0xFF5C8A2A);
const kPaper = Color(0xFFF8F4E8);

/// A glossy, "physical" pill button - gradient fill, soft outer shadow,
/// thin darker bottom edge (pressed-in look), and a subtle top highlight
/// so it reads as a real, lit surface rather than a flat rectangle.
class SkeuButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color colorTop;
  final Color colorBottom;
  final double fontSize;
  final EdgeInsets padding;

  const SkeuButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.colorTop = kGreenLight,
    this.colorBottom = kGreenDark,
    this.fontSize = 22,
    this.padding = const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Opacity(
      opacity: disabled ? 0.45 : 1.0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colorTop, colorBottom],
          ),
          border: Border.all(color: colorBottom.withOpacity(0.6), width: 1),
          boxShadow: [
            BoxShadow(
              color: colorBottom.withOpacity(0.45),
              offset: const Offset(0, 5),
              blurRadius: 10,
            ),
            const BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: onPressed,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 3,
                  left: 12,
                  right: 12,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withOpacity(0.18),
                    ),
                  ),
                ),
                Padding(
                  padding: padding,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: const [
                        Shadow(color: Colors.black38, offset: Offset(0, 1), blurRadius: 2),
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

/// The two overlapping soft dots seen in the top-left of every onboarding
/// card in the mockup - a small recurring decorative motif.
class SkeuCornerDots extends StatelessWidget {
  const SkeuCornerDots({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 26,
      child: Stack(
        children: [
          Positioned(left: 0, child: _dot(kGreenLight.withOpacity(0.55))),
          Positioned(left: 16, child: _dot(kGreenLight.withOpacity(0.85))),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: const [
            BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 3),
          ],
        ),
      );
}