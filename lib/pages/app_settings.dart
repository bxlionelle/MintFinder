import 'package:flutter/material.dart';

/// Two things any page can react to: the chosen UI language ("en" or
/// "tl") and a font-size SCALE (a multiplier, not a fixed size) applied
/// to every text style, so the whole app's text grows/shrinks together
/// from one setting.
///
/// This is a plain singleton ChangeNotifier rather than an
/// InheritedWidget wired at the app root (main.dart wasn't available
/// to safely edit) - any page that needs to react to changes wraps the
/// relevant part of its UI in
/// `ListenableBuilder(listenable: AppSettings.instance, builder: ...)`.
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  String _language = "en"; // "en" | "tl"
  double _fontScale = 1.0; // multiplies every TextStyle's fontSize

  String get language => _language;
  double get fontScale => _fontScale;
  bool get isTagalog => _language == "tl";

  void setLanguage(String lang) {
    if (_language == lang) return;
    _language = lang;
    notifyListeners();
  }

  void setFontScale(double scale) {
    if (_fontScale == scale) return;
    _fontScale = scale;
    notifyListeners();
  }

  /// Scales a base font size by the current preference. Use this
  /// instead of a raw fontSize number anywhere text should respect
  /// the user's chosen text size.
  double scaled(double baseSize) => baseSize * _fontScale;

  /// Looks up a translated string for [key], falling back to the
  /// English value (or the key itself) if no Tagalog translation
  /// exists yet.
  String t(String key) {
    final entry = _strings[key];
    if (entry == null) return key;
    return entry[_language] ?? entry["en"] ?? key;
  }
}

/// Translated strings for the language/font-size picker and the
/// tutorial screens. This does NOT include the per-plant Almanac
/// content (name/description/uses/safety) - that lives in
/// plant_info.dart, which needs its own "tl" entries added alongside
/// the existing English content to fully localize the Almanac.
const Map<String, Map<String, String>> _strings = {
  "language_title": {
    "en": "What language\ndo you prefer?",
    "tl": "Anong wika ang\nnais mong gamitin?",
  },
  "font_size_title": {
    "en": "Choose your text size",
    "tl": "Piliin ang laki ng titik",
  },
  "font_size_preview": {
    "en": "This is how text will look throughout the app.",
    "tl": "Ganito ang hitsura ng teksto sa buong app.",
  },
  "next": {"en": "Next", "tl": "Susunod"},
  "tutorial_prompt_title": {
    "en": "Quick Tutorial?",
    "tl": "Gusto mo bang magpatutorial?",
  },
  "tutorial_prompt_body": {
    "en": "Would you like a short walkthrough on how to take a good "
        "photo for identification?",
    "tl": "Gusto mo bang malaman kung paano kumuha ng magandang "
        "larawan para sa pagkilala ng halaman?",
  },
  "yes": {"en": "Yes, show me", "tl": "Oo, ituro mo"},
  "cancel": {"en": "Cancel", "tl": "Kanselahin"},
  "tutorial_step1_title": {
    "en": "Position the leaf",
    "tl": "Ilagay ang dahon sa gabay",
  },
  "tutorial_step1_body": {
    "en": "Center a single leaf inside the leaf-shaped frame. Good "
        "lighting and a plain background work best.",
    "tl": "Ilagay ang iisang dahon sa gitna ng balangkas na "
        "hugis-dahon. Mas mainam kung maliwanag at malinis ang likod.",
  },
  "tutorial_step2_title": {
    "en": "Tap to focus",
    "tl": "Pindutin para mag-focus",
  },
  "tutorial_step2_body": {
    "en": "Tap anywhere on the preview to sharpen the focus and "
        "adjust brightness at that spot. Pinch to zoom in or out.",
    "tl": "Pindutin ang anumang bahagi ng preview para mag-focus at "
        "ayusin ang liwanag doon. Pisilin (pinch) para mag-zoom.",
  },
  "tutorial_step3_title": {
    "en": "Capture the photo",
    "tl": "Kumuha ng larawan",
  },
  "tutorial_step3_body": {
    "en": "Tap the round shutter button in the middle to take the "
        "photo once the leaf is well framed.",
    "tl": "Pindutin ang bilog na shutter button sa gitna kapag maayos "
        "na ang pagkakalagay ng dahon.",
  },
  "tutorial_step4_title": {
    "en": "Or choose from Gallery",
    "tl": "O pumili mula sa Gallery",
  },
  "tutorial_step4_body": {
    "en": "Already have a photo saved? Tap the gallery icon on the "
        "left to upload it instead.",
    "tl": "May naka-save ka nang larawan? Pindutin ang gallery icon "
        "sa kaliwa para i-upload ito.",
  },
  "got_it": {
    "en": "Got it, Start Identifying",
    "tl": "Nakuha ko, Simulan Na",
  },
  "skip": {"en": "Skip", "tl": "Laktawan"},
  "almanac_title": {"en": "Almanac", "tl": "Almanake"},
  "almanac_subtitle": {
    "en": "Learn about each plant",
    "tl": "Alamin ang bawat halaman",
  },
  "about": {"en": "About", "tl": "Tungkol Dito"},
  "uses_remedies": {"en": "Uses / Remedies", "tl": "Gamit / Lunas"},
  "safety_measures": {
    "en": "Safety Measures",
    "tl": "Mga Babala sa Kaligtasan",
  },
  "common_names": {"en": "Common Names", "tl": "Ibang Pangalan"},
};