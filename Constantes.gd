extends Node
class_name Constantes

# ==============================================================================
# CONSTANTES DEL JUEGO - ÚNICO ORIGEN DE VERDAD DE LOS DATOS ESTÁTICOS
# ------------------------------------------------------------------------------
# Contiene TODOS los datos del juego: eras, civilizaciones, biomas, terrenos,
# características, recursos, edificios, mejoras, maravillas naturales y líderes.
# NO contiene lógica de juego ni estado de partida: es consumido de forma estática
# por Main.gd (por ejemplo: Constantes.DATOS_EDIFICIOS, Constantes.RECURSOS_POR_ERA).
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
const RENDIMIENTOS_RECURSOS = {
	"Camels": "Gold", "Clay": "Production", "Cotton": "Gold", "Cowrie": "Happiness", 
	"Crabs": "Food", "Dates": "Food", "Dyes": "Culture", "Fish": "Food", 
	"Flax": "Science", "Gold": "Gold", "Gypsum": "Science", "Hardwood": "Culture", 
	"Hides": "Production", "Horses": "Production", "Incense": "Culture", "Iron": "Production", 
	"Ivory": "Culture", "Jade": "Culture", "Kaolin": "Production", "Limestone": "Production", 
	"Llamas": "Happiness", "Mangoes": "Culture", "Marble": "Culture", "Pearls": "Gold", 
	"Rice": "Food", "Rubies": "Gold", "Salt": "Food", "Silk": "Culture", 
	"Silver": "Gold", "Tin": "Production", "Turtles": "Culture", "Wild Game": "Food", 
	"Wine": "Happiness", "Wool": "Production",
	"Cloves": "Gold", "Cocoa": "Happiness", "Furs": "Happiness", "Niter": "Production", 
	"Pitch": "Production", "Spices": "Culture", "Sugar": "Gold", "Tea": "Culture", 
	"Truffles": "Happiness", "Whales": "Food",
	"Citrus": "Food", "Coal": "Production", "Coffee": "Gold", "Nickel": "Production", 
	"Oil": "Production", "Quinine": "Science", "Rubber": "Production", "Tobacco": "Culture"
}

const RECURSOS_POR_ERA = {
	"Antiquity": {
		"Camels": ["DESERT", "PLAINS"], "Clay": ["DESERT", "PLAINS", "GRASSLAND", "TUNDRA", "TROPICAL"], "Cotton": ["DESERT", "PLAINS", "GRASSLAND"], 
		"Cowrie": ["MARINE"], "Crabs": ["MARINE"], "Dates": ["DESERT"], "Dyes": ["MARINE"], "Fish": ["MARINE"],
		"Flax": ["PLAINS", "GRASSLAND"], "Gold": ["PLAINS", "GRASSLAND", "TROPICAL"], "Gypsum": ["PLAINS", "TUNDRA"], 
		"Hardwood": ["TUNDRA", "TROPICAL"], "Hides": ["TUNDRA"], "Horses": ["PLAINS", "GRASSLAND"], 
		"Incense": ["DESERT", "PLAINS"], "Iron": ["DESERT", "PLAINS", "GRASSLAND", "TUNDRA", "TROPICAL"], "Ivory": ["DESERT", "PLAINS", "GRASSLAND", "TROPICAL"], 
		"Jade": ["PLAINS", "TUNDRA", "TROPICAL"], "Kaolin": ["PLAINS", "GRASSLAND", "TROPICAL"], 
		"Lapis Lazuli": ["DESERT", "PLAINS"], "Limestone": ["DESERT", "PLAINS", "GRASSLAND"], "Llamas": ["TROPICAL"], 
		"Mangoes": ["TROPICAL"], "Marble": ["PLAINS", "GRASSLAND"], "Pearls": ["MARINE"], "Rice": ["PLAINS", "GRASSLAND", "TROPICAL"], 
		"Rubies": ["DESERT", "PLAINS", "TROPICAL"], "Salt": ["DESERT", "PLAINS", "TUNDRA"], "Silk": ["PLAINS", "GRASSLAND", "TROPICAL"], 
		"Silver": ["DESERT", "TUNDRA"], "Tin": ["PLAINS", "TROPICAL"], "Turtles": ["MARINE"], 
		"Wild Game": ["GRASSLAND", "TUNDRA", "TROPICAL"], "Wine": ["PLAINS", "GRASSLAND"], "Wool": ["DESERT", "PLAINS", "GRASSLAND", "TUNDRA", "TROPICAL"]
	},
	"Exploration": {
		"Camels": ["DESERT", "PLAINS"], "Clay": ["DESERT", "PLAINS", "GRASSLAND", "TUNDRA", "TROPICAL"], "Cloves": ["TROPICAL", "MARINE"], "Cocoa": ["TROPICAL"],
		"Cotton": ["DESERT", "PLAINS", "GRASSLAND"], "Cowrie": ["MARINE"], "Crabs": ["MARINE"], "Dates": ["DESERT"],
		"Dyes": ["MARINE"], "Fish": ["MARINE"], "Flax": ["PLAINS", "GRASSLAND"], "Furs": ["PLAINS", "TUNDRA"],
		"Gold": ["PLAINS", "GRASSLAND", "TROPICAL"], "Gypsum": ["PLAINS", "TUNDRA"], "Hardwood": ["TUNDRA", "TROPICAL"],
		"Horses": ["PLAINS", "GRASSLAND"], "Incense": ["DESERT", "PLAINS"], "Iron": ["DESERT", "PLAINS", "GRASSLAND", "TUNDRA", "TROPICAL"],
		"Ivory": ["DESERT", "PLAINS", "GRASSLAND", "TROPICAL"], "Jade": ["PLAINS", "TUNDRA", "TROPICAL"], 
		"Kaolin": ["PLAINS", "GRASSLAND", "TROPICAL"], "Limestone": ["DESERT", "PLAINS", "GRASSLAND"], 
		"Llamas": ["TROPICAL"], "Mangoes": ["TROPICAL"], "Marble": ["PLAINS", "GRASSLAND"], "Niter": ["DESERT", "PLAINS", "GRASSLAND", "TUNDRA", "TROPICAL"],
		"Pearls": ["MARINE"], "Pitch": ["PLAINS", "GRASSLAND", "TROPICAL"], "Rice": ["PLAINS", "GRASSLAND", "TROPICAL"], 
		"Rubies": ["DESERT", "PLAINS", "TROPICAL"], "Silk": ["PLAINS", "GRASSLAND", "TROPICAL"], "Silver": ["DESERT", "TUNDRA"], 
		"Spices": ["GRASSLAND", "TROPICAL"], "Sugar": ["PLAINS", "GRASSLAND", "TROPICAL"], "Tea": ["PLAINS", "GRASSLAND"], 
		"Tin": ["PLAINS", "TROPICAL"], "Truffles": ["PLAINS", "GRASSLAND", "TUNDRA"], "Turtles": ["MARINE"], 
		"Whales": ["MARINE"], "Wild Game": ["GRASSLAND", "TUNDRA", "TROPICAL"], "Wine": ["PLAINS", "GRASSLAND"]
	},
	"Modern Age": {
		"Citrus": ["PLAINS", "GRASSLAND"], "Coal": ["DESERT", "PLAINS", "GRASSLAND", "TROPICAL"], 
		"Cocoa": ["TROPICAL"], "Coffee": ["PLAINS", "TROPICAL"], "Cotton": ["DESERT", "PLAINS", "GRASSLAND"], 
		"Cowrie": ["MARINE"], "Crabs": ["MARINE"], "Fish": ["MARINE"], "Furs": ["PLAINS", "TUNDRA"],
		"Gold": ["PLAINS", "GRASSLAND", "TROPICAL"], "Hardwood": ["TUNDRA", "TROPICAL"], "Horses": ["PLAINS", "GRASSLAND"], 
		"Ivory": ["DESERT", "PLAINS", "GRASSLAND", "TROPICAL"], "Kaolin": ["PLAINS", "GRASSLAND", "TROPICAL"], 
		"Limestone": ["DESERT", "PLAINS", "GRASSLAND"], "Llamas": ["TROPICAL"], "Marble": ["PLAINS", "GRASSLAND"],
		"Nickel": ["DESERT", "PLAINS", "GRASSLAND", "TUNDRA", "TROPICAL"], "Niter": ["DESERT", "PLAINS", "GRASSLAND", "TUNDRA", "TROPICAL"], "Oil": ["DESERT", "GRASSLAND", "TUNDRA"], "Pearls": ["MARINE"], 
		"Pitch": ["PLAINS", "GRASSLAND", "TROPICAL"], "Quinine": ["PLAINS", "GRASSLAND"], "Rice": ["PLAINS", "GRASSLAND", "TROPICAL"], 
		"Rubber": ["GRASSLAND", "TROPICAL"], "Silk": ["PLAINS", "GRASSLAND", "TROPICAL"], "Silver": ["DESERT", "TUNDRA"], 
		"Spices": ["GRASSLAND", "TROPICAL"], "Sugar": ["PLAINS", "GRASSLAND", "TROPICAL"], "Tea": ["PLAINS", "GRASSLAND"], 
		"Tin": ["PLAINS", "TROPICAL"], "Tobacco": ["PLAINS", "GRASSLAND"], "Truffles": ["PLAINS", "GRASSLAND", "TUNDRA"], 
		"Whales": ["MARINE"], "Wine": ["PLAINS", "GRASSLAND"]
	}
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
