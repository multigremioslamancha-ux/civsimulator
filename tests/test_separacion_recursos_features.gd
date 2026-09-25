extends SceneTree

# Separación estricta entre recursos y features: las maravillas naturales
# son features, nunca recursos. Su nombre solo vive en "recurso" como
# almacenamiento de la maravilla activa en la celda.
const Reglas := preload("res://Main.gd").ReglasJuego
const Motor := preload("res://Main.gd").MaravillasNaturales

var fallos := 0

func _initialize() -> void:
	_probar_maravilla_no_es_recurso()
	_probar_rendimiento_sin_gold_de_recurso()
	_probar_bono_adyacencia_sin_maravilla()
	_probar_ubicacion_sin_edificios_en_maravilla()

	if fallos == 0:
		print("OK: separación entre recursos y features verificada")
		quit(0)
	else:
		printerr("ERROR: %d aserciones fallidas" % fallos)
		quit(1)

func _ok(cond: bool, mensaje: String) -> void:
	if not cond:
		fallos += 1
		printerr("FALLO: " + mensaje)

func _celda(bioma := "DESERT", terreno := "FLAT", caracteristica := "NONE", recurso := "") -> Dictionary:
	return {
		"q": 0, "r": 0, "s": 0,
		"bioma": bioma,
		"terreno": terreno,
		"caracteristica": caracteristica,
		"recurso": recurso,
		"rio": false,
		"mejora_tipo": "",
		"edificios": [],
		"ajeno": false,
		"reclamada": false
	}

func _probar_maravilla_no_es_recurso() -> void:
	var celda_maravilla := _celda("DESERT", "FLAT", "NATURAL_WONDER", "Mount Everest")
	var celda_terreno_maravilla := _celda("DESERT", "NATURAL_WONDER", "NONE")

	# Ningún recurso de DATOS_RECURSOS es válido sobre una maravilla (feature).
	var ninguno := true
	for rec in Constantes.DATOS_RECURSOS:
		if Reglas.es_recurso_valido_en_celda(rec, celda_maravilla, ""):
			ninguno = false
			printerr("  recurso aceptado sobre maravilla: " + str(rec))
	_ok(ninguno, "ningún recurso es válido sobre una celda cuya feature es NATURAL_WONDER")

	# Tampoco en una celda cuyo terreno es NATURAL_WONDER.
	var ninguno_terreno := true
	for rec in Constantes.DATOS_RECURSOS:
		if Reglas.es_recurso_valido_en_celda(rec, celda_terreno_maravilla, ""):
			ninguno_terreno = false
			printerr("  recurso aceptado con terreno maravilla: " + str(rec))
	_ok(ninguno_terreno, "ningún recurso es válido en una celda con terreno NATURAL_WONDER")

	# El nombre de una maravilla nunca se interpreta como un recurso.
	var celda_normal := _celda("GRASSLAND", "FLAT", "NONE")
	_ok(not Reglas.es_recurso_valido_en_celda("Mount Everest", celda_normal, ""), "el nombre de una maravilla no es un recurso válido")

	# Cordura: sí existen recursos válidos en celdas normales.
	var celdas_prueba: Array = [
		_celda("GRASSLAND", "FLAT", "NONE"),
		_celda("PLAINS", "FLAT", "NONE"),
		_celda("DESERT", "FLAT", "NONE"),
		_celda("TUNDRA", "FLAT", "NONE"),
		_celda("TROPICAL", "FLAT", "NONE"),
		_celda("GRASSLAND", "ROUGH", "NONE"),
		_celda("MARINE", "COASTAL", "NONE"),
		_celda("MARINE", "OCEAN", "NONE"),
		_celda("GRASSLAND", "NAVIGABLE_RIVER", "NONE"),
		_celda("PLAINS", "FLAT", "FLOODPLAIN"),
		_celda("GRASSLAND", "FLAT", "VEGETATED"),
		_celda("GRASSLAND", "FLAT", "WET"),
	]
	var hay_valido := false
	for rec in Constantes.DATOS_RECURSOS:
		for celda_prueba in celdas_prueba:
			if Reglas.es_recurso_valido_en_celda(rec, celda_prueba, ""):
				hay_valido = true
				break
		if hay_valido:
			break
	_ok(hay_valido, "al menos un recurso sigue siendo válido en celdas normales")

func _probar_rendimiento_sin_gold_de_recurso() -> void:
	var base := Reglas.calcular_rendimiento_celda("GRASSLAND", "FLAT", "NONE", "", false, "")
	var con_maravilla := Reglas.calcular_rendimiento_celda("GRASSLAND", "FLAT", "NONE", "Mount Everest", false, "")
	_ok(con_maravilla.Gold == base.Gold, "una maravilla en 'recurso' no aporta el +1 Gold de recurso")
	var con_legado := Reglas.calcular_rendimiento_celda("GRASSLAND", "FLAT", "NONE", "Resource", false, "")
	_ok(con_legado.Gold == base.Gold, "el valor legado 'Resource' tampoco suma Gold")
	_ok(Constantes.MARAVILLAS_NATURALES.has("Mount Everest"), "Mount Everest está declarada en MARAVILLAS_NATURALES")

func _probar_bono_adyacencia_sin_maravilla() -> void:
	# Edificio con rendimiento Science o Production: su bono mira si las
	# celdas adyacentes tienen "recurso"; la maravilla no debe contar.
	var nombre_bono := ""
	for nombre in Constantes.DATOS_EDIFICIOS:
		var dato: Dictionary = Constantes.DATOS_EDIFICIOS[nombre]
		if dato.get("tipo", "") in ["Warehouse", "Fortification"]:
			continue
		if dato.get("is_wonder", false):
			continue
		var rend := str(dato.get("rendimiento", "Production"))
		if rend == "Science" or rend == "Production":
			nombre_bono = nombre
			break
	_ok(nombre_bono != "", "existe un edificio de tipo Science/Production para la prueba")
	if nombre_bono == "":
		return

	var rec_ej: String = Constantes.DATOS_RECURSOS.keys()[0]
	var centro := Vector2i(0, 0)
	var vecino := Vector2i(1, 0)
	var grid_vacia := {}
	grid_vacia[centro] = _celda("GRASSLAND", "FLAT", "NONE")
	grid_vacia[vecino] = _celda("GRASSLAND", "FLAT", "NONE")
	var grid_con_recurso := {}
	grid_con_recurso[centro] = _celda("GRASSLAND", "FLAT", "NONE")
	grid_con_recurso[vecino] = _celda("GRASSLAND", "FLAT", "NONE", rec_ej)
	var grid_con_maravilla := {}
	grid_con_maravilla[centro] = _celda("GRASSLAND", "FLAT", "NONE")
	grid_con_maravilla[vecino] = _celda("GRASSLAND", "FLAT", "NATURAL_WONDER", "Mount Everest")

	var b_vacia := Reglas.calcular_bono_edificio(centro, nombre_bono, "Antiquity", grid_vacia)
	var b_recurso := Reglas.calcular_bono_edificio(centro, nombre_bono, "Antiquity", grid_con_recurso)
	var b_maravilla := Reglas.calcular_bono_edificio(centro, nombre_bono, "Antiquity", grid_con_maravilla)
	_ok(b_recurso == b_vacia + 1, "un recurso adyacente sí suma el bono de adyacencia (+1)")
	_ok(b_maravilla == b_vacia, "una maravilla natural adyacente no suma el bono de recurso")

func _probar_ubicacion_sin_edificios_en_maravilla() -> void:
	var centro := Vector2i(0, 0)
	var objetivo := Vector2i(1, 0)
	var grid := {}
	grid[centro] = _celda("GRASSLAND", "FLAT", "NONE")
	grid[objetivo] = _celda("GRASSLAND", "FLAT", "NONE")
	var asentamientos: Array = []

	# Busco un edificio básico que sea válido en la celda normal.
	var edificio_ok := ""
	for nombre in Constantes.DATOS_EDIFICIOS:
		if nombre in ["Palace", "Town Hall"]:
			continue
		var dato: Dictionary = Constantes.DATOS_EDIFICIOS[nombre]
		if dato.get("is_wonder", false):
			continue
		if dato.get("tipo", "") in ["Warehouse", "Fortification", "Unique"]:
			continue
		if dato.has("civ"):
			continue
		if Reglas.es_ubicacion_valida_para_edificio(objetivo, nombre, centro, "Antiquity", "", grid, "Town", asentamientos):
			edificio_ok = nombre
			break
	_ok(edificio_ok != "", "existe un edificio básico válido en una celda normal")
	if edificio_ok == "":
		return

	# La misma celda, convertida en maravilla natural, no admite edificios.
	grid[objetivo] = _celda("GRASSLAND", "FLAT", "NATURAL_WONDER", "Mount Everest")
	_ok(not Reglas.es_ubicacion_valida_para_edificio(objetivo, edificio_ok, centro, "Antiquity", "", grid, "Town", asentamientos), "las maravillas naturales no admiten edificios")

