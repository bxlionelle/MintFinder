// lib/data/instruction_info.dart

class ScanTip {
  final String icon;       // asset path or icon identifier
  final String category;   // "do" | "avoid"
  final String title;
  final String body;

  const ScanTip({
    required this.icon,
    required this.category,
    required this.title,
    required this.body,
  });
}

class InstructionSection {
  final String sectionTitle;
  final List<ScanTip> tips;

  const InstructionSection({
    required this.sectionTitle,
    required this.tips,
  });
}

// ─── Step-by-step guide ───────────────────────────────────────────────────────
const List<Map<String, String>> scanSteps = [
  {
    "step": "1",
    "title": "Open the camera",
    "body": "Tap the camera icon on the Home screen to launch the Identify Plant page.",
  },
  {
    "step": "2",
    "title": "Choose a leaf",
    "body": "Pick a healthy, fully grown leaf. Avoid newly sprouted or damaged ones — the model performs best on mature foliage.",
  },
  {
    "step": "3",
    "title": "Frame the shot",
    "body": "Hold the phone 15–25 cm from the leaf so it fills most of the viewfinder. Keep the device steady.",
  },
  {
    "step": "4",
    "title": "Ensure good lighting",
    "body": "Use natural daylight or bright indoor light. The leaf surface should be evenly lit with no harsh shadows.",
  },
  {
    "step": "5",
    "title": "Tap the shutter",
    "body": "Press the capture button and hold still for a moment. The AI will analyze the image and return a result.",
  },
  {
    "step": "6",
    "title": "Review the result",
    "body": "Check the confidence score. A score above 85% is reliable. Below 65% — try again with a clearer shot.",
  },
];

// ─── Do's and Don'ts ──────────────────────────────────────────────────────────
const List<InstructionSection> instructionSections = [
  InstructionSection(
    sectionTitle: "Best practices",
    tips: [
      ScanTip(
        icon: "eco",
        category: "do",
        title: "Focus on a single leaf",
        body: "Position one leaf at the center of the frame. Isolated leaves give the model a clear, unambiguous subject.",
      ),
      ScanTip(
        icon: "wb_sunny",
        category: "do",
        title: "Use natural light",
        body: "Scan outdoors or near a window in daylight. Even, diffused light brings out the leaf's true color and vein detail.",
      ),
      ScanTip(
        icon: "straighten",
        category: "do",
        title: "Fill the frame",
        body: "Keep the leaf at 15–25 cm from the lens so it occupies at least 60% of the frame — close enough to show texture without blurring.",
      ),
      ScanTip(
        icon: "filter_center_focus",
        category: "do",
        title: "Hold steady",
        body: "Tap to focus on the leaf and wait for the autofocus to lock before pressing the shutter. Blur is the most common cause of low confidence.",
      ),
      ScanTip(
        icon: "flip",
        category: "do",
        title: "Try both sides",
        body: "If the result confidence is low, flip the leaf and scan its underside — some species show more distinctive features there.",
      ),
    ],
  ),
  InstructionSection(
    sectionTitle: "Things to avoid",
    tips: [
      ScanTip(
        icon: "water_drop",
        category: "avoid",
        title: "Wet or glossy leaves",
        body: "Water droplets and strong reflections overexpose parts of the leaf and obscure the surface pattern the model relies on.",
      ),
      ScanTip(
        icon: "broken_image",
        category: "avoid",
        title: "Damaged or wilted leaves",
        body: "Torn edges, insect damage, browning, or wilting changes a leaf's shape and color significantly, reducing classification accuracy.",
      ),
      ScanTip(
        icon: "blur_on",
        category: "avoid",
        title: "Out-of-focus shots",
        body: "A blurry image gives the model ambiguous edges and texture. Always confirm the leaf is sharp before capturing.",
      ),
      ScanTip(
        icon: "layers",
        category: "avoid",
        title: "Overlapping leaves",
        body: "Multiple overlapping leaves confuse the model. Try to isolate a single leaf against a plain or contrasting background.",
      ),
      ScanTip(
        icon: "nights_stay",
        category: "avoid",
        title: "Low-light or dark scenes",
        body: "Poor lighting introduces noise and washes out the leaf's green tones. Avoid scanning at night or in dimly lit rooms.",
      ),
    ],
  ),
];

// ─── Confidence guide ─────────────────────────────────────────────────────────
const List<Map<String, String>> confidenceGuide = [
  {
    "range": "85% – 100%",
    "label": "High confidence",
    "color": "green",
    "body": "The model is very certain. The result is reliable and will display full plant information.",
  },
  {
    "range": "65% – 84%",
    "label": "Moderate confidence",
    "color": "yellow",
    "body": "The model identified a likely match but is not fully certain. Consider retaking the photo in better conditions.",
  },
  {
    "range": "Below 65%",
    "label": "Low confidence",
    "color": "orange",
    "body": "The image was not recognized clearly. The scan will be rejected — try again with a clearer, well-lit leaf.",
  },
];

// ─── Supported plants reminder ────────────────────────────────────────────────
const String supportedPlantsNote =
    "This app currently identifies five medicinal plants: "
    "Cat's Whiskers, White Teak, Lemon Basil, Mayana, and Spearmint. "
    "Check the Almanac for details on each plant.";