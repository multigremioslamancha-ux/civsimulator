extends Node

func obtener_denominacion_celda(bioma: String, terreno: String, caracteristica: String) -> String:
	if bioma == "MARINE":
		if terreno == "LAKE" and caracteristica == "AQUATIC": return "Lotus"
		if terreno == "COASTAL":
			if caracteristica == "AQUATIC": return "Reef"
			if caracteristica == "ICE": return "Ice"
		if terreno == "OCEAN":
			if caracteristica == "AQUATIC": return "Atoll"
			if caracteristica == "ICE": return "Ice"
		return bioma.capitalize() + " " + terreno.capitalize()
	
	if bioma == "TUNDRA":
		if caracteristica == "VEGETATED": return "Taiga"
		if caracteristica == "WET": return "Tundra Bog"
		if caracteristica == "FLOODPLAIN": return "Tundra Floodplain"
	elif bioma == "GRASSLAND":
		if caracteristica == "VEGETATED": return "Forest"
		if caracteristica == "WET": return "Marsh"
		if caracteristica == "FLOODPLAIN": return "Grassland Floodplain"
	elif bioma == "PLAINS":
		if caracteristica == "VEGETATED": return "Savanna Woodland"
		if caracteristica == "WET": return "Watering Hole"
		if caracteristica == "FLOODPLAIN": return "Plains Floodplain"
	elif bioma == "DESERT":
		if caracteristica == "VEGETATED": return "Sagebrush Steppe"
		if caracteristica == "WET": return "Oasis"
		if caracteristica == "FLOODPLAIN": return "Desert Floodplain"
	elif bioma == "TROPICAL":
		if caracteristica == "VEGETATED": return "Rainforest"
		if caracteristica == "WET": return "Mangrove"
		if caracteristica == "FLOODPLAIN": return "Tropical Floodplain"
		
	var result = bioma.capitalize() + " " + terreno.capitalize()
	if caracteristica != "NONE":
		result += " " + caracteristica.capitalize()
	return result

func calcular_rendimiento_celda(bioma: String, terreno: String, caracteristica: String, recurso: String, _rio: bool, _era_actual: String) -> Dictionary:
	var rendimiento = {
		"Food": 0,
		"Production": 0,
		"Gold": 0,
		"Culture": 0,
		"Science": 0,
		"Happiness": 0,
		"Influence": 0
	}
	
	var b = bioma.strip_edges().to_upper()
	var t = terreno.strip_edges().to_upper()
	var c = caracteristica.strip_edges().to_upper()
	
	match b:
		"GRASSLAND":
			rendimiento.Food += 2
		"PLAINS":
			rendimiento.Food += 1
			rendimiento.Production += 1
		"DESERT":
			rendimiento.Production += 1
		"TUNDRA":
			rendimiento.Food += 1
		"TROPICAL":
			rendimiento.Food += 2
		"MARINE":
			rendimiento.Food += 1
			rendimiento.Gold += 1

	match t:
		"ROUGH":
			rendimiento.Production += 1
		"MOUNTAINOUS":
			rendimiento.Production += 2
		"LAKE":
			rendimiento.Food += 2
		"COASTAL":
			rendimiento.Food += 1
			rendimiento.Gold += 1
		"OCEAN":
			rendimiento.Food += 1

	match c:
		"VEGETATED":
			rendimiento.Food += 1
		"WET":
			rendimiento.Food += 1
		"FLOODPLAIN":
			rendimiento.Food += 2
		"VOLCANO":
			rendimiento.Production += 1
			rendimiento.Science += 1

	if recurso != "" and recurso != "Resource":
		rendimiento.Gold += 1

	return rendimiento

func es_edificio_muralla(nombre: String) -> bool:
	return nombre in ["Ancient Walls", "Medieval Walls", "Defensive Fortifications", "Great Wall", "Hidden Fortress", "Ming Great Wall", "Citadel", "Bailey", "Motte"]

func es_edificio_obsoleto(nombre: String, coord: Vector2i, era_actual: String, city_grid: Dictionary) -> bool:
	if city_grid.has(coord) and city_grid[coord].get("edificios_dorados", []).has(nombre): return false
	if not Constantes.DATOS_EDIFICIOS.has(nombre): return false
	var d = Constantes.DATOS_EDIFICIOS[nombre]
	
	var era_edif = d.get("era", "All")
	if era_edif == "All": return false
	if Constantes.ORDEN_ERAS.get(era_edif, 0) >= Constantes.ORDEN_ERAS.get(era_actual, 0): return false
	if d.get("tipo", "") == "Warehouse": return false
	
	return true

func es_mejora_valida(coord: Vector2i, mejora_nombre: String, asent_centro: Vector2i, city_grid: Dictionary, era_actual: String = "Antiquity", civ_actual: String = "None", tipo_asentamiento: String = "Town") -> bool:
	if not city_grid.has(coord): return false
	if city_grid[coord].get("ajeno", false): return false
	if HexMath.dist_hex(coord, asent_centro) > 3: return false
	
	var datos = city_grid[coord]
	var t = datos.get("terreno", "").strip_edges().to_upper()
	
	if era_actual == "Antiquity" and t in ["MOUNTAINOUS", "MONTAÑA"]: 
		return false
		
	var b = datos.get("bioma", "").strip_edges().to_upper()
	var f = datos.get("caracteristica", "NONE").strip_edges().to_upper()
	var res = datos.get("recurso", "")
	var rio = datos.get("rio", false)

	var adyacentes_misma_mejora = 0
	var distritos_adyacentes = 0
	var celdas_coastal_adyacentes = 0
	var rio_adyacente = rio

	for vec in HexMath.VECINOS_HEX:
		var n = coord + vec
		if city_grid.has(n):
			if city_grid[n].get("mejora_tipo", "") == mejora_nombre: adyacentes_misma_mejora += 1
			var bld_count = 0
			for e in city_grid[n].edificios:
				if not es_edificio_muralla(e) and not es_edificio_obsoleto(e, n, era_actual, city_grid): bld_count += 1
			if bld_count >= 2: distritos_adyacentes += 1
			if city_grid[n].get("terreno", "").strip_edges().to_upper() in ["COASTAL", "COSTA"]: celdas_coastal_adyacentes += 1
			if city_grid[n].get("rio", false): rio_adyacente = true

	match mejora_nombre:
		"Quarry":
			if era_actual == "Modern Age": return res in ["Jade", "Kaolin", "Limestone", "Marble"]
			elif era_actual == "Exploration": return res in ["Gypsum", "Jade", "Kaolin", "Limestone", "Marble"]
			else: return res in ["Gypsum", "Jade", "Kaolin", "Marble", "Limestone"]
		"Clay Pit":
			if era_actual == "Modern Age": return f == "WET" or t in ["HUMEDO", "WET"]
			else: return f == "WET" or t in ["HUMEDO", "WET"] or res == "Clay"
		"Expedition Base":
			if era_actual == "Exploration" and civ_actual == "Incan": return f == "NATURAL_WONDER" or t in ["MOUNTAINOUS", "MONTAÑA"]
			elif era_actual == "Modern Age": return f == "NATURAL_WONDER" or t in ["MOUNTAINOUS", "MONTAÑA"]
			else: return f == "NATURAL_WONDER"
		"Farm": return t in ["FLAT", "PLANO"]
		"Woodcutter":
			if era_actual == "Antiquity": return f == "VEGETATED" or t in ["VEGETACION", "VEGETATED"] or res == "Hardwood"
			elif era_actual == "Exploration": return f == "VEGETATED" or t in ["VEGETACION", "VEGETATED"] or res in ["Cocoa", "Hardwood", "Spices"]
			else: return f == "VEGETATED" or t in ["VEGETACION", "VEGETATED"] or res in ["Cocoa", "Hardwood", "Quinine", "Rubber", "Spices"]
		"Fishing Boat":
			var val_water = (t in ["COASTAL", "COSTA", "NAVIGABLE_RIVER", "RIO_NAVEGABLE"]) and not rio
			if era_actual == "Antiquity": return val_water or res in ["Cowrie", "Crabs", "Dyes", "Fish", "Pearls", "Turtles"]
			elif era_actual == "Exploration": return val_water or res in ["Cowrie", "Crabs", "Dyes", "Fish", "Pearls", "Turtles", "Whales"]
			else: return val_water or res in ["Cowrie", "Crabs", "Fish", "Pearls", "Whales"]
		"Mine":
			if era_actual == "Antiquity": return t in ["ROUGH", "ABRUPTO"] or res in ["Gold", "Iron", "Rubies", "Salt", "Silver", "Tin"]
			elif era_actual == "Exploration": return t in ["ROUGH", "ABRUPTO"] or res in ["Gold", "Iron", "Rubies", "Silver", "Niter", "Tin"]
			else: return t in ["ROUGH", "ABRUPTO"] or res in ["Coal", "Gold", "Iron", "Niter", "Silver", "Tin"]
		"Camp":
			if era_actual == "Antiquity": return res in ["Ivory", "Camels", "Hides", "Wild Game"]
			elif era_actual == "Exploration": return res in ["Camels", "Furs", "Ivory", "Truffles", "Wild Game"]
			else: return res in ["Furs", "Ivory", "Truffles"]
		"Pasture": return res in ["Horses", "Llamas", "Wool"] if era_actual == "Antiquity" else res in ["Horses", "Llamas"]
		"Plantation":
			if era_actual == "Antiquity": return res in ["Cotton", "Dates", "Flax", "Incense", "Mangoes", "Rice", "Silk", "Wine"]
			elif era_actual == "Exploration": return res in ["Cotton", "Dates", "Flax", "Incense", "Mangoes", "Rice", "Silk", "Sugar", "Tea", "Wine"]
			else: return res in ["Citrus", "Coffee", "Cotton", "Rice", "Silk", "Sugar", "Tea", "Tobacco", "Wine"]
		"Oil Rig": return res == "Oil"
		"Baray": return t in ["FLAT", "PLANO"] and adyacentes_misma_mejora == 0
		"Great Wall", "Ming Great Wall": return adyacentes_misma_mejora <= 2
		"Hawilt", "Poktop", "Megalith": return t in ["FLAT", "PLANO"]
		"Jinja": return true
		"Pairidaeza", "Emporium", "Yakhchal", "Tea House", "Hidden Fortress", "Mawaskawe Skote", "Water Puppet Theater", "Company Post", "Stepwell", "Abattoir", "Entrepot", "Institute", "Circus Fair":
			if adyacentes_misma_mejora > 0: return false
			if mejora_nombre == "Yakhchal": return b == "DESERT"
			if mejora_nombre == "Tea House" or mejora_nombre == "Stepwell": return t in ["FLAT", "PLANO"]
			if mejora_nombre == "Hidden Fortress": return t in ["ROUGH", "ABRUPTO"]
			if mejora_nombre == "Mawaskawe Skote": return f in ["VEGETATED", "VEGETACION"]
			if mejora_nombre == "Water Puppet Theater": return b != "MARINE" and rio_adyacente
			if mejora_nombre == "Entrepot": return t in ["NAVIGABLE_RIVER", "RIO_NAVEGABLE"]
			return true
		"Festival Grounds": return t in ["FLAT", "PLANO"] and distritos_adyacentes > 0 and adyacentes_misma_mejora == 0
		"Hillfort": return t in ["ROUGH", "ABRUPTO"]
		"Step Pyramid", "Stone Head": return datos.get("favorita", 0) == 0
		"Caravanserai": return b == "DESERT" or b == "PLAINS"
		"Gama": return f in ["VEGETATED", "VEGETACION"]
		"Loi Kalo": return b == "GRASSLAND" or b == "TROPICAL"
		"Ortoo", "Terrace Farm": return t not in ["ROUGH", "ABRUPTO"] and not rio and f == "NONE"
		"Kasbah": return b == "DESERT"
		"Minor Embassy": return tipo_asentamiento == "City" or tipo_asentamiento == "Capital"
		"Monastery": return distritos_adyacentes == 0
		"Saqiya": return f == "FLOODPLAIN"
		"Bang": return t in ["NAVIGABLE_RIVER", "RIO_NAVEGABLE"]
		"Highland Power Station": return f == "NONE" or (t in ["MOUNTAINOUS", "MONTAÑA"] and civ_actual == "Nepalese")
		"Kabakas Lake", "Open-Air Museum": return t in ["FLAT", "PLANO"]
		"Obshchina": return adyacentes_misma_mejora == 0
		"Staatseisenbahn": return true
		"Shore Battery": return b != "MARINE" and celdas_coastal_adyacentes > 0
	return true

func calcular_bono_edificio(coord: Vector2i, nombre_edificio: String, _era_actual: String, city_grid: Dictionary) -> int:
	if not Constantes.DATOS_EDIFICIOS.has(nombre_edificio): return 0
	var d = Constantes.DATOS_EDIFICIOS[nombre_edificio]
	
	if d.get("tipo", "") == "Warehouse" or d.get("tipo", "") == "Fortification": return 0
	if d.get("is_wonder", false): return 0

	var rend = d.get("rendimiento", "Production")
	var bonus = 0
	
	for vec in HexMath.VECINOS_HEX:
		var n = coord + vec
		if city_grid.has(n):
			var vd = city_grid[n]
			var t = vd.get("terreno", "").strip_edges().to_upper()
			var c = vd.get("caracteristica", "NONE").strip_edges().to_upper()
			
			var is_wonder = false
			for e in vd.edificios:
				if e == "Marvel" or Constantes.DATOS_EDIFICIOS.get(e, {}).get("is_wonder", false): is_wonder = true
			if is_wonder: bonus += 1
			
			if rend == "Culture" or rend == "Happiness":
				if t in ["MOUNTAINOUS", "MONTAÑA"] or t == "NATURAL_WONDER" or c == "NATURAL_WONDER": bonus += 1
			elif rend == "Gold" or rend == "Food":
				if t in ["COASTAL", "COSTA", "NAVIGABLE_RIVER", "RIO_NAVEGABLE"]: bonus += 1
			elif rend == "Science" or rend == "Production":
				if vd.get("recurso", "") != "": bonus += 1

	var mi_celda = city_grid[coord]
	var mt = mi_celda.get("terreno", "").strip_edges().to_upper()
	var mc = mi_celda.get("caracteristica", "NONE").strip_edges().to_upper()
	
	if nombre_edificio == "K'uh Nah" and mc in ["VEGETATED", "VEGETACION"]: bonus += 2
	if nombre_edificio == "Parthenon" and mt in ["ROUGH", "ABRUPTO"]: bonus += 2
	if nombre_edificio == "Lecture Hall" and mt in ["ROUGH", "ABRUPTO"]: bonus += 1
	if nombre_edificio == "Motte" and mt in ["ROUGH", "ABRUPTO"]: bonus += 4
	
	return bonus

func es_ubicacion_valida_para_edificio(coord: Vector2i, edificio_nombre: String, asent_centro: Vector2i, era_actual: String, civ_actual: String, city_grid: Dictionary, tipo_asentamiento: String = "Town", asentamientos: Array = []) -> bool:
	if not city_grid.has(coord) or city_grid[coord].get("ajeno", false): return false
	if not Constantes.DATOS_EDIFICIOS.has(edificio_nombre): return false
	if HexMath.dist_hex(coord, asent_centro) > 3: return false
	
	var d = Constantes.DATOS_EDIFICIOS[edificio_nombre]
	var es_nueva_wonder = d.get("is_wonder", false)
	var es_nueva_muralla = es_edificio_muralla(edificio_nombre)
	
	if es_nueva_wonder and tipo_asentamiento == "Town":
		return false
		
	if es_nueva_wonder:
		for asent in asentamientos:
			for c_grid in asent.grid.values():
				if c_grid.edificios.has(edificio_nombre):
					return false

	var datos_celda = city_grid[coord]
	var t = datos_celda.get("terreno", "").strip_edges().to_upper()
	var c = datos_celda.get("caracteristica", "NONE").strip_edges().to_upper()
	var es_recurso = (datos_celda.get("recurso", "") != "")
	
	if c == "ICE" or t in ["OCEAN", "OCEANO"]: return false
	
	if d.get("tipo", "") == "Unique" and tipo_asentamiento == "Town": return false
	if d.has("civ") and d.civ != civ_actual: return false
	
	var edificios_actuales = datos_celda.get("edificios", [])
	var es_centro = edificios_actuales.has("Palace") or edificios_actuales.has("Town Hall")

	# Contabilizar qué hay en la celda
	var normales = 0
	var tiene_wonder = false
	var tiene_muralla = false

	for e in edificios_actuales:
		if es_edificio_muralla(e):
			tiene_muralla = true
		elif Constantes.DATOS_EDIFICIOS.get(e, {}).get("is_wonder", false):
			tiene_wonder = true
		elif e not in ["Palace", "Town Hall"]:
			normales += 1

	# --- VALIDACIONES SEGÚN TIPO (Muralla vs Normal/Wonder) ---
	if es_nueva_muralla:
		if tiene_muralla: return false
		
		# Solo en celdas URBANAS (1 o 2 edificios, maravilla, o el centro del asentamiento)
		var is_urban = normales > 0 or tiene_wonder or es_centro
		if not is_urban: return false

		# REGLA DE ADYACENCIA UNIVERSAL PARA MURALLAS:
		# Si no es el centro (dist > 0), debe tocar al menos a un vecino adyacente que ya tenga muralla.
		var dist = HexMath.dist_hex(coord, asent_centro)
		if dist > 0:
			var tiene_vecino_con_muralla = false
			for vec in HexMath.VECINOS_HEX:
				var n = coord + vec
				if city_grid.has(n):
					for e in city_grid[n].get("edificios", []):
						if es_edificio_muralla(e):
							tiene_vecino_con_muralla = true
							break
				if tiene_vecino_con_muralla:
					break
			if not tiene_vecino_con_muralla:
				return false
	else:
		if es_nueva_wonder:
			if tiene_wonder or normales > 0 or es_centro: return false
		else:
			# Edificios normales: 2 máximo (1 máximo si es el centro)
			var max_normales = 1 if es_centro else 2
			if tiene_wonder or normales >= max_normales: return false
			
	# Los recursos bloquean los edificios normales/wonders (pero no las murallas urbanas)
	if not es_nueva_muralla and es_recurso:
		return false
		
	# --- EXENCIONES PARA LAS MURALLAS ---
	if not es_nueva_muralla:
		if d.get("no_pair", false) and (normales > 0 or tiene_wonder): return false
		
		if d.has("max_one") and d.max_one:
			for c_datos in city_grid.values():
				if c_datos.edificios.has(edificio_nombre): return false
				
		if d.has("no_adj_same") and d.no_adj_same:
			for vec in HexMath.VECINOS_HEX:
				var n = coord + vec
				if city_grid.has(n) and city_grid[n].edificios.has(edificio_nombre): return false
			
	if era_actual == "Antiquity" and t in ["MONTAÑA", "MOUNTAINOUS"]: return false
	
	var req_terreno = d.get("req_terreno", [])
	if req_terreno.size() > 0:
		var valido = false
		for req in req_terreno:
			var req_u = req.strip_edges().to_upper()
			if req_u == "COSTA": req_u = "COASTAL"
			elif req_u == "LAGO": req_u = "LAKE"
			elif req_u == "RIO_NAVEGABLE": req_u = "NAVIGABLE_RIVER"
			elif req_u == "MONTAÑA": req_u = "MOUNTAINOUS"
			elif req_u == "PLANO": req_u = "FLAT"
			
			if req_u == "COASTAL" and t in ["COASTAL", "COSTA"]: valido = true
			elif req_u == "NAVIGABLE_RIVER" and t in ["NAVIGABLE_RIVER", "RIO_NAVEGABLE"]: valido = true
			elif req_u == "LAKE" and t in ["LAKE", "LAGO"]: valido = true
			elif t == req_u or datos_celda.bioma == req_u or c == req_u: valido = true
		if not valido: return false
	else:
		if t in ["COSTA", "COASTAL", "OCEANO", "OCEAN", "RIO_NAVEGABLE", "NAVIGABLE_RIVER"]: return false
			
	if d.get("req_rio", false) and not datos_celda.get("rio", false) and t not in ["RIO_NAVEGABLE", "NAVIGABLE_RIVER"]: return false
		
	return true
