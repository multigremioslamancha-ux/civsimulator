extends SceneTree

# El motor de maravillas vive integrado como clase anidada dentro de Main.gd.
const Motor := preload("res://Main.gd").MaravillasNaturales

var fallos := 0

func _initialize() -> void:
	_probar_limites()
	_probar_activacion()
	_probar_todos_los_bonos()
	_probar_agua_dulce_y_caballeria()
	_probar_solapamiento()
	_probar_integracion()

	if fallos == 0:
		print("OK: todas las pruebas de maravillas naturales han pasado")
		quit(0)
	else:
		printerr("ERROR: %d aserciones fallidas" % fallos)
		quit(1)

func _ok(cond: bool, mensaje: String) -> void:
	if not cond:
		fallos += 1
		printerr("FALLO: " + mensaje)

func _celda(bioma := "DESERT", terreno := "FLAT", caracteristica := "NONE", recurso := "", mejora := "", edificios := []) -> Dictionary:
	return {
		"bioma": bioma,
		"terreno": terreno,
		"caracteristica": caracteristica,
		"recurso": recurso,
		"mejora_tipo": mejora,
		"edificios": edificios
	}

func _maravilla(nombre: String, bioma := "DESERT", terreno := "FLAT", mejora := "") -> Dictionary:
	return _celda(bioma, terreno, "NATURAL_WONDER", nombre, mejora, [])

func _bono(grid: Dictionary, coord: Vector2i) -> Dictionary:
	return Motor.rendimientos_especiales_para_celda(grid, coord)

func _conteo(grid: Dictionary) -> Dictionary:
	var c := {}
	for d in grid.values():
		var n := Motor.nombre_maravilla(d)
		if n != "":
			c[n] = int(c.get(n, 0)) + 1
	return c

func _probar_limites() -> void:
	_ok(Constantes.MARAVILLAS_NATURALES.size() == 22, "deben definirse 22 maravillas")
	var esperados := {
		"Bermuda Triangle": 3, "Grand Canyon": 4, "Great Barrier Reef": 4,
		"Great Blue Hole": 1, "Gullfoss": 1, "Hoerikwaggo": 4,
		"Iguazú Falls": 1, "Machapuchare": 3, "Mapu 'a Vaea Blowholes": 2,
		"Mount Everest": 4, "Mount Fuji": 3, "Mount Kilimanjaro": 3,
		"Nachi Falls": 4, "Redwood Forest": 3, "Seongsan Ilchulbong": 2,
		"Thera": 4, "Torres del Paine": 3, "Uluru": 1,
		"Valley of Flowers": 2, "Vihren": 3, "Vinicunca": 4,
		"Zhangjiajie": 2
	}
	for nombre in esperados.keys():
		_ok(Motor.limite(nombre) == esperados[nombre], "límite incorrecto: " + nombre)
		_ok(Motor.limite(nombre) == int(Constantes.MARAVILLAS_NATURALES[nombre]["casillas"]), "Constantes sin casillas: " + nombre)

	var grid := {}
	for i in range(4):
		_ok(Motor.puede_colocar(grid, "Grand Canyon"), "debería permitir la celda %d antes de colocarla" % (i + 1))
		grid[Vector2i(i, 0)] = _maravilla("Grand Canyon")
	_ok(not Motor.puede_colocar(grid, "Grand Canyon"), "no debería permitir la quinta celda")

func _probar_activacion() -> void:
	var grid := {
		Vector2i(0, 0): _maravilla("Bermuda Triangle", "MARINE", "OCEAN", ""),
		Vector2i(1, 0): _celda("MARINE", "COASTAL")
	}
	_ok(Motor.celdas_activadas(grid).is_empty(), "sin Expedition Base no activa")
	_ok(_bono(grid, Vector2i(1, 0))["Science"] == 0, "sin activación no hay bono")

	var base := Motor.rendimientos_base_celda(grid[Vector2i(0, 0)])
	_ok(base["Science"] == 2 and base["Culture"] == 2, "los rendimientos base siguen intactos")

	grid[Vector2i(0, 0)]["mejora_tipo"] = "Expedition Base"
	_ok(Motor.celdas_activadas(grid).size() == 1, "con Expedition Base activa")
	_ok(_bono(grid, Vector2i(1, 0))["Science"] == 1, "bono activo")

func _probar_todos_los_bonos() -> void:
	# 1 Bermuda: +1 ciencia en cada costero.
	_ok(_bono({
		Vector2i(0, 0): _maravilla("Bermuda Triangle", "MARINE", "OCEAN", "Expedition Base"),
		Vector2i(1, 0): _celda("MARINE", "COASTAL")
	}, Vector2i(1, 0))["Science"] == 1, "Bermuda Triangle")

	# 2 Grand Canyon: +1 ciencia en cada llano.
	_ok(_bono({
		Vector2i(0, 0): _maravilla("Grand Canyon", "DESERT", "ROUGH", "Expedition Base"),
		Vector2i(1, 0): _celda("DESERT", "FLAT")
	}, Vector2i(1, 0))["Science"] == 1, "Grand Canyon")

	# 3 Great Barrier Reef: +2 ciencia en lagos/costas/océanos adyacentes.
	var reef := {
		Vector2i(0, 0): _maravilla("Great Barrier Reef", "MARINE", "COASTAL", "Expedition Base"),
		Vector2i(1, 0): _celda("MARINE", "LAKE"),
		Vector2i(0, 1): _celda("DESERT", "FLAT")
	}
	_ok(_bono(reef, Vector2i(1, 0))["Science"] == 2, "Great Barrier Reef adyacente")
	_ok(_bono(reef, Vector2i(0, 1))["Science"] == 0, "Great Barrier Reef no adyacente")

	# 4 Great Blue Hole: +2 cultura en celdas rurales marinas adyacentes.
	_ok(_bono({
		Vector2i(0, 0): _maravilla("Great Blue Hole", "MARINE", "COASTAL", "Expedition Base"),
		Vector2i(1, 0): _celda("MARINE", "OCEAN")
	}, Vector2i(1, 0))["Culture"] == 2, "Great Blue Hole rural")
	_ok(_bono({
		Vector2i(0, 0): _maravilla("Great Blue Hole", "MARINE", "COASTAL", "Expedition Base"),
		Vector2i(1, 0): _celda("MARINE", "OCEAN", "NONE", "", "", ["Granary"])
	}, Vector2i(1, 0))["Culture"] == 0, "Great Blue Hole urbana")

	# 5 Gullfoss: +1 cultura y +1 producción a rurales adyacentes.
	var gullfoss := _bono({
		Vector2i(0, 0): _maravilla("Gullfoss", "TUNDRA", "FLAT", "Expedition Base"),
		Vector2i(1, 0): _celda("TUNDRA", "FLAT")
	}, Vector2i(1, 0))
	_ok(gullfoss["Culture"] == 1 and gullfoss["Production"] == 1, "Gullfoss")

	# 6 Hoerikwaggo: +2 felicidad en distritos adyacentes.
	_ok(_bono({
		Vector2i(0, 0): _maravilla("Hoerikwaggo", "GRASSLAND", "MOUNTAINOUS", "Expedition Base"),
		Vector2i(1, 0): _celda("GRASSLAND", "FLAT", "NONE", "", "", ["Granary", "Library"])
	}, Vector2i(1, 0))["Happiness"] == 2, "Hoerikwaggo")

	# 7 Iguazú: +2 producción en distritos adyacentes.
	_ok(_bono({
		Vector2i(0, 0): _maravilla("Iguazú Falls", "TROPICAL", "FLAT", "Expedition Base"),
		Vector2i(1, 0): _celda("TROPICAL", "FLAT", "NONE", "", "", ["Granary", "Library"])
	}, Vector2i(1, 0))["Production"] == 2, "Iguazú Falls")

	# 8 Machapuchare: +1 felicidad en Rough y Mountain.
	var macha := {
		Vector2i(0, 0): _maravilla("Machapuchare", "TROPICAL", "MOUNTAINOUS", "Expedition Base"),
		Vector2i(1, 0): _celda("TROPICAL", "ROUGH"),
		Vector2i(0, 1): _celda("TROPICAL", "MOUNTAINOUS"),
		Vector2i(-1, 1): _celda("TROPICAL", "FLAT")
	}
	_ok(_bono(macha, Vector2i(1, 0))["Happiness"] == 1, "Machapuchare rough")
	_ok(_bono(macha, Vector2i(0, 1))["Happiness"] == 1, "Machapuchare mountain")
	_ok(_bono(macha, Vector2i(-1, 1))["Happiness"] == 0, "Machapuchare excluye flat")

	# 9 Mapu a Vaea: +2 cultura en todas las costeras.
	_ok(_bono({
		Vector2i(0, 0): _maravilla("Mapu 'a Vaea Blowholes", "MARINE", "COASTAL", "Expedition Base"),
		Vector2i(2, 0): _celda("MARINE", "COASTAL")
	}, Vector2i(2, 0))["Culture"] == 2, "Mapu 'a Vaea Blowholes")

	# 10 Redwood: +1 ciencia y +1 cultura en vegetated.
	var redwood := _bono({
		Vector2i(0, 0): _maravilla("Redwood Forest", "GRASSLAND", "FLAT", "Expedition Base"),
		Vector2i(1, 0): _celda("GRASSLAND", "FLAT", "VEGETATED")
	}, Vector2i(1, 0))
	_ok(redwood["Science"] == 1 and redwood["Culture"] == 1, "Redwood Forest")

	# 11 Seongsan se valida después como multiplicador de caballería.

	# 12 Torres del Paine: +1 comida y +1 producción en Tundra.
	var torres := _bono({
		Vector2i(0, 0): _maravilla("Torres del Paine", "TUNDRA", "MOUNTAINOUS", "Expedition Base"),
		Vector2i(1, 0): _celda("TUNDRA", "FLAT")
	}, Vector2i(1, 0))
	_ok(torres["Food"] == 1 and torres["Production"] == 1, "Torres del Paine")

	# 13 Uluru: +2 cultura en desierto.
	_ok(_bono({
		Vector2i(0, 0): _maravilla("Uluru", "DESERT", "ROUGH", "Expedition Base"),
		Vector2i(1, 0): _celda("DESERT", "FLAT")
	}, Vector2i(1, 0))["Culture"] == 2, "Uluru")

	# 14 Vinicunca: +2 cultura por cada rural adyacente.
	var vinicunca := {
		Vector2i(0, 0): _maravilla("Vinicunca", "DESERT", "MOUNTAINOUS", "Expedition Base"),
		Vector2i(1, 0): _celda("DESERT", "FLAT"),
		Vector2i(0, 1): _celda("DESERT", "FLAT")
	}
	_ok(_bono(vinicunca, Vector2i(0, 0))["Culture"] == 4, "Vinicunca dos rurales")
	vinicunca[Vector2i(0, 1)]["edificios"] = ["Granary"]
	_ok(_bono(vinicunca, Vector2i(0, 0))["Culture"] == 2, "Vinicunca excluye urbana")

	# 15 Zhangjiajie: +2 cultura en rough.
	_ok(_bono({
		Vector2i(0, 0): _maravilla("Zhangjiajie", "TROPICAL", "MOUNTAINOUS", "Expedition Base"),
		Vector2i(1, 0): _celda("TROPICAL", "ROUGH")
	}, Vector2i(1, 0))["Culture"] == 2, "Zhangjiajie")

	_probar_maravillas_solo_base()

func _probar_maravillas_solo_base() -> void:
	_ok(Motor.SOLO_RENDIMIENTOS_BASE.size() == 7, "deben ser 7 maravillas solo base")
	for nombre in Motor.SOLO_RENDIMIENTOS_BASE:
		var datos: Dictionary = Constantes.MARAVILLAS_NATURALES[nombre]
		var grid := {
			Vector2i(0, 0): _maravilla(nombre, datos["bioma"][0], datos["terreno"][0], "Expedition Base"),
			Vector2i(1, 0): _celda(datos["bioma"][0], "FLAT", "VEGETATED")
		}
		var suma := 0
		for valor in Motor.rendimientos_totales(grid).values():
			suma += int(valor)
		var base_esperada := 0
		for valor in datos["yields"].values():
			base_esperada += int(valor)
		_ok(suma == base_esperada, "solo base, sin efectos especiales: " + nombre)

func _probar_agua_dulce_y_caballeria() -> void:
	var grid := {Vector2i(0, 0): _maravilla("Gullfoss", "TUNDRA", "FLAT")}
	_ok(not Motor.otorga_agua_dulce(grid), "Gullfoss inactiva no da agua")
	grid[Vector2i(0, 0)]["mejora_tipo"] = "Expedition Base"
	_ok(Motor.otorga_agua_dulce(grid), "Gullfoss activa da agua")

	grid = {Vector2i(0, 0): _maravilla("Iguazú Falls", "TROPICAL", "FLAT", "Expedition Base")}
	_ok(Motor.otorga_agua_dulce(grid), "Iguazú activa da agua")

	grid = {Vector2i(0, 0): _maravilla("Seongsan Ilchulbong", "MARINE", "COASTAL", "Expedition Base")}
	_ok(abs(Motor.multiplicador_produccion_caballeria(grid) - 1.2) < 0.0001, "Seongsan +20%")
	grid[Vector2i(1, 0)] = _maravilla("Seongsan Ilchulbong", "MARINE", "COASTAL", "Expedition Base")
	_ok(abs(Motor.multiplicador_produccion_caballeria(grid) - 1.4) < 0.0001, "Seongsan escala por celda")

func _probar_solapamiento() -> void:
	# Dos grids independientes que comparten coordenadas físicas: sus límites y
	# activaciones no se contaminan aunque las fronteras se solapen.
	var grid_a := {}
	var grid_b := {}
	for i in range(4):
		grid_a[Vector2i(i, 0)] = _maravilla("Grand Canyon", "DESERT", "ROUGH", "Expedition Base")
	grid_b[Vector2i(0, 0)] = _maravilla("Grand Canyon", "DESERT", "ROUGH", "Expedition Base")
	grid_b[Vector2i(1, 0)] = _celda("DESERT", "FLAT")

	_ok(Motor.contar_celdas(grid_a, "Grand Canyon") == 4, "límite propio de A")
	_ok(not Motor.puede_colocar(grid_a, "Grand Canyon"), "A al límite")
	_ok(Motor.puede_colocar(grid_b, "Grand Canyon"), "B no hereda el límite de A")
	_ok(_conteo(grid_a)["Grand Canyon"] == 4 and _conteo(grid_b)["Grand Canyon"] == 1, "conteos aislados")
	_ok(_bono(grid_b, Vector2i(1, 0))["Science"] == 1, "B calcula con su propio grid")

	# Una maravilla distinta puede ser adyacente: no existe bloqueo por exclusividad.
	grid_a[Vector2i(4, 0)] = _maravilla("Uluru", "DESERT", "ROUGH", "Expedition Base")
	_ok(Motor.nombre_maravilla(grid_a[Vector2i(3, 0)]) == "Grand Canyon", "maravillas distintas coexisten")

func _probar_integracion() -> void:
	_ok(Constantes.DATOS_MEJORAS.has("Expedition Base"), "Expedition Base definida")
	var texto_main := FileAccess.get_file_as_string("res://Main.gd")
	_ok(texto_main.length() > 0, "Main.gd legible")
	_ok(not texto_main.contains("maravilla_vecina"), "no bloquear adyacencia entre maravillas distintas")
	_ok(texto_main.contains("class MaravillasNaturales"), "Main integra el motor como clase anidada")
	_ok(not FileAccess.file_exists("res://MaravillasNaturales.gd"), "no queda archivo externo de maravillas")
	_ok(texto_main.contains("rendimientos_totales"), "Main integra rendimientos totales")
	_ok(texto_main.contains("otorga_agua_dulce"), "Main integra agua dulce")
	_ok(texto_main.contains("multiplicador_produccion_caballeria"), "Main expone el multiplicador")
	_ok(
		texto_main.contains("btn_menu_felicidad.visible = (seccion_actual != \"FELICIDAD\")"),
		"regla de visibilidad del visor"
	)
	_ok(texto_main.contains("Expedition Base"), "UI permite Expedition Base")

	var inicio := texto_main.find("func actualizar_panel_pincel")
	var fin := texto_main.find("func _crear_cabecera_panel", inicio)
	_ok(inicio >= 0 and fin > inicio, "localizar actualizar_panel_pincel")
	if inicio >= 0 and fin > inicio:
		var cuerpo := texto_main.substr(inicio, fin - inicio)
		_ok(not cuerpo.contains("favorita"), "el pincel no contiene botones de felicidad")
		_ok(not cuerpo.contains("Atractivo"), "el pincel no contiene estados de felicidad")


