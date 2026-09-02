import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Two things any page can react to: the chosen UI language ("en" or
/// "tl") and a font-size SCALE (a multiplier, not a fixed size) applied
/// to every text style, so the whole app's text grows/shrinks together
/// from one setting.
///
/// ALSO tracks whether the one-time onboarding flow (Language ->
/// Disclaimer -> Reminder -> Tutorial) has already been completed on
/// THIS device, persisted via shared_preferences so it survives app
/// restarts and only resets if the app's storage is cleared or it's
/// reinstalled.
///
/// This is a plain singleton ChangeNotifier rather than an
/// InheritedWidget wired at the app root (main.dart wasn't available
/// to safely edit) - any page that needs to react to changes wraps the
/// relevant part of its UI in
/// `ListenableBuilder(listenable: AppSettings.instance, builder: ...)`.
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  static const _kLanguageKey = "mintfinder_language";
  static const _kFontScaleKey = "mintfinder_font_scale";
  static const _kOnboardingDoneKey = "mintfinder_onboarding_done";

  String _language = "en"; // "en" | "tl"
  double _fontScale = 1.0; // multiplies every TextStyle's fontSize
  bool _onboardingDone = false;
  bool _loaded = false;

  String get language => _language;
  double get fontScale => _fontScale;
  bool get isTagalog => _language == "tl";
  bool get onboardingDone => _onboardingDone;

  /// Loads persisted language/fontScale/onboarding state from device
  /// storage. Call this ONCE, before the app decides which screen to
  /// show first (see AppEntryPage). Safe to call multiple times - a
  /// no-op after the first successful load.
  Future<void> loadFromDisk() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString(_kLanguageKey) ?? "en";
    _fontScale = prefs.getDouble(_kFontScaleKey) ?? 1.0;
    _onboardingDone = prefs.getBool(_kOnboardingDoneKey) ?? false;
    _loaded = true;
    notifyListeners();
  }

  /// Marks onboarding as complete on THIS device - called once at the
  /// end of the tutorial (or when it's skipped). Subsequent app
  /// launches will go straight to the Menu instead of repeating
  /// Language -> Disclaimer -> Reminder -> Tutorial.
  Future<void> markOnboardingComplete() async {
    _onboardingDone = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingDoneKey, true);
    notifyListeners();
  }

  void setLanguage(String lang) {
    if (_language == lang) return;
    _language = lang;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((p) => p.setString(_kLanguageKey, lang));
  }

  void setFontScale(double scale) {
    if (_fontScale == scale) return;
    _fontScale = scale;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((p) => p.setDouble(_kFontScaleKey, scale));
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
  "reminder_title": {"en": "REMINDER", "tl": "PAALALA"},
  "reminder_item_1": {
    "en": "MintFinder works fully offline - no internet connection "
        "needed to identify a plant.",
    "tl": "Gumagana ang MintFinder nang ganap na offline - hindi "
        "kailangan ng internet para makilala ang halaman.",
  },
  "reminder_item_2": {
    "en": "For best results, photograph a single, clearly-lit leaf "
        "against a plain background.",
    "tl": "Para sa pinakamainam na resulta, kumuha ng larawan ng "
        "iisang dahon na malinaw ang liwanag at may payak na "
        "background.",
  },
  "reminder_item_3": {
    "en": "Results are for educational reference only, not a "
        "substitute for professional medical advice.",
    "tl": "Ang mga resulta ay para sa edukasyon lamang, hindi kapalit "
        "ng payo ng propesyonal na doktor.",
  },
  "reminder_item_4": {
    "en": "Some leaf conditions (glare, clustered leaves, unusual "
        "angles) may affect accuracy.",
    "tl": "May mga kondisyon ng dahon (glare, magkakadikit na dahon, "
        "kakaibang anggulo) na maaaring makaapekto sa kawastuhan.",
  },
  "i_understand": {"en": "I understand", "tl": "Nauunawaan ko"},
  // Merged single outcome for any rejection (no leaf detected OR
  // species not matched) - per request, these are now ONE outcome,
  // not two, so there are exactly 4 possible results total: the 3
  // species + this one.
  "not_recognized_title": {"en": "Not Recognized", "tl": "Hindi Nakilala"},
  "not_recognized_message": {
    "en": "We couldn't recognize this. Please try a clearer photo of "
        "a single leaf, filling most of the frame, against a plain "
        "background.",
    "tl": "Hindi namin nakilala ito. Subukan ang mas malinaw na "
        "larawan ng iisang dahon, punan ang karamihan ng frame, "
        "laban sa payak na background.",
  },
  "confidence_label": {"en": "Confidence", "tl": "Kumpiyansa"},
  "green_ratio_label": {"en": "Green ratio", "tl": "Antas ng Berde"},
  "shape_coverage_label": {
    "en": "Shape coverage",
    "tl": "Saklaw ng Hugis",
  },
  "position_leaf": {
    "en": "Position the leaf within the frame",
    "tl": "Ilagay ang dahon sa loob ng frame",
  },
  "ok": {"en": "OK", "tl": "OK"},
  // Disclaimer page strings
  "disclaimer_heading": {"en": "Disclaimer", "tl": "Paalala"},
  "disclaimer_body": {
    "en": "This application is not a medical device. It identifies "
        "herbal plants for educational and reference purposes only. "
        "Users should remain vigilant and consult health "
        "professionals before using any plant medicinally.",
    "tl": "Ang application na ito ay hindi isang medical device. "
        "Kinikilala nito ang mga halamang gamot para sa edukasyon at "
        "reperensya lamang. Dapat maging maingat ang mga gumagamit "
        "at kumonsulta sa mga propesyonal sa kalusugan bago gamitin "
        "ang anumang halaman bilang gamot.",
  },
  "disclaimer_footer": {
    "en": "By continuing, you acknowledge that you have read and "
        "understood this disclaimer.",
    "tl": "Sa pagpapatuloy, kinikilala mo na nabasa at naunawaan mo "
        "ang paalalang ito.",
  },
  "disclaimer_continue": {
    "en": "I Understand, Continue",
    "tl": "Nauunawaan Ko, Magpatuloy",
  },
  // Interactive tutorial strings
  "tut_capture_instruction": {
    "en": "Position a leaf inside the frame, then tap the capture "
        "button below.",
    "tl": "Ilagay ang dahon sa loob ng frame, pagkatapos ay pindutin "
        "ang capture button sa ibaba.",
  },
  "tut_capture_retry": {
    "en": "Hmm, that doesn't look aligned. Adjust the angle and try "
        "again.",
    "tl": "Parang hindi maayos ang pagkakalagay. Ayusin ang anggulo "
        "at subukan muli.",
  },
  "tut_capture_success": {
    "en": "Perfect! That's a well-aligned photo.",
    "tl": "Ang galing! Maayos ang larawang iyan.",
  },
  "tut_upload_instruction": {
    "en": "Now try uploading a leaf photo from your gallery instead.",
    "tl": "Ngayon subukan namang mag-upload ng larawan ng dahon mula "
        "sa iyong gallery.",
  },
  "tut_upload_retry": {
    "en": "That photo doesn't look aligned either. Try a clearer one.",
    "tl": "Hindi rin maayos ang larawang iyan. Subukan ang mas "
        "malinaw.",
  },
  "tut_upload_success": {
    "en": "Nice! Gallery upload works the same way.",
    "tl": "Mahusay! Ganito rin gumagana ang gallery upload.",
  },
  "tut_controls_title": {
    "en": "A few more controls",
    "tl": "Ilang karagdagang kontrol",
  },
  "tut_controls_body": {
    "en": "Pinch to zoom, tap anywhere to focus, and use the "
        "brightness slider on the right edge.",
    "tl": "Pisilin (pinch) para mag-zoom, pindutin ang kahit saan "
        "para mag-focus, at gamitin ang brightness slider sa kanang "
        "gilid.",
  },
  "tut_finish": {
    "en": "You're ready! Tap below to start identifying plants.",
    "tl": "Handa ka na! Pindutin sa ibaba para simulan ang pagkilala "
        "ng halaman.",
  },
  "checking": {"en": "Checking...", "tl": "Sinusuri..."},
};