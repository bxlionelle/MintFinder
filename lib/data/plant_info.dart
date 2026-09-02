// lib/data/plant_info.dart
//
// FIXED: the Mojito Mint entry's key was "mojito", but the classifier's
// actual output class name (see CLASS_NAMES in train_model.py /
// classifier_service.dart's label_map) is "mojito_mint". That mismatch
// meant ResultPage would show "Plant data not found" for every real
// mojito_mint prediction. Fixed to "mojito_mint" below.
//
// ADDED: parallel "_tl" (Tagalog) fields alongside the existing English
// content, for AlmanacDetailPage's language switching. Scientific names
// are not translated (Latin binomials are language-independent).
// otherNames already included Filipino/regional terms, so no separate
// otherNames_tl was added.
//
// IMPORTANT: the "_tl" text below is a good-faith translation, not a
// verified medical translation - please have a native Tagalog speaker
// (or a panel member) review the wording, especially the safety
// measures, before presenting it as final/authoritative.

const Map<String, Map<String, dynamic>> plantInfo = {
  "cat_whiskers": {
    "name": "Cat's Whiskers",
    "name_tl": "Balbas-pusa",
    "scientific": "Orthosiphon aristatus",
    "image": "assets/plants/cats_whiskers.jpg",
    "description":
        "A medicinal herb native to Southeast Asia, recognized by its striking long white or purple stamens that resemble a cat's whiskers. Widely used in traditional medicine for its diuretic and anti-inflammatory properties.",
    "description_tl":
        "Isang halamang gamot na katutubo sa Timog-silangang Asya, kilala sa mahaba at kapansin-pansing puti o kulay-ube na estambre na kahawig ng bigote ng pusa. Malawakang ginagamit sa tradisyunal na gamot dahil sa diuretic at anti-inflammatory na katangian nito.",
    "definition":
        "Cat's Whiskers is a flowering herbaceous plant in the mint family (Lamiaceae). It grows up to 1.5 meters tall and thrives in tropical and subtropical climates. Its leaves are used to brew herbal teas believed to support kidney and urinary tract health.",
    "definition_tl":
        "Ang Balbas-pusa ay isang namumulaklak na halamang-damo sa pamilyang mint (Lamiaceae). Umaabot ito ng hanggang 1.5 metro ang taas at umuunlad sa tropikal at subtropikal na klima. Ginagamit ang mga dahon nito upang gumawa ng herbal tea na naniniwalang sumusuporta sa kalusugan ng bato at daluyan ng ihi.",
    "uses": [
      "Brewed as herbal tea (\"Java tea\") for urinary tract and kidney health",
      "Used as a natural diuretic to reduce water retention",
      "Applied topically for skin inflammation and wounds",
      "Traditional treatment for gout, rheumatism, and hypertension",
      "Used in folk medicine to manage blood sugar levels",
    ],
    "uses_tl": [
      "Iniinom bilang herbal tea (\"Java tea\") para sa kalusugan ng daluyan ng ihi at bato",
      "Ginagamit bilang natural na diuretic upang mabawasan ang pagtitigas ng tubig sa katawan",
      "Ipinapahid sa balat para sa pamamaga at sugat",
      "Tradisyunal na gamot para sa gout, rayuma, at altapresyon",
      "Ginagamit sa katutubong gamot upang pamahalaan ang antas ng asukal sa dugo",
    ],
    "safetyMeasures": [
      "Avoid use during pregnancy and breastfeeding — insufficient safety data",
      "Consult a doctor before use if taking diuretic medications (risk of interaction)",
      "Excessive consumption may cause electrolyte imbalance due to strong diuretic effect",
      "Not recommended for children under 12 without medical supervision",
      "Discontinue use and seek medical attention if allergic reactions occur",
    ],
    "safetyMeasures_tl": [
      "Iwasan ang paggamit habang buntis o nagpapasuso — kulang pa ang datos sa kaligtasan",
      "Kumonsulta sa doktor bago gamitin kung umiinom ng gamot na diuretic (posibleng interaksyon)",
      "Ang labis na paggamit ay maaaring magdulot ng electrolyte imbalance dahil sa malakas na diuretic effect",
      "Hindi inirerekomenda para sa mga batang wala pang 12 taong gulang nang walang superbisyon ng doktor",
      "Itigil ang paggamit at humingi ng tulong medikal kung magkaroon ng allergic reaction",
    ],
    "otherNames": ["Balbas pusa", "Java tea", "Kumis kucing", "Misai kucing"],
  },

  "lemon_basil": {
    "name": "Lemon Basil",
    "name_tl": "Solasi Limon",
    "scientific": "Ocimum basilicum var. citriodorum",
    "image": "assets/plants/lemon_basil.jpg",
    "description":
        "An aromatic culinary and medicinal herb with a distinct citrus-like scent caused by high concentrations of citral in its essential oils. Popular in Southeast Asian and Mediterranean cuisine.",
    "description_tl":
        "Isang mabangong halamang-gamot at panlasa na may natatanging amoy-lemon dahil sa mataas na konsentrasyon ng citral sa kanyang mga esensyal na langis. Popular sa lutuing Timog-silangang Asya at Mediterranean.",
    "definition":
        "Lemon Basil is a hybrid basil variety in the family Lamiaceae. It grows as a compact herb up to 50 cm tall with light green, slightly serrated leaves. It is widely cultivated for its culinary flavor and its volatile oils, which have antimicrobial and antioxidant properties.",
    "definition_tl":
        "Ang Solasi Limon ay isang hybrid na uri ng basil sa pamilyang Lamiaceae. Lumalaki ito bilang maliit na halaman na hanggang 50 cm ang taas na may magaan na berdeng dahon na bahagyang may ngipin-ngipin na gilid. Malawakang itinatanim dahil sa panlasang dulot nito at sa mga pabagu-bagong langis na may antimicrobial at antioxidant na katangian.",
    "uses": [
      "Culinary herb used in salads, soups, sauces, and teas",
      "Essential oil used in aromatherapy to reduce stress and anxiety",
      "Crushed leaves applied to relieve insect bites and minor skin irritations",
      "Leaf infusion used as a digestive remedy for bloating and indigestion",
      "Used in traditional medicine as an antimicrobial and antifungal agent",
    ],
    "uses_tl": [
      "Ginagamit sa lutuin tulad ng salad, sabaw, sarsa, at tsaa",
      "Ginagamit ang esensyal na langis sa aromatherapy upang mabawasan ang stress at pagkabalisa",
      "Idinidikdik na dahon na ipinapahid para sa kagat ng insekto at maliit na iritasyon sa balat",
      "Iniinom bilang tsaa upang tulungan ang pagtunaw at bloating",
      "Ginagamit sa tradisyunal na gamot bilang antimicrobial at antifungal",
    ],
    "safetyMeasures": [
      "High doses of basil essential oil should be avoided — may cause liver toxicity",
      "People with bleeding disorders or taking blood thinners should limit consumption",
      "Avoid concentrated essential oil contact with eyes and mucous membranes",
      "Rare allergic reactions (contact dermatitis) have been reported — patch-test before topical use",
      "Pregnant women should avoid consuming large medicinal quantities (culinary amounts are safe)",
    ],
    "safetyMeasures_tl": [
      "Iwasan ang malaking dosis ng esensyal na langis ng basil — maaaring makapinsala sa atay",
      "Ang mga taong may bleeding disorder o umiinom ng blood thinner ay dapat limitahan ang paggamit",
      "Iwasan ang direktang pagdikit ng konsentradong langis sa mata at mucous membrane",
      "May bihirang naiulat na allergic reaction (contact dermatitis) — mag-patch test bago ipahid sa balat",
      "Dapat iwasan ng mga buntis ang malaking dosis na panggamot (ligtas ang dami na ginagamit sa pagluluto)",
    ],
    "otherNames": ["Lemon herb", "Kemangi", "Solasi limon", "Thai lemon basil"],
  },

  "mojito_mint": {
    "name": "Mojito Mint",
    "name_tl": "Yerba Buena",
    "scientific": "Mentha x villosa",
    "image": "assets/plants/mojito_mint.jpg",
    "description":
        "A robust and fragrant mint variety originally cultivated in Cuba, known for its broad, crinkled leaves and sweet, mild flavor. It is the classic mint used in the famous Mojito cocktail and is also valued for its medicinal and culinary properties.",
    "description_tl":
        "Isang matibay at mabangong uri ng mint na unang itinanim sa Cuba, kilala sa malapad at kulot na dahon at matamis, banayad na lasa. Ito ang klasikong mint na ginagamit sa sikat na Mojito cocktail at pinahahalagahan din dahil sa medisinal at panlutong katangian nito.",
    "definition":
        "Mojito Mint is a hybrid mint in the family Lamiaceae, believed to be a cross between Mentha spicata and Mentha villosa. It grows as a vigorous perennial up to 80 cm tall with large, soft, textured leaves. It contains less menthol than peppermint, giving it a sweeter and gentler aroma suited for beverages and cooking.",
    "definition_tl":
        "Ang Mojito Mint ay isang hybrid na mint sa pamilyang Lamiaceae, na pinaniniwalaang halo ng Mentha spicata at Mentha villosa. Lumalaki ito bilang matatag na perennial na hanggang 80 cm ang taas na may malaki, malambot, at texturadong dahon. Mas kaunti ang menthol nito kumpara sa peppermint, kaya mas matamis at banayad ang aroma nito, angkop sa inumin at lutuin.",
    "uses": [
      "Signature herb in Mojito cocktails and other refreshing beverages",
      "Brewed as herbal tea to relieve nausea, indigestion, and bloating",
      "Crushed leaves used to soothe insect bites and minor skin irritations",
      "Inhaled steam from mojito mint tea used to ease nasal congestion",
      "Culinary herb used in salads, sauces, desserts, and fruit dishes",
    ],
    "uses_tl": [
      "Pangunahing sangkap sa Mojito cocktail at iba pang nakapreskong inumin",
      "Iniinom bilang tsaa upang mapawi ang pagduduwal, pagtunaw, at bloating",
      "Idinidikdik na dahon upang mapawi ang kagat ng insekto at maliit na iritasyon sa balat",
      "Ang singaw mula sa mainit na tsaa ay ginagamit para mabawasan ang baradong ilong",
      "Ginagamit sa lutuin tulad ng salad, sarsa, panghimagas, at pagkaing may prutas",
    ],
    "safetyMeasures": [
      "Avoid applying undiluted mint oil directly on skin — always dilute with a carrier oil",
      "Not recommended for infants or very young children — mint compounds may cause breathing discomfort",
      "Excessive consumption may cause heartburn or acid reflux in sensitive individuals",
      "People with gallstones should consult a doctor before regular use",
      "Discontinue use if allergic reactions such as rash or throat irritation occur",
    ],
    "safetyMeasures_tl": [
      "Iwasan ang direktang paglapat ng purong mint oil sa balat — laging i-dilute gamit ang carrier oil",
      "Hindi inirerekomenda para sa sanggol o napakabatang bata — maaaring magdulot ng kahirapan sa paghinga ang mga compound ng mint",
      "Ang labis na paggamit ay maaaring magdulot ng heartburn o acid reflux sa mga sensitibong tao",
      "Ang mga taong may gallstones ay dapat kumonsulta sa doktor bago regular na gamitin",
      "Itigil ang paggamit kung may allergic reaction tulad ng pantal o pangangati ng lalamunan",
    ],
    "otherNames": ["Cuban mint", "Mojito herb", "Hierba buena", "Yerba buena"],
  },
};