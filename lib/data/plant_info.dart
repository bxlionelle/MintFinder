// lib/data/plant_info.dart

const Map<String, Map<String, dynamic>> plantInfo = {
  // Match these keys to exactly what is in your labels.txt
  "cats_whiskers": {
    "name": "Cat's Whiskers",
    "scientific": "Orthosiphon aristatus",
    "description": "A medicinal herb known for its long white or purple stamens.",
    "otherNames": ["Balbas pusa", "Java tea"]
  },
  "gmelina": { // Changed from gmelina_arborea to match TM label
    "name": "Gmelina",
    "scientific": "Gmelina arborea",
    "description": "A fast-growing deciduous tree commonly planted for timber.",
    "otherNames": ["Yemane", "White teak"]
  },
  "lemon_basil": {
    "name": "Lemon Basil",
    "scientific": "Ocimum basilicum",
    "description": "An aromatic herb with a citrus-like scent.",
    "otherNames": ["Lemon herb", "Kemangi"]
  },
  "mayana": {
    "name": "Mayana",
    "scientific": "Coleus scutellarioides",
    "description": "A medicinal and ornamental plant known for its colorful leaves.",
    "otherNames": ["Coleus", "Painted nettle"]
  },
  "mojito": {
    "name": "Mojito mint",
    "scientific": "Mentha spicata",
    "description": "A mint herb used in teas and culinary preparations.",
    "otherNames": ["Mint", "Garden mint"]
  }
};