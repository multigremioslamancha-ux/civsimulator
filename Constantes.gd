extends Node
class_name Constantes

# ==============================================================================
# CONSTANTES DEL JUEGO - ÚNICO ORIGEN DE VERDAD DE LOS DATOS ESTÁTICOS
# ------------------------------------------------------------------------------
# Contiene TODOS los datos del juego: eras, civilizaciones, biomas, terrenos,
# características, recursos, edificios, mejoras, maravillas naturales y líderes.
# NO contiene lógica de juego ni estado de partida: es consumido de forma estática
# por Main.gd (por ejemplo: Constantes.DATOS_EDIFICIOS, Constantes.DATOS_RECURSOS).
# ==============================================================================

# ------------------------------------------------------------------------------
# ERAS Y CIVILIZACIONES
# ------------------------------------------------------------------------------
const ORDEN_ERAS = {
	"Antiquity": 1,
	"Exploration": 2,
	"Modern Age": 3,
	"All": 99
}

const CIVS_ANTIQUITY = ["Achaemenid Persian", "Aksumite", "Assyrian", "Babylonian", "Carthaginian", "Egyptian", "Gallic", "Greek", "Han", "Heian", "Khmer", "Mauryan", "Maya", "Mississippian", "Roman", "Silla", "Tongan"]
const CIVS_EXPLORATION = ["Abbasid", "Bulgarian", "Chola", "English", "Goryeo", "Hawaiian", "Icelandic", "Incan", "Majapahit", "Ming", "Mongolian", "Norman", "Pirate", "Sengoku", "Shawnee", "Songhai", "Spanish", "Vietnamese"]
const CIVS_MODERN = ["American", "British", "Bugandan", "French Imperial", "Joseon", "Meiji Japanese", "Mexican", "Mughal", "Nepalese", "Ottoman", "Prussian", "Qajar", "Qing", "Russian", "Siamese"]

const TODAS_LAS_CIVS = [
	"Achaemenid Persian", "Aksumite", "Assyrian", "Babylonian", "Carthaginian", "Egyptian", "Gallic", "Greek", "Han", "Heian", "Khmer", "Mauryan", "Maya", "Mississippian", "Roman", "Silla", "Tongan",
	"Abbasid", "Bulgarian", "Chola", "English", "Goryeo", "Hawaiian", "Icelandic", "Incan", "Majapahit", "Ming", "Mongolian", "Norman", "Pirate", "Sengoku", "Shawnee", "Songhai", "Spanish", "Vietnamese",
	"American", "British", "Bugandan", "French Imperial", "Joseon", "Meiji Japanese", "Mexican", "Mughal", "Nepalese", "Ottoman", "Prussian", "Qajar", "Qing", "Russian", "Siamese"
]

# Estados de relación con un rival - valores EXACTOS que usa el modal de
# Configuración de Rivales (orden del más positivo al más negativo).
const ESTADOS_RELACION = ["Alianza", "Gran Relación", "Buena relación", "Neutro", "Mala Relación", "Furioso", "Guerra"]

# Colores de identificación rápida de la relación con cada rival. El texto del
# selector se tiñe en negro o blanco según la luminancia del color para que
# siempre sea legible (la Guerra es negro -> texto blanco, etc.).
const COLORES_RELACION = {
	"Alianza": Color(0.16, 0.65, 0.30),
	"Gran Relación": Color(0.55, 0.85, 0.50),
	"Buena relación": Color(0.95, 0.85, 0.25),
	"Neutro": Color(0.25, 0.50, 0.95),
	"Mala Relación": Color(0.95, 0.55, 0.18),
	"Furioso": Color(0.55, 0.35, 0.18),
	"Guerra": Color(0.03, 0.03, 0.03),
}

# ------------------------------------------------------------------------------
# BIOMAS, TERRENOS Y CARACTERISTICAS
# ------------------------------------------------------------------------------
const BIOMAS = ["TUNDRA", "GRASSLAND", "PLAINS", "DESERT", "TROPICAL", "MARINE"]
const TERRENOS_TIERRA = ["FLAT", "ROUGH", "MOUNTAINOUS", "NAVIGABLE_RIVER"]
const TERRENOS_AGUA = ["LAKE", "COASTAL", "OCEAN"]
const CARACTERISTICAS = ["NONE", "WET", "VEGETATED", "AQUATIC", "FLOODPLAIN", "VOLCANO", "ICE", "SNOW", "NATURAL_WONDER"]

const COLORES_BIOMA = {
	"TUNDRA": Color(0.85, 0.85, 0.85),
	"DESERT": Color(0.95, 0.55, 0.1),
	"TROPICAL": Color(0.05, 0.35, 0.15),
	"PLAINS": Color(0.75, 0.75, 0.2),
	"GRASSLAND": Color(0.4, 0.8, 0.3),
	"MARINE": Color(0.1, 0.45, 0.8)
}

const ICONOS_TERRENO = {
	"FLAT": "", "MOUNTAINOUS": "⛰️", "ROUGH": "🪨", "NAVIGABLE_RIVER": "🚢",
	"LAKE": "🛶", "COASTAL": "🌊", "OCEAN": "🐋"
}

# ------------------------------------------------------------------------------
# RECURSOS
# ------------------------------------------------------------------------------
# DATOS_RECURSOS: única fuente de verdad de los recursos. La clave es el nombre
# del recurso y el valor un diccionario con todos sus atributos:
#   - rendimiento      : {"tipo": <rendimiento>, "cantidad": <int>}. Si un
#                        recurso da varios rendimientos (p. ej. Pitch) el valor
#                        es un ARRAY de diccionarios con esa misma forma.
#   - mejora           : improvement asociada (Camp, Mine, Plantation...).
#   - eras             : eras en las que el recurso aparece.
#   - terrenos_validos : terrenos donde puede ubicarse. Entradas admitidas:
#                        "Flat X"/"Rough X" (terreno+bioma), un bioma simple
#                        ("Grassland"...) que implica Flat/Rough sin feature,
#                        "Flat"/"Rough", o "Coastal"/"Lake"/"Ocean"/
#                        "Navigable River".
#   - features_validas : features de la celda (con su denominación canónica:
#                        "Marsh", "Forest", "Desert Floodplain"...) donde puede
#                        ubicarse. La entrada especial "Floodplains" acepta
#                        cualquier floodplain.
# Consumido por Main.gd: botones de recursos, validación de celda, compatibilidad
# con mejoras y rendimientos de celda.
const DATOS_RECURSOS = {
	"Camels": {"rendimiento": {"tipo": "Gold", "cantidad": 1}, "mejora": "Camp", "eras": ["Antiquity", "Exploration"], "terrenos_validos": ["Flat Desert", "Rough Desert", "Flat Plains", "Rough Plains"], "features_validas": []},
	"Clay": {"rendimiento": {"tipo": "Production", "cantidad": 1}, "mejora": "Clay Pit", "eras": ["Antiquity", "Exploration"], "terrenos_validos": [], "features_validas": ["Tundra Bog", "Marsh", "Watering Hole", "Mangrove", "Oasis"]},
	"Cotton": {"rendimiento": {"tipo": "Gold", "cantidad": 1}, "mejora": "Plantation", "eras": ["Antiquity", "Exploration", "Modern Age"], "terrenos_validos": ["Flat Grassland"], "features_validas": ["Desert Floodplain", "Grassland Floodplain", "Plains Floodplain"]},
	"Cowrie": {"rendimiento": {"tipo": "Happiness", "cantidad": 1}, "mejora": "Fishing Boat", "eras": ["Antiquity", "Exploration", "Modern Age"], "terrenos_validos": ["Coastal"], "features_validas": []},
	"Crabs": {"rendimiento": {"tipo": "Food", "cantidad": 1}, "mejora": "Fishing Boat", "eras": ["Antiquity", "Exploration", "Modern Age"], "terrenos_validos": ["Coastal", "Lake", "Navigable River"], "features_validas": []},
	"Dates": {"rendimiento": {"tipo": "Food", "cantidad": 1}, "mejora": "Plantation", "eras": ["Antiquity", "Exploration"], "terrenos_validos": ["Flat Desert"], "features_validas": ["Oasis"]},
	"Dyes": {"rendimiento": {"tipo": "Culture", "cantidad": 1}, "mejora": "Fishing Boat", "eras": ["Antiquity", "Exploration"], "terrenos_validos": ["Coastal"], "features_validas": []},
	"Fish": {"rendimiento": {"tipo": "Food", "cantidad": 1}, "mejora": "Fishing Boat", "eras": ["Antiquity", "Exploration", "Modern Age"], "terrenos_validos": ["Coastal", "Ocean"], "features_validas": []},
	"Flax": {"rendimiento": {"tipo": "Science", "cantidad": 1}, "mejora": "Plantation", "eras": ["Antiquity", "Exploration"], "terrenos_validos": ["Grassland", "Plains"], "features_validas": ["Forest", "Savanna Woodland"]},
	"Gold": {"rendimiento": {"tipo": "Gold", "cantidad": 1}, "mejora": "Mine", "eras": ["Antiquity", "Exploration", "Modern Age"], "terrenos_validos": ["Rough Grassland", "Rough Plains", "Rough Tropical"], "features_validas": []},
	"Gypsum": {"rendimiento": {"tipo": "Science", "cantidad": 1}, "mejora": "Quarry", "eras": ["Antiquity", "Exploration"], "terrenos_validos": ["Flat Plains", "Rough Plains", "Rough Tundra"], "features_validas": []},
	"Hardwood": {"rendimiento": {"tipo": "Culture", "cantidad": 1}, "mejora": "Woodcutter", "eras": ["Antiquity", "Exploration", "Modern Age"], "terrenos_validos": ["Tundra", "Tropical"], "features_validas": ["Tundra Bog", "Mangrove"]},
	"Hides": {"rendimiento": {"tipo": "Production", "cantidad": 1}, "mejora": "Camp", "eras": ["Antiquity"], "terrenos_validos": ["Flat Grassland", "Flat Plains", "Flat Tundra"], "features_validas": ["Taiga", "Tundra Bog", "Tundra Floodplain"]},
	"Horses": {"rendimiento": {"tipo": "Production", "cantidad": 1}, "mejora": "Pasture", "eras": ["Antiquity", "Exploration", "Modern Age"], "terrenos_validos": ["Flat Grassland", "Flat Plains"], "features_validas": []},
	"Incense": {"rendimiento": {"tipo": "Science", "cantidad": 1}, "mejora": "Plantation", "eras": ["Antiquity", "Exploration"], "terrenos_validos": [], "features_validas": ["Sagebrush Steppe", "Savanna Woodland"]},
	"Iron": {"rendimiento": {"tipo": "Production", "cantidad": 1}, "mejora": "Mine", "eras": ["Antiquity", "Exploration"], "terrenos_validos": ["Rough"], "features_validas": []},
	"Ivory": {"rendimiento": {"tipo": "Culture", "cantidad": 1}, "mejora": "Camp", "eras": ["Antiquity", "Exploration", "Modern Age"], "terrenos_validos": ["Flat Desert", "Flat Plains", "Rough Plains", "Flat Tropical"], "features_validas": ["Sagebrush Steppe", "Forest", "Watering Hole", "Rainforest"]},
	"Jade": {"rendimiento": {"tipo": "Culture", "cantidad": 1}, "mejora": "Quarry", "eras": ["Antiquity", "Exploration", "Modern Age"], "terrenos_validos": ["Flat Plains", "Flat Tropical", "Flat Tundra"], "features_validas": []},
	"Kaolin": {"rendimiento": {"tipo": "Food", "cantidad": 1}, "mejora": "Quarry", "eras": ["Antiquity", "Exploration", "Modern Age"], "terrenos_validos": [], "features_validas": ["Marsh", "Watering Hole", "Mangrove"]},
	"Limestone": {"rendimiento": {"tipo": "Production", "cantidad": 1}, "mejora": "Quarry", "eras": ["Antiquity", "Exploration", "Modern Age"], "terrenos_validos": ["Grassland", "Plains", "Desert"], "features_validas": ["Oasis"]},
	"Llamas": {"rendimiento": {"tipo": "Happiness", "cantidad": 1}, "mejora": "Pasture", "eras": ["Antiquity", "Exploration", "Modern Age"], "terrenos_validos": ["Tropical"], "features_validas": ["Rainforest"]},
	"Mangoes": {"rendimiento": {"tipo": "Culture", "cantidad": 1}, "mejora": "Plantation", "eras": ["Antiquity", "Exploration"], "terrenos_validos": ["Tropical"], "features_validas": ["Rainforest"]},
	"Marble": {"rendimiento": {"tipo": "Culture", "cantidad": 1}, "mejora": "Quarry", "eras": ["Antiquity", "Exploration", "Modern Age"], "terrenos_validos": ["Flat Grassland", "Rough Grassland", "Rough Plains"], "features_validas": []},
	"Pearls": {"rendimiento": {"tipo": "Gold", "cantidad": 1}, "mejora": "Fishing Boat", "eras": ["Antiquity", "Exploration", "Modern Age"], "terrenos_validos": ["Coastal"], "features_validas": []},
	"Rice": {"rendimiento": {"tipo": "Food", "cantidad": 1}, "mejora": "Plantation", "eras": ["Antiquity", "Exploration", "Modern Age"], "terrenos_validos": [], "features_validas": ["Marsh", "Watering Hole", "Mangrove"]},
	"Rubies": {"rendimiento": {"tipo": "Gold", "cantidad": 1}, "mejora": "Mine", "eras": ["Antiquity", "Exploration"], "terrenos_validos": ["Plains", "Tropical", "Desert"], "features_validas": []},
	"Salt": {"rendimiento": {"tipo": "Food", "cantidad": 1}, "mejora": "Mine", "eras": ["Antiquity"], "terrenos_validos": ["Flat Desert", "Flat Plains", "Flat Tundra"], "features_validas": []},
	"Silk": {"rendimiento": {"tipo": "Culture", "cantidad": 1}, "mejora": "Plantation", "eras": ["Antiquity", "Exploration", "Modern Age"], "terrenos_validos": ["Flat Plains"], "features_validas": ["Grassland Floodplain", "Plains Floodplain", "Tropical Floodplain"]},
	"Silver": {"rendimiento": {"tipo": "Gold", "cantidad": 1}, "mejora": "Mine", "eras": ["Antiquity", "Exploration", "Modern Age"], "terrenos_validos": ["Rough Desert", "Rough Tundra"], "features_validas": []},
	"Tin": {"rendimiento": {"tipo": "Production", "cantidad": 1}, "mejora": "Mine", "eras": ["Antiquity", "Exploration", "Modern Age"], "terrenos_validos": ["Tropical", "Plains"], "features_validas": []},
	"Turtles": {"rendimiento": {"tipo": "Culture", "cantidad": 1}, "mejora": "Fishing Boat", "eras": ["Antiquity", "Exploration"], "terrenos_validos": ["Coastal"], "features_validas": []},
	"Wild Game": {"rendimiento": {"tipo": "Food", "cantidad": 1}, "mejora": "Camp", "eras": ["Antiquity", "Exploration"], "terrenos_validos": ["Tropical", "Grassland", "Tundra"], "features_validas": ["Rainforest", "Tundra Bog", "Marsh"]},
	"Wine": {"rendimiento": {"tipo": "Happiness", "cantidad": 1}, "mejora": "Plantation", "eras": ["Antiquity", "Exploration", "Modern Age"], "terrenos_validos": ["Flat Grassland", "Flat Plains"], "features_validas": []},
	"Wool": {"rendimiento": {"tipo": "Production", "cantidad": 1}, "mejora": "Pasture", "eras": ["Antiquity"], "terrenos_validos": ["Rough"], "features_validas": []},
	"Cocoa": {"rendimiento": {"tipo": "Gold", "cantidad": 1}, "mejora": "Woodcutter", "eras": ["Exploration", "Modern Age"], "terrenos_validos": [], "features_validas": ["Rainforest"]},
	"Furs": {"rendimiento": {"tipo": "Gold", "cantidad": 1}, "mejora": "Camp", "eras": ["Exploration", "Modern Age"], "terrenos_validos": ["Flat Tundra"], "features_validas": ["Savanna Woodland", "Taiga", "Tundra Floodplain"]},
	"Niter": {"rendimiento": {"tipo": "Production", "cantidad": 1}, "mejora": "Mine", "eras": ["Exploration", "Modern Age"], "terrenos_validos": ["Flat"], "features_validas": ["Floodplains"]},
	"Pitch": {"rendimiento": [{"tipo": "Production", "cantidad": 1}, {"tipo": "Gold", "cantidad": 1}], "mejora": "Woodcutter", "eras": ["Exploration", "Modern Age"], "terrenos_validos": ["Grassland", "Plains", "Tundra"], "features_validas": []},
	"Spices": {"rendimiento": {"tipo": "Gold", "cantidad": 1}, "mejora": "Woodcutter", "eras": ["Exploration", "Modern Age"], "terrenos_validos": [], "features_validas": ["Forest", "Rainforest"]},
	"Sugar": {"rendimiento": {"tipo": "Food", "cantidad": 1}, "mejora": "Plantation", "eras": ["Exploration", "Modern Age"], "terrenos_validos": ["Flat Tropical"], "features_validas": ["Grassland Floodplain", "Plains Floodplain", "Tropical Floodplain"]},
	"Tea": {"rendimiento": {"tipo": "Science", "cantidad": 1}, "mejora": "Plantation", "eras": ["Exploration", "Modern Age"], "terrenos_validos": ["Flat Grassland", "Rough Grassland", "Flat Plains"], "features_validas": []},
	"Truffles": {"rendimiento": {"tipo": "Culture", "cantidad": 1}, "mejora": "Camp", "eras": ["Exploration", "Modern Age"], "terrenos_validos": ["Flat Grassland", "Rough Grassland"], "features_validas": ["Marsh", "Watering Hole", "Tundra Bog"]},
	"Whales": {"rendimiento": {"tipo": "Production", "cantidad": 1}, "mejora": "Fishing Boat", "eras": ["Exploration", "Modern Age"], "terrenos_validos": ["Coastal", "Ocean"], "features_validas": []},
	"Citrus": {"rendimiento": {"tipo": "Food", "cantidad": 1}, "mejora": "Plantation", "eras": ["Modern Age"], "terrenos_validos": ["Flat Grassland", "Flat Plains"], "features_validas": []},
	"Coal": {"rendimiento": {"tipo": "Production", "cantidad": 1}, "mejora": "Mine", "eras": ["Modern Age"], "terrenos_validos": ["Flat Desert", "Rough Grassland", "Rough Plains"], "features_validas": ["Forest", "Savanna Woodland", "Taiga"]},
	"Coffee": {"rendimiento": {"tipo": "Science", "cantidad": 1}, "mejora": "Plantation", "eras": ["Modern Age"], "terrenos_validos": ["Rough Plains", "Flat Tropical", "Rough Tropical"], "features_validas": ["Mangrove", "Rainforest", "Tropical Floodplain"]},
	"Oil": {"rendimiento": {"tipo": "Production", "cantidad": 1}, "mejora": "Oil Rig", "eras": ["Modern Age"], "terrenos_validos": ["Flat Desert", "Flat Tundra"], "features_validas": ["Desert Floodplain", "Oasis", "Sagebrush Steppe", "Marsh", "Taiga", "Tundra Bog", "Tundra Floodplain"]},
	"Quinine": {"rendimiento": {"tipo": "Food", "cantidad": 1}, "mejora": "Woodcutter", "eras": ["Modern Age"], "terrenos_validos": [], "features_validas": ["Forest", "Savanna Woodland"]},
	"Rubber": {"rendimiento": {"tipo": "Production", "cantidad": 1}, "mejora": "Woodcutter", "eras": ["Modern Age"], "terrenos_validos": [], "features_validas": ["Forest", "Rainforest"]},
	"Tobacco": {"rendimiento": {"tipo": "Gold", "cantidad": 1}, "mejora": "Plantation", "eras": ["Modern Age"], "terrenos_validos": ["Flat Grassland", "Flat Plains"], "features_validas": ["Forest", "Savanna Woodland"]}
}

# ------------------------------------------------------------------------------
# EDIFICIOS Y MARAVILLAS CONSTRUIBLES
# ------------------------------------------------------------------------------
const DATOS_EDIFICIOS = {
	"Town Hall": {"rendimiento": "Town Hall", "era": "All", "base": 0, "desc": "Settlement Center", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Central"},
	"Palace": {"rendimiento": "Palace", "era": "All", "base": 0, "desc": "Seat of Government", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Central"},
	
	"Academy": {"rendimiento": "Science", "era": "Antiquity", "base": 4, "desc": "3 Great Work slots", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Altar": {"rendimiento": "Happiness", "era": "Antiquity", "base": 3, "desc": "+1 Sci per Veg", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Amphitheater": {"rendimiento": "Culture", "era": "Antiquity", "base": 4, "desc": "10% Prod to Wonders", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Ancient Bridge": {"rendimiento": "Gold", "era": "Antiquity", "base": 4, "desc": "Cross Rivers", "req_terreno": ["NAVIGABLE_RIVER"], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Ancient Walls": {"rendimiento": "Production", "era": "Antiquity", "base": 0, "desc": "+100 HP District", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Fortification"},
	"Arena": {"rendimiento": "Happiness", "era": "Antiquity", "base": 4, "desc": "+1 Happy on Quarters", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": true, "tipo": "Standard"},
	"Barracks": {"rendimiento": "Production", "rendimiento_secundario": "Military", "era": "Antiquity", "base": 3, "desc": "10% Prod towards land units", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Bath": {"rendimiento": "Food", "era": "Antiquity", "base": 4, "desc": "10% Growth Rate", "req_terreno": [], "req_rio": true, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Blacksmith": {"rendimiento": "Production", "era": "Antiquity", "base": 4, "desc": "+1 Prod on Quarters", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": true, "tipo": "Standard"},
	"Brickyard": {"rendimiento": "Warehouse", "era": "Antiquity", "base": 1, "desc": "+1 Prod on Clay/Mine/Quarry", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Warehouse"},
	"Fishing Quay": {"rendimiento": "Warehouse", "era": "Antiquity", "base": 1, "desc": "+1 Food on Fish Boats", "req_terreno": ["COASTAL", "LAKE", "NAVIGABLE_RIVER"], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Warehouse"},
	"Garden": {"rendimiento": "Food", "rendimiento_secundario": "Happiness", "era": "Antiquity", "base": 3, "desc": "+2 Happiness", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Granary": {"rendimiento": "Warehouse", "era": "Antiquity", "base": 1, "desc": "+1 Food Farm/Past/Plant", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Warehouse"},
	"Harbor": {"rendimiento": "Warehouse", "era": "Antiquity", "base": 1, "desc": "+1 Prod on Fish Boats", "req_terreno": ["COASTAL", "LAKE", "NAVIGABLE_RIVER"], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Warehouse"},
	"Library": {"rendimiento": "Science", "era": "Antiquity", "base": 3, "desc": "2 Great Work slots", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Lighthouse": {"rendimiento": "Gold", "era": "Antiquity", "base": 4, "desc": "2 Res slots", "req_terreno": ["COASTAL"], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Market": {"rendimiento": "Gold", "era": "Antiquity", "base": 3, "desc": "1 Res slot", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Monument": {"rendimiento": "Culture", "rendimiento_secundario": "Influence", "era": "Antiquity", "base": 3, "desc": "+2 Infl", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Saw Pit": {"rendimiento": "Warehouse", "era": "Antiquity", "base": 1, "desc": "+1 Prod Camp/Wood", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Warehouse"},
	"Villa": {"rendimiento": "Happiness", "rendimiento_secundario": "Influence", "era": "Antiquity", "base": 3, "desc": "+3 Infl. +3 Happy", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	
	"Armorer": {"rendimiento": "Production", "rendimiento_secundario": "Military", "era": "Exploration", "base": 8, "desc": "10% Prod Land Units", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Bank": {"rendimiento": "Gold", "era": "Exploration", "base": 8, "desc": "+1 Gold on Quarters", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": true, "tipo": "Standard"},
	"Bazaar": {"rendimiento": "Gold", "era": "Exploration", "base": 6, "desc": "1 Res Slot", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Dungeon": {"rendimiento": "Production", "rendimiento_secundario": "Influence", "era": "Exploration", "base": 6, "desc": "+4 Infl", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Gristmill": {"rendimiento": "Warehouse", "era": "Exploration", "base": 4, "desc": "+1 Food Farm/Past/Plant", "req_terreno": [], "req_rio": true, "full_tile": false, "adj_barrio": false, "tipo": "Warehouse"},
	"Guildhall": {"rendimiento": "Gold", "rendimiento_secundario": "Influence", "era": "Exploration", "base": 6, "desc": "+6 Infl", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Hospital": {"rendimiento": "Food", "era": "Exploration", "base": 8, "desc": "15% Growth", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Inn": {"rendimiento": "Food", "rendimiento_secundario": "Happiness", "era": "Exploration", "base": 6, "desc": "+4 Happy", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Kiln": {"rendimiento": "Culture", "era": "Exploration", "base": 6, "desc": "10% to Wonders", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Medieval Bridge": {"rendimiento": "Gold", "era": "Exploration", "base": 4, "desc": "Cross Rivers", "req_terreno": ["NAVIGABLE_RIVER"], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Medieval Walls": {"rendimiento": "Production", "era": "Exploration", "base": 0, "desc": "+100 HP", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Fortification"},
	"Menagerie": {"rendimiento": "Happiness", "era": "Exploration", "base": 8, "desc": "+1 Happy Camps/Pastures", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Observatory": {"rendimiento": "Science", "era": "Exploration", "base": 6, "desc": "+1 Sci per Mount/Res", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Pavilion": {"rendimiento": "Culture", "era": "Exploration", "base": 8, "desc": "+1 Happy on Quarters", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": true, "tipo": "Standard"},
	"Sawmill": {"rendimiento": "Warehouse", "era": "Exploration", "base": 3, "desc": "+1 Prod Camp/Wood", "req_terreno": [], "req_rio": true, "full_tile": false, "adj_barrio": false, "tipo": "Warehouse"},
	"Shipyard": {"rendimiento": "Production", "rendimiento_secundario": "Military", "era": "Exploration", "base": 8, "desc": "10% Prod Naval", "req_terreno": ["COASTAL", "NAVIGABLE_RIVER"], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Stonecutter": {"rendimiento": "Warehouse", "era": "Exploration", "base": 3, "desc": "+1 Prod Mine/Quarry", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Warehouse"},
	"Temple": {"rendimiento": "Happiness", "era": "Exploration", "base": 6, "desc": "1 GW Slot", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"University": {"rendimiento": "Science", "era": "Exploration", "base": 8, "desc": "+1 Sci on Quarters", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": true, "tipo": "Standard"},
	"Wharf": {"rendimiento": "Food", "era": "Exploration", "base": 6, "desc": "2 Res slots", "req_terreno": ["COASTAL", "NAVIGABLE_RIVER"], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	
	"Aerodrome": {"rendimiento": "Production", "rendimiento_secundario": "Military", "era": "Modern Age", "base": 9, "desc": "Air Units", "req_terreno": ["FLAT"], "req_rio": false, "full_tile": true, "adj_barrio": false, "tipo": "Standard", "no_pair": true},
	"Cannery": {"rendimiento": "Food", "era": "Modern Age", "base": 9, "desc": "10% Growth", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"City Park": {"rendimiento": "Happiness", "era": "Modern Age", "base": 9, "desc": "+1 Happy on Veg", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Defensive Fortifications": {"rendimiento": "Production", "era": "Modern Age", "base": 0, "desc": "+100 HP", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Fortification"},
	"Department Store": {"rendimiento": "Happiness", "era": "Modern Age", "base": 12, "desc": "1 Res Slot", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Factory": {"rendimiento": "Production", "rendimiento_secundario": "Resource", "era": "Modern Age", "base": 12, "desc": "1 Factory Res Slot", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": true, "tipo": "Standard"},
	"Grocer": {"rendimiento": "Warehouse", "era": "Modern Age", "base": 4, "desc": "+1 Food to All Food Imps", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Warehouse"},
	"Ironworks": {"rendimiento": "Warehouse", "era": "Modern Age", "base": 4, "desc": "+1 Prod to All Prod Imps", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Warehouse"},
	"Laboratory": {"rendimiento": "Science", "era": "Modern Age", "base": 12, "desc": "+1 Sci on Quarters", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": true, "tipo": "Standard"},
	"Launch Pad": {"rendimiento": "Science", "era": "Modern Age", "base": 18, "desc": "Launch Satellite", "req_terreno": ["FLAT"], "req_rio": false, "full_tile": true, "adj_barrio": false, "tipo": "Standard", "no_pair": true},
	"Military Academy": {"rendimiento": "Production", "rendimiento_secundario": "Military", "era": "Modern Age", "base": 9, "desc": "Free Commander Lvl", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Modern Bridge": {"rendimiento": "Gold", "era": "Modern Age", "base": 6, "desc": "Cross Rivers", "req_terreno": ["NAVIGABLE_RIVER"], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Museum": {"rendimiento": "Culture", "era": "Modern Age", "base": 9, "desc": "3 Artifacts slots", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Opera House": {"rendimiento": "Culture", "rendimiento_secundario": "Influence", "era": "Modern Age", "base": 12, "desc": "+6 Infl", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Port": {"rendimiento": "Gold", "era": "Modern Age", "base": 9, "desc": "2 Res slots", "req_terreno": ["COASTAL"], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Radio Station": {"rendimiento": "Happiness", "rendimiento_secundario": "Influence", "era": "Modern Age", "base": 9, "desc": "+9 Infl", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Rail Station": {"rendimiento": "Gold", "era": "Modern Age", "base": 9, "desc": "+9 Prod", "req_terreno": [], "req_rio": false, "full_tile": true, "adj_barrio": false, "tipo": "Standard", "no_pair": true},
	"Schoolhouse": {"rendimiento": "Science", "era": "Modern Age", "base": 9, "desc": "+1 Sci per Res", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Standard"},
	"Stock Exchange": {"rendimiento": "Gold", "era": "Modern Age", "base": 12, "desc": "+1 Gold on Quarters", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": true, "tipo": "Standard"},
	"Tenement": {"rendimiento": "Food", "era": "Modern Age", "base": 12, "desc": "+1 Happy on Quarters", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": true, "tipo": "Standard"},
	
	"Citadel": {"rendimiento": "Production", "rendimiento_secundario": "Fortification", "era": "Antiquity", "base": 3, "desc": "Assyrian Fortification", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Assyrian"},
	"Royal Library": {"rendimiento": "Science", "era": "Antiquity", "base": 3, "desc": "Assyrian Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Assyrian"},
	"Cothon": {"rendimiento": "Production", "rendimiento_secundario": "Water", "era": "Antiquity", "base": 2, "desc": "Carthaginian Unique", "req_terreno": ["COASTAL"], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Carthaginian"},
	"Dockyard": {"rendimiento": "Gold", "rendimiento_secundario": "Water", "era": "Antiquity", "base": 2, "desc": "Carthaginian Unique", "req_terreno": ["COASTAL"], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Carthaginian"},
	"Mastaba": {"rendimiento": "Culture", "era": "Antiquity", "base": 3, "desc": "Egyptian Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Egyptian"},
	"Mortuary Temple": {"rendimiento": "Gold", "era": "Antiquity", "base": 3, "desc": "Egyptian Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Egyptian"},
	"Odeon": {"rendimiento": "Happiness", "era": "Antiquity", "base": 3, "desc": "Greek Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Greek"},
	"Parthenon": {"rendimiento": "Culture", "era": "Antiquity", "base": 3, "desc": "Greek Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Greek"},
	"Dharamshala": {"rendimiento": "Happiness", "era": "Antiquity", "base": 3, "desc": "Mauryan Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Mauryan"},
	"Vihara": {"rendimiento": "Happiness", "era": "Antiquity", "base": 3, "desc": "Mauryan Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Mauryan"},
	"Jalaw": {"rendimiento": "Happiness", "era": "Antiquity", "base": 3, "desc": "Maya Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Maya"},
	"K'uh Nah": {"rendimiento": "Science", "era": "Antiquity", "base": 3, "desc": "Maya Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Maya"},
	"Basilica": {"rendimiento": "Influence", "era": "Antiquity", "base": 3, "desc": "Roman Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Roman"},
	"Temple of Jupiter": {"rendimiento": "Happiness", "era": "Antiquity", "base": 3, "desc": "Roman Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Roman"},
	"Lecture Hall": {"rendimiento": "Culture", "era": "Antiquity", "base": 3, "desc": "Silla Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Silla"},
	"Pagoda": {"rendimiento": "Happiness", "era": "Antiquity", "base": 3, "desc": "Silla Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Silla"},
	"Langi": {"rendimiento": "Culture", "era": "Antiquity", "base": 3, "desc": "Tongan Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Tongan"},
	"Vaikaukau": {"rendimiento": "Happiness", "era": "Antiquity", "base": 3, "desc": "Tongan Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Tongan"},
	"Mosque": {"rendimiento": "Happiness", "era": "Exploration", "base": 6, "desc": "Abbasid Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Abbasid"},
	"Madrasa": {"rendimiento": "Science", "era": "Exploration", "base": 6, "desc": "Abbasid Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Abbasid"},
	"Anjuvannam": {"rendimiento": "Gold", "rendimiento_secundario": "Military", "era": "Exploration", "base": 6, "desc": "Chola Unique", "req_terreno": ["COASTAL"], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Chola"},
	"Manigramam": {"rendimiento": "Happiness", "era": "Exploration", "base": 6, "desc": "Chola Unique", "req_terreno": ["COASTAL"], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Chola"},
	"Candi Bentar": {"rendimiento": "Culture", "era": "Exploration", "base": 6, "desc": "Majapahit Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Majapahit"},
	"Meru": {"rendimiento": "Happiness", "era": "Exploration", "base": 6, "desc": "Majapahit Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Majapahit"},
	"Bailey": {"rendimiento": "Culture", "rendimiento_secundario": "Fortification", "era": "Exploration", "base": 6, "desc": "Norman Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Norman"},
	"Motte": {"rendimiento": "Happiness", "rendimiento_secundario": "Fortification", "era": "Exploration", "base": 6, "desc": "Norman Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Norman"},
	"Naval Arsenal": {"rendimiento": "Gold", "rendimiento_secundario": "Water", "era": "Exploration", "base": 4, "desc": "Pirate Unique", "req_terreno": ["COASTAL"], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Pirate"},
	"Naval Station": {"rendimiento": "Production", "rendimiento_secundario": "Water", "era": "Exploration", "base": 5, "desc": "Pirate Unique", "req_terreno": ["COASTAL"], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Pirate"},
	"Casa de Contratación": {"rendimiento": "Gold", "era": "Exploration", "base": 6, "desc": "Spanish Unique", "req_terreno": ["COASTAL"], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Spanish"},
	"Casa Consistorial": {"rendimiento": "Culture", "era": "Exploration", "base": 6, "desc": "Spanish Unique", "req_terreno": ["COASTAL"], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Spanish"},
	"Railyard": {"rendimiento": "Production", "era": "Modern Age", "base": 9, "desc": "American Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "American"},
	"Steel Mill": {"rendimiento": "Production", "era": "Modern Age", "base": 9, "desc": "American Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "American"},
	"Manufactory": {"rendimiento": "Production", "era": "Modern Age", "base": 9, "desc": "British Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "British"},
	"Royal Exchange": {"rendimiento": "Gold", "era": "Modern Age", "base": 9, "desc": "British Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "British"},
	"Jardin à la Française": {"rendimiento": "Culture", "era": "Modern Age", "base": 9, "desc": "French Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "French"},
	"Salon": {"rendimiento": "Happiness", "era": "Modern Age", "base": 9, "desc": "French Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "French"},
	"Confucian Academy": {"rendimiento": "Culture", "era": "Modern Age", "base": 9, "desc": "Joseon Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Joseon"},
	"Printing House": {"rendimiento": "Science", "era": "Modern Age", "base": 9, "desc": "Joseon Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Joseon"},
	"Jukogyo": {"rendimiento": "Production", "era": "Modern Age", "base": 9, "desc": "Meiji Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Meiji"},
	"Ginkō": {"rendimiento": "Gold", "era": "Modern Age", "base": 9, "desc": "Meiji Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Meiji"},
	"Portal de Mercaderes": {"rendimiento": "Culture", "era": "Modern Age", "base": 9, "desc": "Mexican Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Mexican"},
	"Catedral": {"rendimiento": "Happiness", "era": "Modern Age", "base": 9, "desc": "Mexican Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Mexican"},
	"Cami": {"rendimiento": "Culture", "era": "Modern Age", "base": 9, "desc": "Ottoman Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Ottoman"},
	"Hammam": {"rendimiento": "Happiness", "era": "Modern Age", "base": 9, "desc": "Ottoman Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Ottoman"},
	"Ghahve Khane": {"rendimiento": "Food", "era": "Modern Age", "base": 9, "desc": "Qajar Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Qajar"},
	"Takyeh": {"rendimiento": "Happiness", "era": "Modern Age", "base": 9, "desc": "Qajar Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Qajar"},
	"Shiguan": {"rendimiento": "Science", "era": "Modern Age", "base": 9, "desc": "Qing Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Qing"},
	"Qianzhuang": {"rendimiento": "Gold", "era": "Modern Age", "base": 9, "desc": "Qing Unique", "req_terreno": [], "req_rio": false, "full_tile": false, "adj_barrio": false, "tipo": "Unique", "civ": "Qing"},
	
	"Angkor Wat": {"rendimiento": "Happiness", "era": "Antiquity", "base": 3, "desc": "+1 Specialist Limit. Adj to River", "req_terreno": [], "req_rio": true, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Byrsa": {"rendimiento": "Gold", "era": "Antiquity", "base": 2, "desc": "Uncancelable routes. On Coastal", "req_terreno": ["COASTAL"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Colosseum": {"rendimiento": "Culture", "era": "Antiquity", "base": 3, "desc": "+1 Happy/Gold on Quarters. Adj District", "req_terreno": [], "req_rio": false, "full_tile": true, "is_wonder": true, "adj_barrio": true, "tipo": "Standard"},
	"Colossus": {"rendimiento": "Gold", "era": "Antiquity", "base": 3, "desc": "+3 Res Cap. Coastal adj Land", "req_terreno": ["COASTAL"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Dur-Sharrukin": {"rendimiento": "Science", "era": "Antiquity", "base": 1, "desc": "+5 Combat Strength, counts as fort.", "req_terreno": [], "req_rio": false, "full_tile": true, "is_wonder": true, "adj_barrio": true, "tipo": "Standard"},
	"Emile Bell": {"rendimiento": "Influence", "era": "Antiquity", "base": 2, "desc": "Ginseng Agreement. Rough Terrain", "req_terreno": ["ROUGH"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Gate of All Nations": {"rendimiento": "Happiness", "era": "Antiquity", "base": 2, "desc": "+1 War Support. Adj District", "req_terreno": [], "req_rio": false, "full_tile": true, "is_wonder": true, "adj_barrio": true, "tipo": "Standard"},
	"Great Library": {"rendimiento": "Science", "era": "Antiquity", "base": 4, "desc": "+1 Sci in Sci Buildings. Adj District", "req_terreno": [], "req_rio": false, "full_tile": true, "is_wonder": true, "adj_barrio": true, "tipo": "Standard"},
	"Great Lighthouse": {"rendimiento": "Gold", "era": "Antiquity", "base": 3, "desc": "+15 Naval route range. On Coastal", "req_terreno": ["COASTAL"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Great Stele": {"rendimiento": "Production", "era": "Antiquity", "base": 2, "desc": "+200 Gold when built. Flat Terrain", "req_terreno": ["FLAT"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Ha'amonga 'a Maui": {"rendimiento": "Culture", "era": "Antiquity", "base": 2, "desc": "+1 Culture/Food on Boats. Adj Coastal", "req_terreno": ["COASTAL"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Hanging Gardens": {"rendimiento": "Food", "era": "Antiquity", "base": 0, "desc": "+1 Food Farms, +10% Growth. Adj River", "req_terreno": [], "req_rio": true, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Hoo-do Hall": {"rendimiento": "Culture", "era": "Antiquity", "base": 0, "desc": "+1 Prod/Cult/Happy on Breathtaking", "req_terreno": ["FLAT"], "req_rio": true, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Mausoleum at Halicarnassus": {"rendimiento": "Production", "era": "Antiquity", "base": 3, "desc": "Revive 1st Cavalry. Flat adj Coastal", "req_terreno": ["FLAT"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Mausoleum of Theodoric": {"rendimiento": "Production", "era": "Antiquity", "base": 3, "desc": "+100% Land unit HP. Adj Coastal", "req_terreno": ["COASTAL"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Mireuksa": {"rendimiento": "Happiness", "era": "Antiquity", "base": 2, "desc": "+2 Cult/+1 Prod on happy districts.", "req_terreno": [], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Monks Mound": {"rendimiento": "Food", "era": "Antiquity", "base": 4, "desc": "+4 Res Cap. Adj River", "req_terreno": [], "req_rio": true, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Mundo Perdido": {"rendimiento": "Science", "era": "Antiquity", "base": 1, "desc": "+1 Sci/+1 Happy on Tropical", "req_terreno": ["TROPICAL"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Nalanda": {"rendimiento": "Science", "era": "Antiquity", "base": 3, "desc": "Grants 3 Innovation. On Plains", "req_terreno": ["PLAINS"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Oracle": {"rendimiento": "Culture", "era": "Antiquity", "base": 2, "desc": "+20 Cult per Event. Rough Terrain", "req_terreno": ["ROUGH"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Petra": {"rendimiento": "Gold", "era": "Antiquity", "base": 2, "desc": "+1 Prod/Gold in Desert. On Desert", "req_terreno": ["DESERT"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Pyramid Of The Sun": {"rendimiento": "Culture", "era": "Antiquity", "base": 3, "desc": "+2 Culture per Quarter. Flat adj District", "req_terreno": ["FLAT"], "req_rio": false, "full_tile": true, "is_wonder": true, "adj_barrio": true, "tipo": "Standard"},
	"Pyramids": {"rendimiento": "Gold", "era": "Antiquity", "base": 1, "desc": "+1 Gold/Prod on rivers. Adj Nav River", "req_terreno": ["DESERT", "PLAINS", "GRASSLAND", "TROPICAL"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Sanchi Stupa": {"rendimiento": "Happiness", "era": "Antiquity", "base": 3, "desc": "+1 Culture per 5 extra Happy. On Plains", "req_terreno": ["PLAINS"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Terracotta Army": {"rendimiento": "Production", "era": "Antiquity", "base": 2, "desc": "Free Commander. +25% Exp. On Grassland", "req_terreno": ["GRASSLAND"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Weiyang Palace": {"rendimiento": "Influence", "era": "Antiquity", "base": 3, "desc": "+1 Tradition Slot. On Grassland", "req_terreno": ["GRASSLAND"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Borobudur": {"rendimiento": "Happiness", "era": "Exploration", "base": 3, "desc": "+3 Food/+1 Happy on Quarters. Adj Coastal", "req_terreno": ["COASTAL"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Brihadeeswarar Temple": {"rendimiento": "Influence", "era": "Exploration", "base": 3, "desc": "Bldgs gain +1 Happy per River.", "req_terreno": [], "req_rio": true, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Buseoksa": {"rendimiento": "Influence", "era": "Exploration", "base": 0, "desc": "Bonuses to Unique Improvements.", "req_terreno": ["TROPICAL", "GRASSLAND"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"El Escorial": {"rendimiento": "Happiness", "era": "Exploration", "base": 3, "desc": "+1 Settlement Limit. Rough Terrain", "req_terreno": ["ROUGH"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Erdene Zuu": {"rendimiento": "Culture", "era": "Exploration", "base": 2, "desc": "Cavalry grants Culture. Flat Terrain", "req_terreno": ["FLAT"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Forbidden City": {"rendimiento": "Culture", "era": "Exploration", "base": 4, "desc": "+1 Cult/Gold on Fortifications.", "req_terreno": [], "req_rio": false, "full_tile": true, "is_wonder": true, "adj_barrio": true, "tipo": "Standard"},
	"Grand Bazaar": {"rendimiento": "Gold", "era": "Exploration", "base": 2, "desc": "+2 Resource Slots. Adj District", "req_terreno": [], "req_rio": false, "full_tile": true, "is_wonder": true, "adj_barrio": true, "tipo": "Standard"},
	"Hale o Keawe": {"rendimiento": "Culture", "era": "Exploration", "base": 2, "desc": "+1 Culture on Water bldgs. Adj Coastal", "req_terreno": ["COASTAL"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Havana Harbor": {"rendimiento": "Gold", "era": "Exploration", "base": 3, "desc": "Generates Treasure Convoys. On Coastal", "req_terreno": ["COASTAL"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Himeji Castle": {"rendimiento": "Culture", "era": "Exploration", "base": 4, "desc": "+5 Combat in Districts. Rough Terrain", "req_terreno": ["ROUGH"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"House of Wisdom": {"rendimiento": "Science", "era": "Exploration", "base": 3, "desc": "+2 Sci on Great Works. Adj District", "req_terreno": [], "req_rio": false, "full_tile": true, "is_wonder": true, "adj_barrio": true, "tipo": "Standard"},
	"Machu Pikchu": {"rendimiento": "Gold", "era": "Exploration", "base": 4, "desc": "Bldgs gain Cult/Gold from Mountain.", "req_terreno": ["MOUNTAINOUS"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Nan Madol": {"rendimiento": "Culture", "era": "Exploration", "base": 3, "desc": "+3 Cult/Prod/Happy on Palace. On Coastal", "req_terreno": ["COASTAL"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Notre Dame": {"rendimiento": "Happiness", "era": "Exploration", "base": 4, "desc": "Instantly starts Celebration.", "req_terreno": [], "req_rio": true, "full_tile": true, "is_wonder": true, "adj_barrio": true, "tipo": "Standard"},
	"Reykjaholt": {"rendimiento": "Culture", "era": "Exploration", "base": 3, "desc": "+25% Military Prod per Work. On Tundra", "req_terreno": ["TUNDRA"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Rila Monastery": {"rendimiento": "Culture", "era": "Exploration", "base": 4, "desc": "Grants Relic when building Wonder", "req_terreno": [], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Serpent Mound": {"rendimiento": "Influence", "era": "Exploration", "base": 4, "desc": "+3 Sci/+2 Prod on Unique Imps. Grassland", "req_terreno": ["GRASSLAND"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Shwedagon Zedi Daw": {"rendimiento": "Science", "era": "Exploration", "base": 4, "desc": "+1 Sci on Rural tiles. Adj Lake", "req_terreno": ["LAKE"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Thành Huế": {"rendimiento": "Culture", "era": "Exploration", "base": 4, "desc": "+1 Specialist Limit. Adj Walls", "req_terreno": [], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Tomb of Askia": {"rendimiento": "Gold", "era": "Exploration", "base": 2, "desc": "+2 Gold/Prod per Assigned Resource.", "req_terreno": ["DESERT"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Wat Xieng Thong": {"rendimiento": "Culture", "era": "Exploration", "base": 2, "desc": "Gain Gold on getting Great Work. Adj River", "req_terreno": [], "req_rio": true, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"White Tower": {"rendimiento": "Happiness", "era": "Exploration", "base": 4, "desc": "+4 Happy per Tradition. Adj Town Hall", "req_terreno": [], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Battersea Power Station": {"rendimiento": "Production", "era": "Modern Age", "base": 4, "desc": "Extra Naval Unit. Adj Coastal", "req_terreno": ["COASTAL"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Boudhanath": {"rendimiento": "Influence", "era": "Modern Age", "base": 6, "desc": "+20 Global Relation. Adj Mountain", "req_terreno": ["GRASSLAND", "TROPICAL"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Brandenburg Gate": {"rendimiento": "Production", "era": "Modern Age", "base": 6, "desc": "+1 Settlement Limit. Adj District", "req_terreno": [], "req_rio": false, "full_tile": true, "is_wonder": true, "adj_barrio": true, "tipo": "Standard"},
	"Chengde Mountain Resort": {"rendimiento": "Gold", "era": "Modern Age", "base": 6, "desc": "+5% Culture per Trade Route.", "req_terreno": [], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Dogo Onsen": {"rendimiento": "Happiness", "era": "Modern Age", "base": 4, "desc": "Gain Pop on Celebration. Adj Coastal", "req_terreno": ["COASTAL"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Doi Suthep": {"rendimiento": "Influence", "era": "Modern Age", "base": 4, "desc": "+5 Cult/Gold per City-State.", "req_terreno": ["ROUGH"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Eiffel Tower": {"rendimiento": "Culture", "era": "Modern Age", "base": 5, "desc": "+4 Cult/+2 Tur in Quarters. Adj District", "req_terreno": [], "req_rio": false, "full_tile": true, "is_wonder": true, "adj_barrio": true, "tipo": "Standard"},
	"Eram Garden": {"rendimiento": "Food", "era": "Modern Age", "base": 4, "desc": "+1 Specialist Limit. In Desert", "req_terreno": ["DESERT"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Hermitage": {"rendimiento": "Culture", "era": "Modern Age", "base": 4, "desc": "+5 Cult if Great Works. On Tundra", "req_terreno": ["TUNDRA"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Hwaseong": {"rendimiento": "Culture", "era": "Modern Age", "base": 4, "desc": "+1 Policy/Tradition Slot. Flat adj Rough", "req_terreno": ["FLAT"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Manhattan Project": {"rendimiento": "Science", "era": "Modern Age", "base": 5, "desc": "Grants Nuclear Weapon", "req_terreno": [], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Muzibu Azaala Mpanga": {"rendimiento": "Food", "era": "Modern Age", "base": 4, "desc": "Lake bonuses. Adj Lake", "req_terreno": ["LAKE"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Nirayama Reverberatory Furnace": {"rendimiento": "Production", "era": "Modern Age", "base": 5, "desc": "+4 Prod/+2 Sci on Mines. Adj Mine", "req_terreno": [], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Oxford University": {"rendimiento": "Science", "era": "Modern Age", "base": 4, "desc": "2 Free Techs. Adj District", "req_terreno": [], "req_rio": false, "full_tile": true, "is_wonder": true, "adj_barrio": true, "tipo": "Standard"},
	"Palacio de Bellas Artes": {"rendimiento": "Culture", "era": "Modern Age", "base": 5, "desc": "+3 Happy on Great Works. Adj District", "req_terreno": [], "req_rio": false, "full_tile": true, "is_wonder": true, "adj_barrio": true, "tipo": "Standard"},
	"Red Fort": {"rendimiento": "Gold", "era": "Modern Age", "base": 4, "desc": "+50 HP. Fortification. Adj District", "req_terreno": [], "req_rio": false, "full_tile": true, "is_wonder": true, "adj_barrio": true, "tipo": "Standard"},
	"Statue of Liberty": {"rendimiento": "Happiness", "era": "Modern Age", "base": 6, "desc": "Spawns 4 Migrants. On Coastal", "req_terreno": ["COASTAL"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Sultanahmet Camii": {"rendimiento": "Happiness", "era": "Modern Age", "base": 4, "desc": "+2 Cult/Gold on Wonders. Adj Wonder", "req_terreno": [], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Taj Mahal": {"rendimiento": "Gold", "era": "Modern Age", "base": 5, "desc": "+50% Celebration Duration. On Plains", "req_terreno": ["PLAINS"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"Ubudiah Mosque": {"rendimiento": "Happiness", "era": "Modern Age", "base": 4, "desc": "+50% improvement yields. Wet Feature", "req_terreno": [], "req_carac": ["WET"], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"},
	"World's Fair": {"rendimiento": "Culture", "era": "Modern Age", "base": 6, "desc": "+6 Infl, Happy, Sci. +2 Wonder Tourism.", "req_terreno": [], "req_rio": false, "full_tile": true, "is_wonder": true, "tipo": "Standard"}
}

# ------------------------------------------------------------------------------
# MEJORAS
# ------------------------------------------------------------------------------
const DATOS_MEJORAS = {
	"Quarry": {"tipo": "Production", "era": "Antiquity"},
	"Clay Pit": {"tipo": "Production", "era": "Antiquity"},
	"Expedition Base": {"tipo": "Science", "era": "Antiquity"},
	"Farm": {"tipo": "Food", "era": "Antiquity"},
	"Woodcutter": {"tipo": "Production", "era": "Antiquity"},
	"Fishing Boat": {"tipo": "Food", "era": "Antiquity"},
	"Mine": {"tipo": "Production", "era": "Antiquity"},
	"Camp": {"tipo": "Gold", "era": "Antiquity"},
	"Pasture": {"tipo": "Food", "era": "Antiquity"},
	"Plantation": {"tipo": "Gold", "era": "Antiquity"},
	
	"Baray": {"tipo": "Food", "era": "Antiquity"},
	"Great Wall": {"tipo": "Defense", "era": "Antiquity"},
	"Hawilt": {"tipo": "Culture", "era": "Antiquity"},
	"Jinja": {"tipo": "Culture", "era": "Antiquity"},
	"Pairidaeza": {"tipo": "Culture", "era": "Antiquity"},
	"Poktop": {"tipo": "Culture", "era": "Antiquity"},
	"Emporium": {"tipo": "Gold", "era": "Antiquity"},
	"Festival Grounds": {"tipo": "Culture", "era": "Antiquity"},
	"Hillfort": {"tipo": "Defense", "era": "Antiquity"},
	"Megalith": {"tipo": "Culture", "era": "Antiquity"},
	"Step Pyramid": {"tipo": "Science", "era": "Antiquity"},
	"Yakhchal": {"tipo": "Food", "era": "Antiquity"},
	
	"Caravanserai": {"tipo": "Gold", "era": "Exploration"},
	"Gama": {"tipo": "Culture", "era": "Exploration"},
	"Hidden Fortress": {"tipo": "Defense", "era": "Exploration"},
	"Loi Kalo": {"tipo": "Food", "era": "Exploration"},
	"Mawaskawe Skote": {"tipo": "Food", "era": "Exploration"},
	"Ming Great Wall": {"tipo": "Defense", "era": "Exploration"},
	"Ortoo": {"tipo": "Influence", "era": "Exploration"},
	"Tea House": {"tipo": "Culture", "era": "Exploration"},
	"Terrace Farm": {"tipo": "Food", "era": "Exploration"},
	"Water Puppet Theater": {"tipo": "Culture", "era": "Exploration"},
	"Company Post": {"tipo": "Gold", "era": "Exploration"},
	"Kasbah": {"tipo": "Culture", "era": "Exploration"},
	"Minor Embassy": {"tipo": "Influence", "era": "Exploration"},
	"Monastery": {"tipo": "Science", "era": "Exploration"},
	"Saqiya": {"tipo": "Food", "era": "Exploration"},
	"Stone Head": {"tipo": "Culture", "era": "Exploration"},
	
	"Oil Rig": {"tipo": "Production", "era": "Modern Age"},
	"Bang": {"tipo": "Production", "era": "Modern Age"},
	"Highland Power Station": {"tipo": "Production", "era": "Modern Age"},
	"Kabakas Lake": {"tipo": "Food", "era": "Modern Age"},
	"Obshchina": {"tipo": "Food", "era": "Modern Age"},
	"Staatseisenbahn": {"tipo": "Production", "era": "Modern Age"},
	"Stepwell": {"tipo": "Food", "era": "Modern Age"},
	"Abattoir": {"tipo": "Food", "era": "Modern Age"},
	"Circus Fair": {"tipo": "Happiness", "era": "Modern Age"},
	"Entrepot": {"tipo": "Gold", "era": "Modern Age"},
	"Institute": {"tipo": "Science", "era": "Modern Age"},
	"Open-Air Museum": {"tipo": "Culture", "era": "Modern Age"},
	"Shore Battery": {"tipo": "Defense", "era": "Modern Age"}
}

# ------------------------------------------------------------------------------
# MARAVILLAS NATURALES
# ------------------------------------------------------------------------------
const MARAVILLAS_NATURALES = {
	"Bermuda Triangle": {"terreno": ["OCEAN"], "bioma": ["MARINE"], "casillas": 3, "yields": {"Science": 2, "Culture": 2}},
	"Grand Canyon": {"terreno": ["ROUGH"], "bioma": ["DESERT"], "casillas": 4, "yields": {"Culture": 2, "Happiness": 4}},
	"Great Barrier Reef": {"terreno": ["COASTAL"], "bioma": ["MARINE"], "casillas": 4, "yields": {"Food": 2, "Happiness": 2, "Science": 2}},
	"Great Blue Hole": {"terreno": ["COASTAL"], "bioma": ["MARINE"], "casillas": 1, "yields": {"Science": 2, "Happiness": 4}},
	"Gullfoss": {"terreno": ["FLAT", "ROUGH"], "bioma": ["TUNDRA"], "casillas": 1, "yields": {"Food": 6}},
	"Hoerikwaggo": {"terreno": ["MOUNTAINOUS"], "bioma": ["GRASSLAND"], "casillas": 4, "yields": {"Culture": 2, "Food": 4, "Happiness": 2}},
	"Iguazú Falls": {"terreno": ["FLAT"], "bioma": ["TROPICAL"], "casillas": 1, "yields": {"Happiness": 2, "Food": 4}},
	"Machapuchare": {"terreno": ["MOUNTAINOUS"], "bioma": ["TROPICAL"], "casillas": 3, "yields": {"Production": 4, "Culture": 2}},
	"Mapu 'a Vaea Blowholes": {"terreno": ["COASTAL"], "bioma": ["MARINE"], "casillas": 2, "yields": {"Production": 2, "Happiness": 4}},
	"Mount Everest": {"terreno": ["MOUNTAINOUS"], "bioma": ["DESERT", "PLAINS", "GRASSLAND", "TUNDRA", "TROPICAL"], "casillas": 4, "yields": {"Culture": 2, "Happiness": 2, "Influence": 2}},
	"Mount Fuji": {"terreno": ["MOUNTAINOUS"], "bioma": ["DESERT", "PLAINS", "GRASSLAND", "TUNDRA", "TROPICAL"], "casillas": 3, "yields": {"Gold": 2, "Culture": 2, "Happiness": 2}},
	"Mount Kilimanjaro": {"terreno": ["MOUNTAINOUS"], "bioma": ["DESERT", "PLAINS", "GRASSLAND", "TUNDRA", "TROPICAL"], "casillas": 3, "yields": {"Production": 2, "Happiness": 4}},
	"Nachi Falls": {"terreno": ["MOUNTAINOUS"], "bioma": ["TROPICAL"], "casillas": 4, "yields": {"Culture": 6}},
	"Redwood Forest": {"terreno": ["FLAT", "ROUGH"], "bioma": ["GRASSLAND"], "casillas": 3, "yields": {"Food": 2, "Happiness": 2, "Production": 2}},
	"Seongsan Ilchulbong": {"terreno": ["COASTAL"], "bioma": ["MARINE"], "casillas": 2, "yields": {"Happiness": 6}},
	"Thera": {"terreno": ["COASTAL"], "bioma": ["MARINE"], "casillas": 4, "yields": {"Happiness": 2, "Culture": 4}},
	"Torres del Paine": {"terreno": ["MOUNTAINOUS"], "bioma": ["TUNDRA"], "casillas": 3, "yields": {"Food": 2, "Happiness": 4}},
	"Uluru": {"terreno": ["ROUGH"], "bioma": ["DESERT"], "casillas": 1, "yields": {"Happiness": 6}},
	"Valley of Flowers": {"terreno": ["FLAT"], "bioma": ["PLAINS"], "casillas": 2, "yields": {"Food": 2, "Culture": 2, "Happiness": 2}},
	"Vihren": {"terreno": ["MOUNTAINOUS"], "bioma": ["PLAINS"], "casillas": 3, "yields": {"Food": 4, "Production": 2}},
	"Vinicunca": {"terreno": ["MOUNTAINOUS"], "bioma": ["DESERT"], "casillas": 4, "yields": {"Production": 2, "Science": 2, "Happiness": 2}},
	"Zhangjiajie": {"terreno": ["MOUNTAINOUS"], "bioma": ["TROPICAL"], "casillas": 2, "yields": {"Happiness": 2, "Production": 4}}
}

# ------------------------------------------------------------------------------
# LIDERES
# ------------------------------------------------------------------------------
const LIDERES = [
	"Ada Lovelace", "Alexander", "Amina", "Ashoka World Renouncer", "Augustus",
	"Benjamin Franklin", "Catherine the Great", "Charlemagne", "Confucius",
	"Edward Teach", "Elizabeth", "Friedrich Oblique", "Genghis Khan",
	"George Washington", "Gilgamesh", "Harriet Tubman", "Hatshepsut",
	"Himiko Queen of Wa", "Ibn Battuta", "Isabella", "Jose Rizal",
	"Lafayette", "Lakshmibai", "Machiavelli", "Napoleon Emperor",
	"Pachacuti", "Sayyida al Hurra", "Simon Bolivar", "Tecumseh",
	"Toyotomi Hideyoshi", "Trung Trac", "Xerxes King of Kings",
	"Yi Sun sin", "Ashoka World Conqueror", "Friedrich Baroque",
	"Himiko High Shaman", "Napoleon Revolutionary", "Xerxes the Achaemenid"
]

const DATOS_LIDERES = {
	"Alexander": {"bonos": ["wonder_prod_cult_boost"]},
	"Amina": {"bonos": ["gold_per_resource"]},
	"Ashoka World Renouncer": {"bonos": ["happy_building_improvement_adj"]},
	"Augustus": {"bonos": ["prod_in_capital_per_town"]},
	"Benjamin Franklin": {"bonos": ["science_on_prod_science_bldgs"]},
	"Catherine the Great": {"bonos": ["tundra_culture_to_science"]},
	"Charlemagne": {"bonos": ["military_science_wall_adj"]},
	"Hatshepsut": {"bonos": ["culture_per_unique_resource", "prod_river_city"]},
	"Isabella": {"bonos": ["natural_wonder_boost"]},
	"Lafayette": {"bonos": ["culture_happiness_in_settlements"]},
	"Pachacuti": {"bonos": ["building_mountain_adj", "prod_from_food"]},
	"Trung Trac": {"bonos": ["tropical_science_boost"]},
	"Xerxes King of Kings": {"bonos": ["gold_boost_settlements"]},
	"Himiko High Shaman": {"bonos": ["happiness_on_dip_bldgs", "culture_science_modifier"]},
	"Xerxes the Achaemenid": {"bonos": ["yields_on_uniques"]}
}

# ------------------------------------------------------------------------------
# ESPECIALISTAS (mecánica Civ VII)
# ------------------------------------------------------------------------------
# Cada celda urbana puede alojar especialistas que potencian la adyacencia de
# sus edificios. Main.gd guarda por celda:
#   especialistas_asignados (int, empieza en 0)
#   limite_especialistas    (int, 0 en los pueblos y en las celdas sin edificios
#                            reales; 1 por edificio real y +1 de distrito; ni
#                            murallas ni maravillas aportan cupo)
const ESPECIALISTAS_ALIMENTO_MANTENIMIENTO := -2
const ESPECIALISTAS_FELICIDAD_BASE := 0
const ESPECIALISTAS_BONO_ADYACENCIA := 0.5

# Reglas de colocación (Civ VII): un especialista solo puede situarse en una
# celda URBANA del propio asentamiento (un edificio externo no cuenta) que ya
# tenga AL MENOS UN edificio —el Palace y el Town Hall cuentan como edificio—,
# y únicamente en Ciudades y Capitales. En los pueblos ("Town") no puede haber
# especialistas. Solo ReglasJuego.limite_especialistas_celda() las interpreta.
const ESPECIALISTAS_TIPOS_ASENTAMIENTO := ["Capital", "City"]

# LETARGO DE ESPECIALISTAS (mecánica Civ VII): un especialista dormido no genera
# rendimiento, ni adyacencia, ni recibe bonos de políticas; su mantenimiento pasa
# a ser exactamente -1 Alimento y -1 Felicidad por especialista (sustituye al
# coste normal de -2 Alimento y a los costes de políticas). Condiciones y
# reactivación automática: ReglasJuego.especialistas_en_letargo_celda().
const ESPECIALISTAS_LETARGO_ALIMENTO := -1
const ESPECIALISTAS_LETARGO_FELICIDAD := -1

# Ningún edificio en particular desbloquea especialistas ni les aporta cupo
# "propio": la regla es por CONTEO en la celda (1 cupo por edificio real, sin
# murallas ni maravillas; +1 de distrito). La interpreta y aplica únicamente
# ReglasJuego.limite_especialistas_celda().

# ------------------------------------------------------------------------------
# SEPARACIÓN DE PANELES: UI DE LA CELDA vs PANEL DE CONSTRUCCIÓN
# ------------------------------------------------------------------------------
# Nombres de nodo de la UI que deben ser ÚNICOS de su panel (los usa Main.gd):
# la fila de especialistas se pinta SOLO en el panel de información de la celda,
# justo debajo de su caja de rendimientos. El panel de construcción la retira si
# alguna vez apareciera ahí (blindaje en GestorConstruccion y
# ReglasJuego.es_construible): los especialistas NO son elementos construibles.
const NODO_CAJA_RENDIMIENTOS_CELDA := "CajaRendimientosCelda"
const NODO_FILA_ESPECIALISTAS := "FilaEspecialistas"

# Pseudo-elementos de CELDA que NUNCA son construibles. Se comparan en
# minúsculas (sin distinguir mayúsculas) desde ReglasJuego.es_construible(), que
# es el filtro que usan el panel de construcción y el aconsejador de
# rendimientos antes de pintar o recomendar cada elemento.
const ELEMENTOS_NO_CONSTRUIBLES := ["especialista", "especialistas", "specialist", "specialists"]

# Edificios de cultura y de ciencia (Drama and Poetry / Literature).
# Se usa "tipo" cuando existe; como respaldo se listan nombres por rendimiento.
const EDIFICIOS_CULTURA := [
	"Hawilt", "Jinja", "Pairidaeza", "Poktop", "Festival Grounds", "Megalith",
	"Odeon", "Mastaba", "Monument", "Temple", "Cathedral", "Amphitheater",
	"Arena", "Theater", "Tea House", "Gama", "Kasbah", "Water Puppet Theater",
	"Stone Head", "Museum", "Open-Air Museum", "Opera House",
]
const EDIFICIOS_CIENCIA := [
	"Step Pyramid", "Royal Library", "Library", "Academy", "Observatory",
	"University", "Schoolhouse", "Laboratory", "Institute", "Monastery",
]

# ------------------------------------------------------------------------------
# MEMENTOS: DATOS Y LÍMITES DE SELECCIÓN
# ------------------------------------------------------------------------------
# Único origen de verdad de los mementos (antes en DatosMementos.gd). Cada
# memento es un diccionario con:
#   - descripcion : efecto del memento (texto del diseño original)
#   - era         : "Antiquity" / "Exploration" / "Modern Age" (o "Todas"): la
#                   Era a la que pertenece. El modal SOLO muestra los mementos
#                   de la Era actual del jugador.
# El jugador activa como máximo MEMENTOS_MAXIMO_POR_ERA mementos por Era y son
# sustituibles. Las reglas de selección viven en Main.gd -> GestorMementos.
const MEMENTOS_MAXIMO_POR_ERA := 2

const DATOS_MEMENTOS := {
	"The Iliad": {"descripcion": "+1 cultura y +1 produccion por Era en Maravillas en Ciudades distintas a tu capital.", "era": "Antiquity"},
	"Silk Uttariya": {"descripcion": "+2 produccion por era en ciudades con felicidad positiva.", "era": "Antiquity"},
	"Chakra": {"descripcion": "+1 comida en la capital por cada 5 de felicidad.", "era": "Antiquity"},
	"Breastplate": {"descripcion": "+2 comida por era en pueblos.", "era": "Exploration"},
	"clipeus virtutis": {"descripcion": "+1 prod en capital por cada pueblo creado.", "era": "Antiquity"},
	"Great Imperial Crown": {"descripcion": "+2 science por era por cada pueblo en el que su ayuntamiento esta sobre bioma tundra", "era": "Modern Age"},
	"altar set": {"descripcion": "+1 culture en la celda urbana donde hay especialistas por cada especialista", "era": "Antiquity"},
	"the analects": {"descripcion": "+1 science en la celda urbana donde hay especialistas por cada especialista", "era": "Antiquity"},
	"flute": {"descripcion": "+1 culture por era en cada military building", "era": "Antiquity"},
	"walking stick": {"descripcion": "+1 science pro era en cada military building", "era": "Modern Age"},
	"constitution": {"descripcion": "+1 influence en cada ciudad por cada tradición activa", "era": "Modern Age"},
	"bastille key": {"descripcion": "+1 food y +1 happiness en cada ciudad por cada tradición activa", "era": "Modern Age"},
	"false beard": {"descripcion": "+2 culture en wonders (maravillas construibles)", "era": "Antiquity"},
	"uraeus": {"descripcion": "+10 culture por era en cada ciudad que tenga al menos 1 maravilla construible", "era": "Antiquity"},
	"kusanagi_no_tsurugi": {"descripcion": "+3 culture por era on happiness builiding and -1 science por era en happiness building", "era": "Exploration"},
	"golden seal stone": {"descripcion": "+1 influence por era en science building", "era": "Antiquity"},
	"queens jewelry": {"descripcion": "+2 gold por era en cada maravilla natural", "era": "Modern Age"},
	"padrón real": {"descripcion": "+2 happiness en cada maravilla natural", "era": "Exploration"},
	"letter to adrienne": {"descripcion": "+2 happiness por era por cada política social activa", "era": "Modern Age"},
	"tricolor_cockade": {"descripcion": "+2 culture y +2 happiness por era en la capital por cada tradición activa", "era": "Modern Age"},
	"baadals reins": {"descripcion": "+1 influence por cada improvement pasture", "era": "Exploration"},
	"topayauri": {"descripcion": "+1 food por era en barrios adyacentes a montañas", "era": "Exploration"},
	"mascapaycha": {"descripcion": "+1 gold en especialistas, +1 gold adicional en especialistas en celdas adyacentes a montañas", "era": "Exploration"},
	"davalos medal": {"descripcion": "+1 happiness por era en cada military building", "era": "Exploration"},
	"kabuto": {"descripcion": "+3 influence por era", "era": "Exploration"},
	"golden sceptre": {"descripcion": "+3 gold por era por cada asentamiento que conquistas", "era": "Modern Age"},
	"incense censer": {"descripcion": "+2 culture por era por cada ruta de comercio activa", "era": "Exploration"},
	"chalcedony seal": {"descripcion": "+1 culture y +1 gold por cada edificio único y mejora única", "era": "Antiquity"},
}

# Lista ordenada de eras en las que se puede seleccionar (pestañas del modal).
const MEMENTOS_ERAS_SELECCION := ["Antiquity", "Exploration", "Modern Age"]

# ------------------------------------------------------------------------------
# POLÍTICAS Y TRADICIONES: DATOS Y LÍMITES DE SELECCIÓN
# ------------------------------------------------------------------------------
# Único origen de verdad de las políticas y tradiciones (antes en
# DatosPoliticas.gd). Estructura anidada por Era -> Tipo -> lista:
#   DATOS_POLITICAS[era][tipo] = [ {"nombre": ..., "requisito": ..., "efecto": ...}, ... ]
#     Eras  : "Antiquity", "Exploration", "Modern Age"
#     Tipos : "Social", "Crisis", "Ideology", "Tradiciones"
# Las políticas de Ideología llevan además el campo "ideologia" ("Democracy",
# "Fascism", "Communism"). "Crisis" queda como lista vacía preparada para el
# listado completo siguiendo el mismo patrón.
# LÍMITES DE SELECCIÓN POR ERA (valor por DEFECTO; los botones "+" del modal los
# amplían durante la partida en main.tope_politicas / main.tope_tradiciones):
#   * MAXIMO_POLITICAS_POR_ERA   : contador TOTAL de políticas; INCLUYE las
#     tradiciones activas (total = políticas + tradiciones).
#   * MAXIMO_TRADICIONES_POR_ERA : contador EXCLUSIVO de tradiciones.
# Las reglas de selección y de tradiciones heredadas viven en Main.gd ->
# GestorPoliticas.
const MAXIMO_POLITICAS_POR_ERA := 5
const MAXIMO_TRADICIONES_POR_ERA := 3

const DATOS_POLITICAS := {
	"Antiquity": {
		"Social": [
			{"nombre": "Charismatic Leader", "requisito": "Chiefdom", "efecto": "+2 Culture on the Palace"},
			{"nombre": "Castes", "requisito": "Citizenship", "efecto": "+2 Food in Settlements"},
			{"nombre": "City Guard", "requisito": "Public Life", "efecto": "+3 Combat Strength for Fortified Districts"},
			{"nombre": "Clan Networks", "requisito": "Mysticism II", "efecto": "+20% Growth Rate in Towns with a Growing Focus"},
			{"nombre": "Coinage", "requisito": "Skilled Trades", "efecto": "+1 Gold for each imported Resource, +1 Movement for Merchants"},
			{"nombre": "Commodities", "requisito": "Commerce", "efecto": "+1 Resource cap in Cities"},
			{"nombre": "Conscription", "requisito": "Organized Military", "efecto": "-1 Gold maintenance for Units"},
			{"nombre": "Drama and Poetry", "requisito": "Citizenship", "efecto": "+2 Culture on Culture Buildings, +20% Production towards Culture Buildings"},
			{"nombre": "Drills", "requisito": "Tactics", "efecto": "+30% Production towards training Infantry and Ranged Units"},
			{"nombre": "Ethics", "requisito": "Code of Laws II", "efecto": "+1 Culture from Specialists, +1 Happiness maintenance for Specialists"},
			{"nombre": "Honor", "requisito": "Discipline II", "efecto": "+3 Combat Strength against Independent Powers"},
			{"nombre": "Hospitality", "requisito": "Citizenship II", "efecto": "+3 Culture for every City-State you are suzerain of"},
			{"nombre": "Literature", "requisito": "Literacy", "efecto": "+2 Science on Science Buildings, +20% Production towards Science Buildings"},
			{"nombre": "Medicine", "requisito": "Commerce", "efecto": "Units Heal +5 HP"},
			{"nombre": "Oratory", "requisito": "Code of Laws", "efecto": "+2 Influence per turn"},
			{"nombre": "Priesthood", "requisito": "Mysticism", "efecto": "+2 Gold in all Settlements"},
			{"nombre": "Rites and Rituals", "requisito": "Entertainment", "efecto": "+2 Happiness in all Settlements"},
			{"nombre": "Scholars", "requisito": "Philosophy", "efecto": "+1 Science from Specialists, +1 Happiness maintenance for Specialists"},
			{"nombre": "Survey", "requisito": "Discipline", "efecto": "+1 Scout Movement and Sight"},
			{"nombre": "Tool Making", "requisito": "Chiefdom", "efecto": "+1 Production and +1 Science on the Palace"}
		],
		"Crisis": [],
		"Ideology": [],
		"Tradiciones": [
			{"nombre": "Oral Tradition", "requisito": "", "efecto": "+1 Culture per turn in Cities"},
			{"nombre": "Ancestor Worship", "requisito": "", "efecto": "+2 Happiness in all Settlements"},
			{"nombre": "Sacred Kingship", "requisito": "", "efecto": "+1 Production on the Palace"},
			{"nombre": "Heroic Legends", "requisito": "", "efecto": "+2 Combat Strength against Independent Powers"},
			{"nombre": "Clan Feuds", "requisito": "", "efecto": "+1 Gold in all Towns"},
			{"nombre": "Trial by Combat", "requisito": "", "efecto": "+2 Combat Strength for fortified Units"}
		]
	},
	"Exploration": {
		"Social": [
			{"nombre": "Castes", "requisito": "", "efecto": "+2 Food in Settlements"},
			{"nombre": "Conscription", "requisito": "", "efecto": "-1 Gold maintenance for Units"},
			{"nombre": "Oratory", "requisito": "", "efecto": "+2 Influence per turn"},
			{"nombre": "Priesthood", "requisito": "", "efecto": "+2 Gold in all Settlements"},
			{"nombre": "Rites and Rituals", "requisito": "", "efecto": "+2 Happiness in all Settlements"},
			{"nombre": "Survey", "requisito": "", "efecto": "+1 Scout Movement and Sight"},
			{"nombre": "Bourgeoisie", "requisito": "Social Class II", "efecto": "+4 Culture and +4 Gold in homeland Cities"},
			{"nombre": "Charters", "requisito": "Colonialism", "efecto": "+2 Gold from Specialists, +1 Happiness maintenance for Specialists"},
			{"nombre": "Chivalry", "requisito": "Social Class", "efecto": "+30% Production towards training Cavalry Units"},
			{"nombre": "Colonial Surplus", "requisito": "Colonialism", "efecto": "+2 Production from Specialists, +1 Food maintenance for Specialists"},
			{"nombre": "Commune", "requisito": "Piety", "efecto": "+20% Production towards overbuilding, +3 Combat Strength for Fortified Districts"},
			{"nombre": "Commissioned Officers", "requisito": "Imperialism II", "efecto": "+30% Commander experience, +1 Movement for fleets and armies"},
			{"nombre": "Constitution", "requisito": "Bureaucracy", "efecto": "+25% Food and +25% Happiness towards maintaining Specialists"},
			{"nombre": "De Facto", "requisito": "Sovereignty II", "efecto": "+3 Combat Strength for all Units in distant lands, Units Heal +5 HP"},
			{"nombre": "De Jure", "requisito": "Sovereignty II", "efecto": "+3 Combat Strength for all Units in homelands"},
			{"nombre": "Divine Right", "requisito": "Sovereignty", "efecto": "+10 Happiness and +4 Influence on the Palace"},
			{"nombre": "Enlightenment", "requisito": "Social Class", "efecto": "+2 Science from Specialists, +1 Happiness maintenance for Specialists"},
			{"nombre": "Evangelism", "requisito": "Theology", "efecto": "+1 Civilian Movement, +1 Missionary charge"},
			{"nombre": "Heqin", "requisito": "Diplomatic Service", "efecto": "+5 Culture per Alliance"},
			{"nombre": "Indenture", "requisito": "Imperialism", "efecto": "+2 Food from Specialists, +1 Happiness maintenance for Specialists"},
			{"nombre": "Levies", "requisito": "Authority II", "efecto": "+25% Gold towards purchasing Military Units, -1 Gold maintenance for Units"},
			{"nombre": "Maritime Law", "requisito": "Economics", "efecto": "+30% Production towards training Naval Units"},
			{"nombre": "Metropole", "requisito": "Imperialism II", "efecto": "+1 Resource Capacity in homeland Cities, +10 Trade Range"},
			{"nombre": "Patronage", "requisito": "Society", "efecto": "+2 Culture from Specialists, +1 Happiness maintenance for Specialists"},
			{"nombre": "Rationalism", "requisito": "Reformation", "efecto": "+15% Gold and +15% Science in your own Cities that are converted to your own Religion"},
			{"nombre": "Regulars", "requisito": "Sovereignty", "efecto": "+30% Production towards training Infantry and Ranged Units"},
			{"nombre": "Religious Orders", "requisito": "Reformation", "efecto": "+15% Culture and +15% Happiness in your own Cities that are converted to your own Religion"},
			{"nombre": "Renaissance", "requisito": "Inspiration", "efecto": "+10% Production towards constructing Wonders, +2 Culture on displayed Great Works"},
			{"nombre": "Tariffs", "requisito": "Imperialism", "efecto": "+50% Trade income, but -3 Happiness in Cities"},
			{"nombre": "Trade Winds", "requisito": "Mercantilism", "efecto": "+1 Gold and +1 Happiness for every imported Resource, +1 Movement on Merchants"},
			{"nombre": "Uposatha", "requisito": "Society", "efecto": "+2 Happiness from Specialists, +1 Food maintenance for Specialists"},
			{"nombre": "Vassalage", "requisito": "Authority", "efecto": "+3 Culture and +3 Gold for every City-State you are suzerain of"},
			{"nombre": "Yeomanry", "requisito": "Social Class II", "efecto": "+4 Food and +4 Production in distant land Towns"}
		],
		"Crisis": [],
		"Ideology": [],
		"Tradiciones": [
			{"nombre": "Seafaring Lore", "requisito": "", "efecto": "+1 Movement for Naval Units"},
			{"nombre": "Merchant Guilds", "requisito": "", "efecto": "+1 Gold for each active Trade Route"},
			{"nombre": "Courtly Etiquette", "requisito": "", "efecto": "+2 Influence per turn"},
			{"nombre": "Colonial Charters", "requisito": "", "efecto": "+2 Production in distant land Settlements"},
			{"nombre": "Cartographers", "requisito": "", "efecto": "+1 Sight and +1 Movement for Scouts"},
			{"nombre": "Treasure Myths", "requisito": "", "efecto": "+2 Gold from Treasure resources"}
		]
	},
	"Modern Age": {
		"Social": [
			{"nombre": "Bourgeoisie", "requisito": "", "efecto": "+4 Culture and +4 Gold in homeland Cities"},
			{"nombre": "Commune", "requisito": "", "efecto": "+20% Production towards overbuilding, +3 Combat Strength for Fortified Districts"},
			{"nombre": "Constitution", "requisito": "", "efecto": "+25% Food and +25% Happiness towards maintaining Specialists"},
			{"nombre": "Divine Right", "requisito": "", "efecto": "+10 Happiness and +4 Influence on the Palace"},
			{"nombre": "Levies", "requisito": "", "efecto": "+25% Gold towards purchasing Military Units, -1 Gold maintenance for Units"},
			{"nombre": "Metropole", "requisito": "", "efecto": "+1 Resource Capacity in homeland Cities, +10 Trade Range"},
			{"nombre": "Yeomanry", "requisito": "", "efecto": "+4 Food and +4 Production in distant land Towns"},
			{"nombre": "Ambassadors", "requisito": "Globalism", "efecto": "+6 Influence per turn"},
			{"nombre": "Civil Engineering", "requisito": "Modernity", "efecto": "+30% Production towards overbuilding"},
			{"nombre": "Cultural Imperialism", "requisito": "Hegemony", "efecto": "+6 Culture and +6 Gold for every City-State you are suzerain of"},
			{"nombre": "Demagogy", "requisito": "Nationalism", "efecto": "Gain Happiness on the Palace equal to your Cultural Attribute"},
			{"nombre": "Draft", "requisito": "Militarism II", "efecto": "+25% Gold towards purchasing Units and -1 Gold maintenance for Units"},
			{"nombre": "Free Speech", "requisito": "Political Theory", "efecto": "+50% Food and +50% Happiness towards maintaining Specialists"},
			{"nombre": "Humanism", "requisito": "Social Question", "efecto": "+3 Culture from Specialists, +1 Food and Happiness maintenance for Specialists"},
			{"nombre": "Laissez-Faire", "requisito": "Capitalism", "efecto": "+2 Gold and +1 Happiness for each imported Resource"},
			{"nombre": "Land Heritage", "requisito": "Natural History", "efecto": "+2 Happiness on Mountains, +6 Culture on Natural Wonders"},
			{"nombre": "Living Standards", "requisito": "Modernity", "efecto": "+25% Gold and +25% Happiness towards maintaining Buildings"},
			{"nombre": "Materiel", "requisito": "Militarism", "efecto": "Units Heal +10 HP, +1 Movement for fleets and armies"},
			{"nombre": "Monopolies", "requisito": "Capitalism II", "efecto": "+5 Gold and +1 Resource Capacity in every Settlement with a Factory"},
			{"nombre": "People's Army", "requisito": "Nationalism II", "efecto": "+25% Production towards training Land Units, but +1 Gold maintenance for those Units"},
			{"nombre": "Preservation Societies", "requisito": "Globalism II", "efecto": "+3 Science from displayed Great Works"},
			{"nombre": "Projection of Force", "requisito": "Militarism II", "efecto": "+50% Production towards training Naval Units, but +1 Gold maintenance for those Units"},
			{"nombre": "Social Science", "requisito": "Social Question", "efecto": "+3 Science from Specialists, +1 Food and Happiness maintenance for Specialists"},
			{"nombre": "Sphere of Influence", "requisito": "Hegemony II", "efecto": "Gain Culture equal to your Diplomatic Attribute for every Alliance you have"},
			{"nombre": "Trenchworks", "requisito": "Militarism", "efecto": "+3 Combat Strength for fortified Units and Districts"}
		],
		"Crisis": [],
		"Ideology": [
			{"nombre": "Avant Garde", "requisito": "Progressivism", "efecto": "+2 Culture and Happiness from displayed Great Works", "ideologia": "Democracy"},
			{"nombre": "Fireside Chats", "requisito": "Democracy", "efecto": "+4 Happiness from Specialists, -3 Gold in Towns", "ideologia": "Democracy"},
			{"nombre": "Free Press", "requisito": "Liberalism", "efecto": "Towns get Culture equal to your Cultural Attribute, -5 Science in Cities", "ideologia": "Democracy"},
			{"nombre": "New Deal", "requisito": "Progressivism", "efecto": "+30% Production towards Wonders", "ideologia": "Democracy"},
			{"nombre": "Suffrage", "requisito": "Democracy", "efecto": "+3 Culture from Specialists, -3 Production in Towns", "ideologia": "Democracy"},
			{"nombre": "Their Finest Hour", "requisito": "Progressivism", "efecto": "+25% Production towards Air Units, +5 Combat Strength for Air Units in your territory", "ideologia": "Democracy"},
			{"nombre": "Welfare State", "requisito": "Liberalism", "efecto": "Towns get Happiness equal to your Diplomatic Attribute, -5 Production in Cities", "ideologia": "Democracy"},
			{"nombre": "Assembly Line", "requisito": "Fascism", "efecto": "+2 Production from Specialists, -2 Food in Towns", "ideologia": "Fascism"},
			{"nombre": "Dirigisme", "requisito": "Fascism", "efecto": "+4 Gold from Specialists, -3 Happiness in Towns", "ideologia": "Fascism"},
			{"nombre": "Military-Industrial Complex", "requisito": "Absolutism", "efecto": "+50% Production towards training all Military Units, but +1 Gold maintenance for all Units", "ideologia": "Fascism"},
			{"nombre": "Propaganda", "requisito": "Radicalism", "efecto": "Towns gain Gold equal to your Economic Attribute, -5 Culture in Cities", "ideologia": "Fascism"},
			{"nombre": "Scorched Earth", "requisito": "Absolutism", "efecto": "+3 Combat Strength for all Units when attacking, +25% yields and HP from pillaging", "ideologia": "Fascism"},
			{"nombre": "Collectivization", "requisito": "Centralism", "efecto": "Towns gain Food equal to your Expansionist Attribute, -5 Happiness in Cities", "ideologia": "Communism"},
			{"nombre": "Defense of the Motherland", "requisito": "Socialism", "efecto": "+3 Combat Strength for all Land Units in your own territory", "ideologia": "Communism"},
			{"nombre": "Naukograd", "requisito": "Centralism", "efecto": "Towns gain Science equal to your Scientific Attribute, -5 Culture in Cities", "ideologia": "Communism"},
			{"nombre": "Police State", "requisito": "Socialism", "efecto": "+8 Happiness in Cities while at War", "ideologia": "Communism"},
			{"nombre": "Productive Forces Determinism", "requisito": "Communism", "efecto": "+3 Science from Specialists, -3 Gold in Towns", "ideologia": "Communism"},
			{"nombre": "Proletariat", "requisito": "Communism", "efecto": "+4 Food from Specialists, -3 Happiness in Towns", "ideologia": "Communism"},
			{"nombre": "Public Works", "requisito": "Socialism", "efecto": "+30% Production towards completing Projects", "ideologia": "Communism"}
		],
		"Tradiciones": [
			{"nombre": "National Identity", "requisito": "", "efecto": "+2 Culture in Cities"},
			{"nombre": "Industrial Spirit", "requisito": "", "efecto": "+2 Production in Cities"},
			{"nombre": "Rule of Law", "requisito": "", "efecto": "+2 Happiness in Cities"},
			{"nombre": "Mass Education", "requisito": "", "efecto": "+2 Science in Cities"},
			{"nombre": "Civic Duty", "requisito": "", "efecto": "+1 Influence per turn"},
			{"nombre": "Scientific Method", "requisito": "", "efecto": "+2 Science from Specialists"}
		]
	},
}

# ------------------------------------------------------------------------------
# UTILIDADES DE COLOR
# ------------------------------------------------------------------------------
static func obtener_color_rendimiento(rendimiento: String) -> Color:
	match rendimiento:
		"Food": return Color(0.2, 0.75, 0.2)
		"Science": return Color(0.2, 0.5, 0.9)
		"Culture": return Color(0.6, 0.2, 0.8)
		"Happiness": return Color(0.9, 0.5, 0.1)
		"Gold": return Color(0.85, 0.75, 0.1)
		"Production": return Color(0.85, 0.2, 0.2)
		"Warehouse": return Color(0.5, 0.5, 0.5)
		"Influence": return Color(0.7, 0.4, 0.9)
		_: return Color(0.35, 0.35, 0.35)

static func obtener_color_texto(rendimiento: String) -> Color:
	match rendimiento:
		"Food", "Gold", "Happiness": return Color.BLACK
		_: return Color.WHITE
