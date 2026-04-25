// lib/data/plant_info.dart

const Map<String, Map<String, dynamic>> plantInfo = {
  "cats_whiskers": {
    "name": "Cat's Whiskers",
    "scientific": "Orthosiphon aristatus",
    "image": "assets/plants/cats_whiskers.png", // ← image path
    "description":
        "A medicinal herb native to Southeast Asia, recognized by its striking long white or purple stamens that resemble a cat's whiskers. Widely used in traditional medicine for its diuretic and anti-inflammatory properties.",
    "definition":
        "Cat's Whiskers is a flowering herbaceous plant in the mint family (Lamiaceae). It grows up to 1.5 meters tall and thrives in tropical and subtropical climates. Its leaves are used to brew herbal teas believed to support kidney and urinary tract health.",
    "uses": [
      "Brewed as herbal tea (\"Java tea\") for urinary tract and kidney health",
      "Used as a natural diuretic to reduce water retention",
      "Applied topically for skin inflammation and wounds",
      "Traditional treatment for gout, rheumatism, and hypertension",
      "Used in folk medicine to manage blood sugar levels",
    ],
    "safetyMeasures": [
      "Avoid use during pregnancy and breastfeeding — insufficient safety data",
      "Consult a doctor before use if taking diuretic medications (risk of interaction)",
      "Excessive consumption may cause electrolyte imbalance due to strong diuretic effect",
      "Not recommended for children under 12 without medical supervision",
      "Discontinue use and seek medical attention if allergic reactions occur",
    ],
    "otherNames": ["Balbas pusa", "Java tea", "Kumis kucing", "Misai kucing"],
  },


  "lemon_basil": {
    "name": "Lemon Basil",
    "scientific": "Ocimum basilicum var. citriodorum",
    "image": "assets/plants/lemon_basil.png", // ← image path
    "description":
        "An aromatic culinary and medicinal herb with a distinct citrus-like scent caused by high concentrations of citral in its essential oils. Popular in Southeast Asian and Mediterranean cuisine.",
    "definition":
        "Lemon Basil is a hybrid basil variety in the family Lamiaceae. It grows as a compact herb up to 50 cm tall with light green, slightly serrated leaves. It is widely cultivated for its culinary flavor and its volatile oils, which have antimicrobial and antioxidant properties.",
    "uses": [
      "Culinary herb used in salads, soups, sauces, and teas",
      "Essential oil used in aromatherapy to reduce stress and anxiety",
      "Crushed leaves applied to relieve insect bites and minor skin irritations",
      "Leaf infusion used as a digestive remedy for bloating and indigestion",
      "Used in traditional medicine as an antimicrobial and antifungal agent",
    ],
    "safetyMeasures": [
      "High doses of basil essential oil should be avoided — may cause liver toxicity",
      "People with bleeding disorders or taking blood thinners should limit consumption",
      "Avoid concentrated essential oil contact with eyes and mucous membranes",
      "Rare allergic reactions (contact dermatitis) have been reported — patch-test before topical use",
      "Pregnant women should avoid consuming large medicinal quantities (culinary amounts are safe)",
    ],
    "otherNames": ["Lemon herb", "Kemangi", "Solasi limon", "Thai lemon basil"],
  },


  "mojito_mint": {
    "name": "Mojito Mint",
    "scientific": "Mentha spicata",
    "image": "assets/plants/spearmint.png", // ← image path
    "description":
        "A refreshing mint herb widely used in teas, culinary preparations, and traditional medicine. It is milder than peppermint and prized for its sweet, cool flavor and digestive benefits.",
    "definition":
        "Spearmint is a perennial herbaceous plant of the family Lamiaceae. It spreads through rhizomes and grows up to 90 cm tall. The primary active component, carvone, gives it its characteristic flavor. It is widely cultivated for culinary, pharmaceutical, and cosmetic uses.",
    "uses": [
      "Herbal tea for relieving nausea, indigestion, and bloating",
      "Used as a flavoring agent in food, beverages, toothpaste, and gum",
      "Inhaled steam from spearmint tea used to ease nasal congestion",
      "Applied topically (diluted oil) to soothe muscle aches and headaches",
      "Traditional remedy for hormonal imbalances and polycystic ovary syndrome (PCOS)",
    ],
    "safetyMeasures": [
      "Avoid spearmint oil undiluted on skin — dilute with a carrier oil before topical use",
      "Excessive intake of spearmint tea (more than 3 cups/day) may affect hormone levels",
      "Not recommended for infants or very young children — menthol compounds can cause breathing issues",
      "People with gallstones or severe acid reflux should consult a doctor before regular use",
      "Discontinue if allergic reactions such as rash or throat tightness occur",
    ],
    "otherNames": ["Mint", "Garden mint", "Hierba buena", "Common mint"],
  },
  "unknown": {
    "name": "Unknown Plant",
    "scientific": "-",
    "image": "assets/plants/unknown.png",
    "description":
        "The system could not confidently identify this plant. Please try scanning again with a clearer, well-lit leaf image.",
    "definition":
        "This is a placeholder entry shown when the AI model cannot reach the confidence threshold for recognition.",
    "uses": [],
    "safetyMeasures": [
      "Do not consume or use unidentified plants.",
      "Consult reliable references or experts before handling unknown species.",
  ],
  "otherNames": [],
},

};