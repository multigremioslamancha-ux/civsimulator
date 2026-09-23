extends Node2D

var panel_estadisticas: MarginContainer
var grid_estadisticas: GridContainer
var lider_actual: String = "Augustus"
var radio_hex: float = 48.0
var asentamientos: Array = []
var asentamiento_activo_idx: int = 0
var city_grid: Dictionary = {}
var celda_seleccionada: Vector2i = Vector2i(-999, -999)
var sugerencias_cache: Dictionary = {}
var cache_puentes_urbanos: Dictionary = {}

var era_actual: String = "Antiquity"
var civ_actual: String = "None"
var civ_sincretismo: String = "None"
var era_transicionada: bool = false

var partidas_guardadas: Dictionary = {}
var partida_actual_nombre: String = "Autosave"
var lbl_nombre_partida: Label

var camera: Camera2D
var lbl_info: RichTextLabel
var panel_info: Control
var seccion_actual: String = "ASENTAMIENTOS"

var btn_menu_pincel: Button
var btn_menu_asentamientos: Button
var btn_menu_maravillas: Button
var btn_modo_construccion: Button
var btn_modo_externos: Button

var panel_biomas: Control
var scroll_biomas: ScrollContainer
var grid_biomas: GridContainer
var grid_terrenos: GridContainer
var grid_carac: GridContainer
var hbox_favs: HBoxContainer
var panel_maravillas: Control
var grid_maravillas_naturales: GridContainer

var panel_construccion: VBoxContainer
var grid_recursos: GridContainer
var btn_quitar_recurso: Button
var grid_genericos: GridContainer
var lbl_header_genericos: Label
var grid_mejoras: GridContainer
var lbl_header_mejoras: Label
var grid_edificios: GridContainer
var lbl_header_edificios: Label
var grid_maravillas: GridContainer
var lbl_header_maravillas: Label
var contenedor_borrar_edificios: VBoxContainer

var panel_externos: VBoxContainer
var lbl_ext_edif: Label
var lbl_ext_mej: Label
var scroll_ext_edif: ScrollContainer
var scroll_ext_mej: ScrollContainer
var btn_del_ext: Button
var contenedor_edificios_externos: GridContainer
var contenedor_mejoras_externas: GridContainer

var panel_asentamientos_ui: Control
var contenedor_lista_asentamientos: VBoxContainer
var lbl_era_actual: Label
var lbl_civ_actual: Control
var btn_avanzar_era: Button
var btn_sincretismo: Button

var puntos_tactiles: Dictionary = {}
var distancia_pinch_inicial: float = 0.0
var ultimo_pos_raton: Vector2 = Vector2.ZERO
var arrastrando: bool = false

func _ready() -> void:
	get_window().mode = Window.MODE_MAXIMIZED
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	get_window().content_scale_size = Vector2i(1440, 900)
	
	var bg_layer = CanvasLayer.new()
	bg_layer.layer = -10
	var bg_tex = TextureRect.new()
	bg_tex.texture = load("res://assets/meier.jpg")
	bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_layer.add_child(bg_tex)
	add_child(bg_layer)
	
	var refs = GestorInterfaz.construir_interfaz_principal(self)
	btn_menu_pincel = refs.get("btn_menu_pincel")
	btn_menu_asentamientos = refs.get("btn_menu_asentamientos")
	btn_menu_maravillas = refs.get("btn_menu_maravillas")
	btn_modo_construccion = refs.get("btn_modo_construccion")
	btn_modo_externos = refs.get("btn_modo_externos")
	panel_biomas = refs.get("panel_biomas")
	scroll_biomas = refs.get("scroll_biomas")
	grid_biomas = refs.get("grid_biomas")
	grid_terrenos = refs.get("grid_terrenos")
	grid_carac = refs.get("grid_carac")
	hbox_favs = refs.get("hbox_favs")
	panel_maravillas = refs.get("panel_maravillas")
	grid_maravillas_naturales = refs.get("grid_maravillas_naturales")
	panel_construccion = refs.get("panel_construccion")
	grid_recursos = refs.get("grid_recursos")
	btn_quitar_recurso = refs.get("btn_quitar_recurso")
	grid_genericos = refs.get("grid_genericos")
	lbl_header_genericos = refs.get("lbl_header_genericos")
	grid_mejoras = refs.get("grid_mejoras")
	lbl_header_mejoras = refs.get("lbl_header_mejoras")
	grid_edificios = refs.get("grid_edificios")
	lbl_header_edificios = refs.get("lbl_header_edificios")
	grid_maravillas = refs.get("grid_maravillas")
	lbl_header_maravillas = refs.get("lbl_header_maravillas")
	contenedor_borrar_edificios = refs.get("contenedor_borrar_edificios")
	panel_externos = refs.get("panel_externos")
	lbl_ext_edif = refs.get("lbl_ext_edif")
	lbl_ext_mej = refs.get("lbl_ext_mej")
	scroll_ext_edif = refs.get("scroll_ext_edif")
	scroll_ext_mej = refs.get("scroll_ext_mej")
	btn_del_ext = refs.get("btn_del_ext")
	contenedor_edificios_externos = refs.get("contenedor_edificios_externos")
	contenedor_mejoras_externas = refs.get("contenedor_mejoras_externas")
	panel_asentamientos_ui = refs.get("panel_asentamientos_ui")
	contenedor_lista_asentamientos = refs.get("contenedor_lista_asentamientos")
	lbl_era_actual = refs.get("lbl_era_actual")
	lbl_civ_actual = refs.get("lbl_civ_actual")
	btn_avanzar_era = refs.get("btn_avanzar_era")
	btn_sincretismo = refs.get("btn_sincretismo")
	lbl_info = refs.get("lbl_info")
	panel_info = refs.get("panel_info")
	lbl_nombre_partida = refs.get("lbl_nombre_partida")
	
	camera = Camera2D.new()
	camera.position = Vector2.ZERO
	camera.zoom = Vector2(1.3, 1.3)
	add_child(camera)
	
	_crear_panel_estadisticas()
	
	_controlar_botones_navegacion(false)
	mostrar_pantalla_partidas_guardadas()

# ==============================================================================
# PUENTES DE DELEGACIÓN (LLAMADAS A LOS GESTORES)
# ==============================================================================

func guardar_partida_actual(): GestorArchivos.guardar_partida_actual(self)
func cargar_partida_especifica(nombre: String): GestorArchivos.cargar_partida_especifica(self, nombre)
func mostrar_dialogo_cargar(): GestorArchivos.mostrar_dialogo_cargar(self)

func celda_tiene_desarrollo(datos: Dictionary) -> bool:
	return GestorPincel.celda_tiene_desarrollo(datos)

func _aplicar_bioma_y_terreno(b: String, t: String): GestorPincel.aplicar_bioma_y_terreno(self, b, t)
func _aplicar_caracteristica(c: String): GestorPincel.aplicar_caracteristica(self, c)
func _aplicar_recurso(recurso_nombre: String): GestorPincel.aplicar_recurso(self, recurso_nombre)
func _aplicar_maravilla_natural(maravilla_nombre: String): GestorPincel.aplicar_maravilla_natural(self, maravilla_nombre)
func _borrar_maravilla_natural(): GestorPincel.borrar_maravilla_natural(self)
func _marcar_favorita(val: int): GestorPincel.marcar_favorita(self, val)
func _toggle_rio_celda(): GestorPincel.toggle_rio_celda(self)

func actualizar_sugerencias_cache(): 
	sugerencias_cache = GestorConstruccion.calcular_sugerencias_edificios(self)
func _aplicar_edificio(edificio: String): GestorConstruccion.aplicar_edificio(self, edificio)
func _aplicar_mejora(tipo: String): GestorConstruccion.aplicar_mejora(self, tipo)
func _borrar_edificio_especifico(edificio_nombre: String): GestorConstruccion.borrar_edificio_especifico(self, edificio_nombre)
func _borrar_mejora(): GestorConstruccion.borrar_mejora(self)
func _aplicar_edificio_externo(edificio: String): GestorConstruccion.aplicar_edificio_externo(self, edificio)
func _aplicar_mejora_externo(mejora: String): GestorConstruccion.aplicar_mejora_externo(self, mejora)
func _borrar_externo(): GestorConstruccion.borrar_externo(self)

func mostrar_dialogo_renombrar(idx: int): GestorDialogos.mostrar_dialogo_renombrar(self, idx)
func mostrar_dialogo_borrar_asentamiento(idx: int): GestorDialogos.mostrar_dialogo_borrar_asentamiento(self, idx)
func mostrar_dialogo_nueva_partida(): GestorDialogos.mostrar_dialogo_nueva_partida(self)
func mostrar_dialogo_confirmar_siguiente_era(): GestorDialogos.mostrar_dialogo_confirmar_siguiente_era(self)
func mostrar_dialogo_sincretismo(): GestorDialogos.mostrar_dialogo_sincretismo(self)
func mostrar_dialogo_lideres_inicio(iniciar_nueva_partida_despues: bool = true): GestorDialogos.mostrar_dialogo_lideres_inicio(self, iniciar_nueva_partida_despues)
func crear_nuevo_asentamiento(tipo: String): GestorAsentamientos.crear_nuevo_asentamiento(self, tipo)
func resetear_asentamiento(idx: int): GestorAsentamientos.resetear_asentamiento(self, idx)
func cambiar_asentamiento_activo(idx: int): GestorAsentamientos.cambiar_asentamiento_activo(self, idx)

# ==============================================================================
# LÓGICA DE VISUALIZACIÓN Y CÁMARA
# ==============================================================================

func centrar_camara_en_activo():
	if camera and asentamientos.size() > 0 and asentamiento_activo_idx < asentamientos.size():
		var centro = asentamientos[asentamiento_activo_idx].centro
		var pos_mundo = HexMath.cubo_a_pixel(radio_hex, centro.x, centro.y, -centro.x - centro.y)
		
		var panel_activo = null
		match seccion_actual:
			"PINCEL": panel_activo = panel_biomas
			"CONSTRUCCION": panel_activo = panel_construccion
			"EXTERNOS": panel_activo = panel_externos
			"ASENTAMIENTOS": panel_activo = panel_asentamientos_ui
			"MARAVILLAS": panel_activo = panel_maravillas
			
		var panel_w = 0.0
		if panel_activo and panel_activo is Control and panel_activo.visible:
			panel_w = max(panel_activo.size.x, panel_activo.custom_minimum_size.x)
			if panel_w <= 0: panel_w = 380.0
			
		var offset_x = (panel_w * 0.5) / camera.zoom.x
		camera.position = pos_mundo - Vector2(offset_x, 0)

func mostrar_dialogo_guardar_como():
	var dialog = AcceptDialog.new()
	dialog.title = "Save Game As"
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	var lbl = Label.new()
	lbl.text = "Enter save name:"
	vbox.add_child(lbl)
	var line_edit = LineEdit.new()
	line_edit.text = partida_actual_nombre
	line_edit.custom_minimum_size = Vector2(250, 40)
	vbox.add_child(line_edit)
	dialog.add_child(vbox)
	
	dialog.confirmed.connect(func():
		var nuevo_nombre = line_edit.text.strip_edges()
		if nuevo_nombre != "":
			partida_actual_nombre = nuevo_nombre
			guardar_partida_actual()
		centrar_camara_en_activo()
		dialog.queue_free()
	)
	dialog.close_requested.connect(func():
		centrar_camara_en_activo()
		dialog.queue_free()
	)
	get_tree().root.add_child(dialog)
	dialog.popup_centered(Vector2(320, 160))

func es_mejora_compatible_con_recurso(mej_nombre: String, recurso: String, era: String) -> bool:
	var rec_lower = recurso.strip_edges().to_lower()
	match era:
		"Antiquity":
			match mej_nombre:
				"Quarry": return rec_lower in ["gypsum", "jade", "kaolin", "marble", "limestone"]
				"Clay Pit": return rec_lower in ["clay"]
				"Woodcutter": return rec_lower in ["hardwood"]
				"Fishing Boat": return rec_lower in ["cowrie", "crabs", "dyes", "fish", "pearls", "turtles"]
				"Mine": return rec_lower in ["gold", "iron", "rubies", "salt", "silver", "tin"]
				"Camp": return rec_lower in ["ivory", "camels", "hides", "wild game"]
				"Pasture": return rec_lower in ["horses", "llamas", "wool"]
				"Plantation": return rec_lower in ["cotton", "dates", "flax", "incense", "mangoes", "rice", "silk", "wine"]
				_: return false
		"Exploration":
			match mej_nombre:
				"Clay Pit": return rec_lower in ["clay"]
				"Woodcutter": return rec_lower in ["cocoa", "hardwood", "spices"]
				"Fishing Boat": return rec_lower in ["cowrie", "crabs", "dyes", "fish", "pearls", "turtles", "whales"]
				"Mine": return rec_lower in ["gold", "iron", "rubies", "silver", "niter", "tin"]
				"Camp": return rec_lower in ["camels", "furs", "ivory", "truffles", "wild game"]
				"Pasture": return rec_lower in ["horses", "llamas"]
				"Plantation": return rec_lower in ["cotton", "dates", "flax", "incense", "mangoes", "rice", "silk", "sugar", "tea", "wine"]
				"Quarry": return rec_lower in ["gypsum", "jade", "kaolin", "limestone", "marble"]
				_: return false
		"Modern Age":
			match mej_nombre:
				"Woodcutter": return rec_lower in ["cocoa", "hardwood", "quinine", "rubber", "spices"]
				"Fishing Boat": return rec_lower in ["cowrie", "crabs", "fish", "pearls", "whales"]
				"Mine": return rec_lower in ["coal", "gold", "iron", "niter", "silver", "tin"]
				"Camp": return rec_lower in ["furs", "ivory", "truffles"]
				"Oil Rig": return rec_lower in ["oil"]
				"Pasture": return rec_lower in ["horses", "llamas"]
				"Plantation": return rec_lower in ["citrus", "coffee", "cotton", "rice", "silk", "sugar", "tea", "tobacco", "wine"]
				"Quarry": return rec_lower in ["jade", "kaolin", "limestone", "marble"]
				_: return false
	return false

func _es_celda_urbana(coord: Vector2i) -> bool:
	if not city_grid.has(coord): return false
	var d = city_grid[coord]
	if d.ajeno: return false
	if d.edificios.size() > 0: return true
	return false

func obtener_multiplicador_era() -> int:
	match era_actual:
		"Antiquity": return 1
		"Exploration": return 2
		"Modern Age": return 3
		_: return 1

func asentamiento_tiene_agua_dulce(coord_centro: Vector2i) -> bool:
	if not city_grid.has(coord_centro): return false
	var d_centro = city_grid[coord_centro]
	if d_centro.get("rio", false) or d_centro.terreno == "LAKE" or d_centro.terreno == "NAVIGABLE_RIVER":
		return true
	for vec in HexMath.VECINOS_HEX:
		var n = coord_centro + vec
		if city_grid.has(n):
			var d_n = city_grid[n]
			if d_n.get("rio", false) or d_n.terreno == "LAKE" or d_n.terreno == "NAVIGABLE_RIVER":
				return true
	return false

func calcular_adyacencia_palacio(coord_centro: Vector2i) -> Dictionary:
	var bonus = {"Science": 0, "Culture": 0}
	for vec in HexMath.VECINOS_HEX:
		var n = coord_centro + vec
		if city_grid.has(n):
			var d_n = city_grid[n]
			if d_n.get("ajeno", false): continue
			
			var tiene_maravilla = false
			var reg_count = 0
			var is_full_tile = false
			
			for e in d_n.edificios:
				if Constantes.MARAVILLAS_NATURALES.has(e) or Constantes.DATOS_EDIFICIOS.get(e, {}).get("is_wonder", false):
					tiene_maravilla = true
					break
				
				if not ReglasJuego.es_edificio_muralla(e):
					reg_count += 1
					if Constantes.DATOS_EDIFICIOS.get(e, {}).get("full_tile", false) or e in ["Aerodrome", "Rail Station"]:
						is_full_tile = true
						
			# Es un distrito si tiene 2 edificios normales o 1 edificio completo
			if not tiene_maravilla and (reg_count >= 2 or is_full_tile):
				bonus["Science"] += 1
				bonus["Culture"] += 1
				
	return bonus

func _calcular_celdas_puente_requeridas() -> Dictionary:
	var requeridas = {}
	if asentamientos.size() == 0 or asentamiento_activo_idx >= asentamientos.size(): return requeridas
	var centro = asentamientos[asentamiento_activo_idx].centro
	
	var u_valid = {}
	var queue = [centro]
	u_valid[centro] = true
	
	var index = 0
	while index < queue.size():
		var actual = queue[index]
		index += 1
		for vec in HexMath.VECINOS_HEX:
			var n = actual + vec
			if city_grid.has(n) and not u_valid.has(n):
				if _es_celda_urbana(n):
					u_valid[n] = true
					queue.append(n)
					
	for coord in city_grid.keys():
		if _es_celda_urbana(coord) and not u_valid.has(coord):
			var actual = coord
			while actual != centro:
				var dist_actual = HexMath.dist_hex(actual, centro)
				var mejor_vecino = actual
				for vec in HexMath.VECINOS_HEX:
					var n = actual + vec
					if city_grid.has(n) and HexMath.dist_hex(n, centro) < dist_actual:
						mejor_vecino = n
						break
				actual = mejor_vecino
				if u_valid.has(actual): break
				if not _es_celda_urbana(actual):
					requeridas[actual] = true
					for vec_req in HexMath.VECINOS_HEX:
						var n_req = actual + vec_req
						if city_grid.has(n_req) and not _es_celda_urbana(n_req) and HexMath.dist_hex(n_req, centro) <= HexMath.dist_hex(actual, centro):
							requeridas[n_req] = true
					
	return requeridas

func es_celda_externos_valida() -> bool:
	if asentamientos.size() == 0 or asentamiento_activo_idx >= asentamientos.size(): return false
	if not city_grid.has(celda_seleccionada): return false
	var asent_centro = asentamientos[asentamiento_activo_idx].centro
	var dist = HexMath.dist_hex(celda_seleccionada, asent_centro)
	
	# Permitir celdas a partir del anillo 2
	if dist < 2: return false
	
	var d = city_grid[celda_seleccionada]
	var es_anillo_4 = (dist == 4)
	
	# Las celdas reclamadas no son externas (el anillo 4 nunca se reclama)
	if d.get("reclamada", false) and not es_anillo_4: return false
	
	var tiene_desarrollo_interno = (d.edificios.size() > 0 or d.mejora_tipo != "") and not d.ajeno
	if tiene_desarrollo_interno: return false
	
	if d.terreno in ["MOUNTAINOUS", "OCEAN"] or d.get("caracteristica", "") in ["ICE", "NATURAL_WONDER"]:
		return false
		
	return true

func actualizar_visibilidad_boton_externos():
	if btn_modo_externos:
		var visible_val = es_celda_externos_valida()
		btn_modo_externos.visible = visible_val
		if not visible_val and seccion_actual == "EXTERNOS":
			cambiar_seccion("CONSTRUCCION")

func resolver_ruta_asset(item_name: String) -> String:
	var map = {
		"Food B.": "food", "Production B.": "production", "Gold B.": "gold", 
		"Science B.": "science", "Culture B.": "culture", "Happiness B.": "happiness", "Influence B.": "influence"
	}
	var name_to_use = map.get(item_name, item_name)
	if name_to_use == "Gold": name_to_use = "goldr"
	if name_to_use == "Ha'amonga 'a Maui": return "res://assets/haamonga_a_maui.png"
	if name_to_use == "Thành Huế": return "res://assets/thanh_hue.png"
	
	var limpio = name_to_use.to_lower()
	limpio = limpio.replace(" ", "_").replace("'", "").replace("`", "")
	limpio = limpio.replace("á", "a").replace("é", "e").replace("í", "i").replace("ó", "o").replace("ú", "u")
	limpio = limpio.replace("à", "a").replace("è", "e").replace("ì", "i").replace("ò", "o").replace("ù", "u")
	limpio = limpio.replace("ế", "e").replace("ầ", "a")
	
	var path_lower = "res://assets/" + limpio + ".png"
	if ResourceLoader.exists(path_lower): return path_lower
	return ""

func _crear_selector_civs(seleccion_actual: String, btn_group: ButtonGroup, incluir_none: bool = false, solo_era_destino: String = "", civ_actual_mantener: String = "") -> Control:
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(580, 240)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)

	var grupos = [
		{"titulo": "ANTIQUITY", "era": "Antiquity", "civs": Constantes.CIVS_ANTIQUITY},
		{"titulo": "EXPLORATION", "era": "Exploration", "civs": Constantes.CIVS_EXPLORATION},
		{"titulo": "MODERN AGE", "era": "Modern Age", "civs": Constantes.CIVS_MODERN}
	]

	if incluir_none:
		var btn_none = _crear_boton_civ("None", btn_group, seleccion_actual == "None")
		vbox.add_child(btn_none)

	if solo_era_destino != "" and civ_actual_mantener != "" and civ_actual_mantener != "None":
		var panel_title = PanelContainer.new()
		var sb_title = StyleBoxFlat.new()
		sb_title.bg_color = Color(0.15, 0.15, 0.18)
		sb_title.set_corner_radius_all(6)
		panel_title.add_theme_stylebox_override("panel", sb_title)
		
		var hb_title = HBoxContainer.new()
		hb_title.alignment = BoxContainer.ALIGNMENT_CENTER
		hb_title.add_theme_constant_override("separation", 8)
		var lbl = Label.new()
		lbl.text = "CURRENT CIVILIZATION"
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
		hb_title.add_child(lbl)
		panel_title.add_child(hb_title)
		vbox.add_child(panel_title)

		var grid_curr = GridContainer.new()
		grid_curr.columns = 6
		grid_curr.add_theme_constant_override("h_separation", 6)
		grid_curr.add_theme_constant_override("v_separation", 6)
		var btn_curr = _crear_boton_civ(civ_actual_mantener, btn_group, civ_actual_mantener == seleccion_actual)
		grid_curr.add_child(btn_curr)
		vbox.add_child(grid_curr)

	for g in grupos:
		if solo_era_destino != "" and g.era != solo_era_destino:
			continue
		var panel_title = PanelContainer.new()
		var sb_title = StyleBoxFlat.new()
		sb_title.bg_color = Color(0.15, 0.15, 0.18)
		sb_title.set_corner_radius_all(6)
		panel_title.add_theme_stylebox_override("panel", sb_title)
		
		var hb_title = HBoxContainer.new()
		hb_title.alignment = BoxContainer.ALIGNMENT_CENTER
		hb_title.add_theme_constant_override("separation", 8)
		var tex = TextureRect.new()
		tex.custom_minimum_size = Vector2(20, 20)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var path = resolver_ruta_asset(g.era)
		if ResourceLoader.exists(path): tex.texture = load(path)
		hb_title.add_child(tex)
		
		var lbl = Label.new()
		lbl.text = g.titulo
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
		hb_title.add_child(lbl)
		panel_title.add_child(hb_title)
		vbox.add_child(panel_title)

		var grid = GridContainer.new()
		grid.columns = 6
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)

		for civ in g.civs:
			var btn = _crear_boton_civ(civ, btn_group, civ == seleccion_actual)
			grid.add_child(btn)
		vbox.add_child(grid)

	return scroll

func _crear_boton_civ(civ_name: String, btn_group: ButtonGroup, is_selected: bool) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(88, 96)
	btn.toggle_mode = true
	btn.button_group = btn_group
	btn.button_pressed = is_selected
	btn.set_meta("civ_name", civ_name)
	
	var sb_normal = StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.12, 0.12, 0.16)
	sb_normal.border_color = Color(0.3, 0.3, 0.3)
	sb_normal.set_border_width_all(2)
	sb_normal.set_corner_radius_all(6)
	
	var sb_pressed = sb_normal.duplicate()
	sb_pressed.bg_color = Color(0.2, 0.3, 0.5)
	sb_pressed.border_color = Color(0.4, 0.8, 1.0)
	sb_pressed.set_border_width_all(3)

	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_stylebox_override("hover", sb_pressed)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)

	var tex_rect = TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(48, 48)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var path = resolver_ruta_asset(civ_name)
	if ResourceLoader.exists(path): tex_rect.texture = load(path)
	vbox.add_child(tex_rect)

	var lbl = Label.new()
	lbl.text = civ_name
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.custom_minimum_size = Vector2(84, 22)
	vbox.add_child(lbl)

	btn.add_child(vbox)
	return btn

func bioma_es_valido(bioma_actual: String, biomas_validos: Array) -> bool:
	for b_val in biomas_validos:
		if b_val == "TODOS": return true
		var partes = b_val.split(",")
		for p in partes:
			if p.strip_edges().to_upper() == bioma_actual.strip_edges().to_upper():
				return true
	return false

# ==============================================================================
# LÓGICA DE ACTUALIZACIÓN DE PANELES (UI)
# ==============================================================================

func actualizar_lista_asentamientos_ui():
	if not contenedor_lista_asentamientos: return
	for child in contenedor_lista_asentamientos.get_children(): child.queue_free()
		
	for i in range(asentamientos.size()):
		var asent = asentamientos[i]
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 6)
		
		var btn_rename = Button.new()
		btn_rename.text = "✏️"
		btn_rename.custom_minimum_size = Vector2(38, 42)
		var index_r = i
		btn_rename.pressed.connect(func(): mostrar_dialogo_renombrar(index_r))
		hbox.add_child(btn_rename)
		
		var path_icono = ""
		if asent.tipo == "Capital": path_icono = resolver_ruta_asset("Palace")
		elif asent.tipo == "Town": path_icono = resolver_ruta_asset("town")
		else: path_icono = resolver_ruta_asset("settlement")
		
		var btn = Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(160, 42)
		if i == asentamiento_activo_idx: btn.modulate = Color(1.3, 1.3, 1.3)
		else: btn.modulate = Color(0.7, 0.7, 0.7)
		
		var btn_hbox = HBoxContainer.new()
		btn_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
		
		var m_left = MarginContainer.new()
		m_left.add_theme_constant_override("margin_left", 8)
		btn_hbox.add_child(m_left)
		
		var tex_rect = TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(28, 28)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if ResourceLoader.exists(path_icono): tex_rect.texture = load(path_icono)
		btn_hbox.add_child(tex_rect)
		
		var lbl_name = Label.new()
		lbl_name.text = " " + asent.nombre
		lbl_name.add_theme_font_size_override("font_size", 14)
		lbl_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		btn_hbox.add_child(lbl_name)
		
		btn.add_child(btn_hbox)
		var index = i
		btn.pressed.connect(func(): GestorAsentamientos.cambiar_asentamiento_activo(self, index))
		hbox.add_child(btn)
		
		if asent.tipo == "Town":
			var btn_type = Button.new()
			btn_type.custom_minimum_size = Vector2(50, 42)
			btn_type.tooltip_text = "Upgrade to City"
			var type_hbox = HBoxContainer.new()
			type_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
			type_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
			type_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
			
			var set_tex = TextureRect.new()
			set_tex.custom_minimum_size = Vector2(26, 26)
			set_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			set_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			if ResourceLoader.exists(resolver_ruta_asset("settlement")): set_tex.texture = load(resolver_ruta_asset("settlement"))
			type_hbox.add_child(set_tex)
			btn_type.add_child(type_hbox)
			
			var index_t = i
			btn_type.pressed.connect(func():
				asentamientos[index_t].tipo = "City"
				actualizar_lista_asentamientos_ui()
				guardar_partida_actual()
			)
			hbox.add_child(btn_type)
		
		var btn_reset = Button.new()
		btn_reset.text = "🔄"
		btn_reset.custom_minimum_size = Vector2(38, 42)
		btn_reset.pressed.connect(func(): resetear_asentamiento(index))
		hbox.add_child(btn_reset)
		
		if asent.tipo != "Capital":
			var btn_del = Button.new()
			btn_del.text = "🗑️"
			btn_del.custom_minimum_size = Vector2(38, 42)
			var idx_del = i
			btn_del.pressed.connect(func(): mostrar_dialogo_borrar_asentamiento(idx_del))
			hbox.add_child(btn_del)
		
		contenedor_lista_asentamientos.add_child(hbox)

func actualizar_botones_recursos_ui():
	if not grid_recursos: return
	for child in grid_recursos.get_children(): child.queue_free()
		
	var parent = grid_recursos.get_parent()
	var idx = grid_recursos.get_index()
	var header_node = null
	if idx > 0:
		header_node = parent.get_child(idx - 1)
		if header_node is Label:
			var h_box = _crear_cabecera_panel("RESOURCES", "resources")
			h_box.name = "HeaderRecursos"
			parent.add_child(h_box)
			parent.move_child(h_box, idx - 1)
			header_node.queue_free()
			header_node = h_box

	if asentamientos.size() == 0 or asentamiento_activo_idx >= asentamientos.size(): return
	if not city_grid.has(celda_seleccionada): return
	var datos_celda = city_grid[celda_seleccionada]
	var tiene_desarrollo = celda_tiene_desarrollo(datos_celda)

	if tiene_desarrollo:
		if header_node: header_node.visible = false
		grid_recursos.visible = false
		if btn_quitar_recurso: btn_quitar_recurso.visible = false
		return

	var asent_centro = asentamientos[asentamiento_activo_idx].centro
	var es_centro = (celda_seleccionada == asent_centro or datos_celda.edificios.has("Palace") or datos_celda.edificios.has("Town Hall"))
	var bioma_actual = datos_celda.bioma
	var terreno_actual = datos_celda.terreno
	var carac_actual = datos_celda.get("caracteristica", "NONE")
	
	if es_centro or terreno_actual in ["MOUNTAINOUS", "OCEAN", "NAVIGABLE_RIVER"] or carac_actual == "ICE":
		if header_node: header_node.visible = false
		grid_recursos.visible = false
		if btn_quitar_recurso: btn_quitar_recurso.visible = false
		return
	
	if carac_actual == "NATURAL_WONDER":
		if header_node and header_node is HBoxContainer:
			for child in header_node.get_children():
				if child is Label:
					child.text = "NATURAL WONDERS"
					break
		if header_node: header_node.visible = true
		grid_recursos.visible = true
		grid_recursos.columns = 2
		if btn_quitar_recurso: btn_quitar_recurso.visible = false
		
		if Constantes.MARAVILLAS_NATURALES:
			for mar_name in Constantes.MARAVILLAS_NATURALES.keys():
				var m_data = Constantes.MARAVILLAS_NATURALES[mar_name]
				var ter_validos = m_data.get("terreno", [])
				var bio_validos = m_data.get("bioma", [])
				var ter_ok = ("TODOS" in ter_validos) or (terreno_actual in ter_validos)
				var bio_ok = bioma_es_valido(bioma_actual, bio_validos)
				
				if not (ter_ok and bio_ok): continue
				
				var vbox_item = VBoxContainer.new()
				vbox_item.add_theme_constant_override("separation", 6)
				vbox_item.alignment = BoxContainer.ALIGNMENT_CENTER
				
				var btn = Button.new()
				btn.custom_minimum_size = Vector2(100, 100)
				btn.clip_contents = true
				btn.tooltip_text = mar_name
				
				var sb = StyleBoxFlat.new()
				sb.bg_color = Color(0.2, 0.1, 0.3)
				sb.border_color = Color(0.9, 0.4, 0.9)
				sb.set_border_width_all(2)
				sb.set_corner_radius_all(12)
				btn.add_theme_stylebox_override("normal", sb)
				
				var tex_path = resolver_ruta_asset(mar_name)
				if ResourceLoader.exists(tex_path):
					var tex_rect = TextureRect.new()
					tex_rect.texture = load(tex_path)
					tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
					tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
					tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
					btn.add_child(tex_rect)
				else:
					btn.text = mar_name
					btn.add_theme_font_size_override("font_size", 12)
					
				var mar_param = mar_name
				btn.pressed.connect(func(): _aplicar_maravilla_natural(mar_param))
				vbox_item.add_child(btn)
				
				var lbl = Label.new()
				lbl.text = mar_name
				lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lbl.add_theme_font_size_override("font_size", 11)
				lbl.add_theme_color_override("font_color", Color.WHITE)
				lbl.custom_minimum_size = Vector2(100, 0)
				lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				vbox_item.add_child(lbl)
				grid_recursos.add_child(vbox_item)
		return

	if header_node and header_node is HBoxContainer:
		for child in header_node.get_children():
			if child is Label:
				child.text = "RESOURCES"
				break
	if header_node: header_node.visible = true
	grid_recursos.columns = 6

	var recurso_actual = datos_celda.get("recurso", "")
	if recurso_actual != "":
		grid_recursos.visible = false
		if header_node: header_node.visible = false
		if btn_quitar_recurso: btn_quitar_recurso.visible = true
		return
	else:
		grid_recursos.visible = true
		if header_node: header_node.visible = true
		if btn_quitar_recurso: btn_quitar_recurso.visible = false

	if Constantes.RECURSOS_POR_ERA.has(era_actual):
		var dict_recursos = Constantes.RECURSOS_POR_ERA[era_actual]
		for rec_name in dict_recursos.keys():
			if rec_name.strip_edges().to_lower() == "lapis lazuli": continue
			var biomas_validos = dict_recursos[rec_name]
			var es_valido = false
			if bioma_es_valido(bioma_actual, biomas_validos): es_valido = true
			elif "AGUAS" in biomas_validos and terreno_actual in ["LAKE", "COASTAL", "OCEAN"]: es_valido = true
				
			if not es_valido: continue
			
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(46, 46)
			btn.tooltip_text = rec_name.capitalize()
			
			var sb = StyleBoxFlat.new()
			sb.bg_color = Color(0.12, 0.12, 0.16)
			sb.border_color = Color(0.8, 0.5, 0.2)
			sb.set_border_width_all(2)
			sb.set_corner_radius_all(12)
			btn.add_theme_stylebox_override("normal", sb)
			
			var tex_path = resolver_ruta_asset(rec_name)
			if ResourceLoader.exists(tex_path):
				btn.icon = load(tex_path)
				btn.expand_icon = true
				btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			else:
				btn.text = rec_name.substr(0, 4)
				btn.add_theme_font_size_override("font_size", 10)
				
			var rec_param = rec_name
			btn.pressed.connect(func(): _aplicar_recurso(rec_param))
			grid_recursos.add_child(btn)

func actualizar_panel_maravillas_naturales():
	if not grid_maravillas_naturales: return
	for child in grid_maravillas_naturales.get_children(): child.queue_free()
	
	if not city_grid.has(celda_seleccionada): return
	var d = city_grid[celda_seleccionada]
	if d.get("caracteristica", "") != "NATURAL_WONDER": return
	
	var bioma_actual = d.bioma
	var terreno_actual = d.terreno
	
	if Constantes.MARAVILLAS_NATURALES:
		for mar_name in Constantes.MARAVILLAS_NATURALES.keys():
			var m_data = Constantes.MARAVILLAS_NATURALES[mar_name]
			var ter_validos = m_data.get("terreno", [])
			var bio_validos = m_data.get("bioma", [])
			
			var ter_ok = ("TODOS" in ter_validos) or (terreno_actual in ter_validos)
			var bio_ok = bioma_es_valido(bioma_actual, bio_validos)
			
			if not (ter_ok and bio_ok): continue
			
			var vbox_item = VBoxContainer.new()
			vbox_item.add_theme_constant_override("separation", 8)
			vbox_item.alignment = BoxContainer.ALIGNMENT_CENTER
			
			var panel_icono = PanelContainer.new()
			panel_icono.custom_minimum_size = Vector2(180, 180)
			
			var sb = StyleBoxFlat.new()
			sb.bg_color = Color(0.2, 0.1, 0.3)
			sb.border_color = Color(0.9, 0.4, 0.9)
			sb.set_border_width_all(3)
			sb.set_corner_radius_all(16)
			panel_icono.add_theme_stylebox_override("panel", sb)
			panel_icono.clip_contents = true
			
			var tex_path = resolver_ruta_asset(mar_name)
			if ResourceLoader.exists(tex_path):
				var tex_rect = TextureRect.new()
				tex_rect.texture = load(tex_path)
				tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
				tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
				tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				panel_icono.add_child(tex_rect)
			
			var btn = Button.new()
			btn.set_anchors_preset(Control.PRESET_FULL_RECT)
			var sb_trans = StyleBoxFlat.new()
			sb_trans.bg_color = Color(0, 0, 0, 0)
			sb_trans.set_corner_radius_all(16)
			btn.add_theme_stylebox_override("normal", sb_trans)
			var sb_hover = StyleBoxFlat.new()
			sb_hover.bg_color = Color(1, 1, 1, 0.15)
			sb_hover.set_corner_radius_all(16)
			btn.add_theme_stylebox_override("hover", sb_hover)
			
			var mar_param = mar_name
			btn.pressed.connect(func(): _aplicar_maravilla_natural(mar_param))
			panel_icono.add_child(btn)
			vbox_item.add_child(panel_icono)
			
			var lbl = Label.new()
			lbl.text = mar_name
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 14)
			lbl.add_theme_color_override("font_color", Color.WHITE)
			lbl.custom_minimum_size = Vector2(180, 0)
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vbox_item.add_child(lbl)
			grid_maravillas_naturales.add_child(vbox_item)

func celda_tiene_maravillas_compatibles(bioma: String, terreno: String) -> bool:
	if not Constantes.MARAVILLAS_NATURALES: return false
	for mar_name in Constantes.MARAVILLAS_NATURALES.keys():
		var m_data = Constantes.MARAVILLAS_NATURALES[mar_name]
		var ter_validos = m_data.get("terreno", [])
		var bio_validos = m_data.get("bioma", [])
		var ter_ok = ("TODOS" in ter_validos) or (terreno in ter_validos)
		var bio_ok = bioma_es_valido(bioma, bio_validos)
		if ter_ok and bio_ok: return true
	return false

func actualizar_panel_gestion_ui():
	if lbl_nombre_partida: lbl_nombre_partida.visible = false
	if lbl_era_actual: lbl_era_actual.visible = false
	
	if lbl_civ_actual:
		var contenedor_civs_visual = lbl_civ_actual.get_node_or_null("ContenedorCivsVisual")
		if contenedor_civs_visual:
			for c in contenedor_civs_visual.get_children(): c.queue_free()
			
			var main_vbox = VBoxContainer.new()
			main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			main_vbox.add_theme_constant_override("separation", 10)
			
			var lbl_header = Label.new()
			lbl_header.text = "💾 Game: " + partida_actual_nombre
			lbl_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl_header.add_theme_font_size_override("font_size", 14)
			lbl_header.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
			main_vbox.add_child(lbl_header)
			
			var separator = HSeparator.new()
			main_vbox.add_child(separator)
			
			var main_row = HBoxContainer.new()
			main_row.alignment = BoxContainer.ALIGNMENT_CENTER
			main_row.add_theme_constant_override("separation", 24)
			
			var vbox_era = VBoxContainer.new()
			vbox_era.alignment = BoxContainer.ALIGNMENT_CENTER
			vbox_era.add_theme_constant_override("separation", 4)
			var panel_era = PanelContainer.new()
			var sb_era = StyleBoxFlat.new()
			sb_era.bg_color = Color(0.12, 0.12, 0.16)
			sb_era.border_color = Color(0.9, 0.7, 0.3)
			sb_era.set_border_width_all(2)
			sb_era.set_corner_radius_all(6)
			panel_era.add_theme_stylebox_override("panel", sb_era)
			panel_era.custom_minimum_size = Vector2(52, 52)
			
			var tex_era = TextureRect.new()
			tex_era.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_era.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			var path_era = resolver_ruta_asset(era_actual)
			if ResourceLoader.exists(path_era): tex_era.texture = load(path_era)
			panel_era.add_child(tex_era)
			vbox_era.add_child(panel_era)
			
			var lbl_era_name = Label.new()
			lbl_era_name.text = era_actual
			lbl_era_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl_era_name.add_theme_font_size_override("font_size", 10)
			lbl_era_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl_era_name.custom_minimum_size = Vector2(70, 0)
			vbox_era.add_child(lbl_era_name)
			main_row.add_child(vbox_era)
			
			var vbox_lider = VBoxContainer.new()
			vbox_lider.alignment = BoxContainer.ALIGNMENT_CENTER
			vbox_lider.add_theme_constant_override("separation", 4)
			var panel_lider = PanelContainer.new()
			var sb_lider = StyleBoxFlat.new()
			sb_lider.bg_color = Color(0.12, 0.12, 0.16)
			sb_lider.border_color = Color(0.5, 0.8, 0.5)
			sb_lider.set_border_width_all(2)
			sb_lider.set_corner_radius_all(6)
			panel_lider.add_theme_stylebox_override("panel", sb_lider)
			panel_lider.custom_minimum_size = Vector2(52, 52)
			
			var tex_lider = TextureRect.new()
			tex_lider.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_lider.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			var path_lider = resolver_ruta_asset(lider_actual)
			if ResourceLoader.exists(path_lider): tex_lider.texture = load(path_lider)
			panel_lider.add_child(tex_lider)
			vbox_lider.add_child(panel_lider)
			
			var lbl_lider_name = Label.new()
			lbl_lider_name.text = lider_actual
			lbl_lider_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl_lider_name.add_theme_font_size_override("font_size", 10)
			lbl_lider_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl_lider_name.custom_minimum_size = Vector2(70, 0)
			vbox_lider.add_child(lbl_lider_name)
			main_row.add_child(vbox_lider)
			
			var civs_sub_hbox = HBoxContainer.new()
			civs_sub_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
			civs_sub_hbox.add_theme_constant_override("separation", 12)
			
			var vbox_civ = VBoxContainer.new()
			vbox_civ.alignment = BoxContainer.ALIGNMENT_CENTER
			vbox_civ.add_theme_constant_override("separation", 4)
			var panel_civ = PanelContainer.new()
			var sb_civ = StyleBoxFlat.new()
			sb_civ.bg_color = Color(0.12, 0.12, 0.16)
			sb_civ.border_color = Color(0.6, 0.4, 0.2)
			sb_civ.set_border_width_all(2)
			sb_civ.set_corner_radius_all(6)
			panel_civ.add_theme_stylebox_override("panel", sb_civ)
			panel_civ.custom_minimum_size = Vector2(52, 52)
			
			var tex_civ = TextureRect.new()
			tex_civ.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_civ.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			var path_civ = resolver_ruta_asset(civ_actual)
			if ResourceLoader.exists(path_civ): tex_civ.texture = load(path_civ)
			panel_civ.add_child(tex_civ)
			vbox_civ.add_child(panel_civ)
			
			var lbl_civ_name = Label.new()
			lbl_civ_name.text = civ_actual
			lbl_civ_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl_civ_name.add_theme_font_size_override("font_size", 10)
			lbl_civ_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl_civ_name.custom_minimum_size = Vector2(70, 0)
			vbox_civ.add_child(lbl_civ_name)
			civs_sub_hbox.add_child(vbox_civ)
			
			if civ_sincretismo != "None":
				var vbox_sync = VBoxContainer.new()
				vbox_sync.alignment = BoxContainer.ALIGNMENT_CENTER
				vbox_sync.add_theme_constant_override("separation", 4)
				var panel_sync = PanelContainer.new()
				var sb_sync = StyleBoxFlat.new()
				sb_sync.bg_color = Color(0.12, 0.12, 0.16)
				sb_sync.border_color = Color(0.3, 0.5, 0.8)
				sb_sync.set_border_width_all(2)
				sb_sync.set_corner_radius_all(6)
				panel_sync.add_theme_stylebox_override("panel", sb_sync)
				panel_sync.custom_minimum_size = Vector2(52, 52)
				
				var tex_sync = TextureRect.new()
				tex_sync.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tex_sync.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				var path_sync = resolver_ruta_asset(civ_sincretismo)
				if ResourceLoader.exists(path_sync): tex_sync.texture = load(path_sync)
				panel_sync.add_child(tex_sync)
				vbox_sync.add_child(panel_sync)
				
				var lbl_sync_name = Label.new()
				lbl_sync_name.text = civ_sincretismo
				lbl_sync_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lbl_sync_name.add_theme_font_size_override("font_size", 10)
				lbl_sync_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				lbl_sync_name.custom_minimum_size = Vector2(70, 0)
				vbox_sync.add_child(lbl_sync_name)
				civs_sub_hbox.add_child(vbox_sync)
				
			main_row.add_child(civs_sub_hbox)
			
			var buttons_vbox = VBoxContainer.new()
			buttons_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			buttons_vbox.add_theme_constant_override("separation", 8)
			
			if btn_sincretismo:
				if btn_sincretismo.get_parent(): btn_sincretismo.get_parent().remove_child(btn_sincretismo)
				btn_sincretismo.text = "Syncretism"
				btn_sincretismo.custom_minimum_size = Vector2(130, 32)
				btn_sincretismo.add_theme_font_size_override("font_size", 12)
				var style_sync = StyleBoxFlat.new()
				style_sync.bg_color = Color(0.18, 0.18, 0.22)
				style_sync.border_color = Color(0.4, 0.4, 0.45)
				style_sync.set_border_width_all(1)
				style_sync.set_corner_radius_all(6)
				btn_sincretismo.add_theme_stylebox_override("normal", style_sync)
				buttons_vbox.add_child(btn_sincretismo)
				
			if btn_avanzar_era:
				if btn_avanzar_era.get_parent(): btn_avanzar_era.get_parent().remove_child(btn_avanzar_era)
				var style_btn = StyleBoxFlat.new()
				style_btn.set_corner_radius_all(6)
				match era_actual:
					"Antiquity":
						btn_avanzar_era.text = "Exploration"
						style_btn.bg_color = Color(0.2, 0.45, 0.8)
						style_btn.border_color = Color(0.4, 0.7, 1.0)
						style_btn.set_border_width_all(2)
						btn_avanzar_era.add_theme_stylebox_override("normal", style_btn)
						btn_avanzar_era.visible = true
					"Exploration":
						btn_avanzar_era.text = "Modern"
						style_btn.bg_color = Color(0.75, 0.2, 0.2)
						style_btn.border_color = Color(1.0, 0.4, 0.4)
						style_btn.set_border_width_all(2)
						btn_avanzar_era.add_theme_stylebox_override("normal", style_btn)
						btn_avanzar_era.visible = true
					"Modern Age":
						btn_avanzar_era.visible = false
						
				if btn_avanzar_era.visible:
					btn_avanzar_era.custom_minimum_size = Vector2(130, 32)
					btn_avanzar_era.add_theme_font_size_override("font_size", 12)
					buttons_vbox.add_child(btn_avanzar_era)
					
			if buttons_vbox.get_child_count() > 0:
				main_row.add_child(buttons_vbox)
				
			main_vbox.add_child(main_row)
			contenedor_civs_visual.add_child(main_vbox)

func _crear_btn_opcion(texto: String, bg_color: Color, seleccionado: bool) -> Button:
	var btn = Button.new()
	btn.text = texto
	btn.custom_minimum_size = Vector2(0, 36)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.set_corner_radius_all(4)

	if seleccionado:
		sb.border_color = Color.WHITE
		sb.set_border_width_all(3)
	else:
		sb.border_color = Color(0.1, 0.1, 0.1)
		sb.set_border_width_all(1)

	btn.add_theme_stylebox_override("normal", sb)

	var luma = (bg_color.r * 0.299) + (bg_color.g * 0.587) + (bg_color.b * 0.114)
	if luma > 0.5: btn.add_theme_color_override("font_color", Color.BLACK)
	else: btn.add_theme_color_override("font_color", Color.WHITE)

	return btn

func actualizar_panel_pincel():
	if seccion_actual != "PINCEL" or not grid_biomas: return
	if not city_grid.has(celda_seleccionada): return

	var d = city_grid[celda_seleccionada]
	if celda_tiene_desarrollo(d):
		for child in grid_biomas.get_children(): child.queue_free()
		for child in grid_carac.get_children(): child.queue_free()
		if hbox_favs:
			for child in hbox_favs.get_children(): child.queue_free()
		if grid_terrenos: grid_terrenos.visible = false
		return

	var b_actual = d.bioma
	var t_actual = d.terreno
	var c_actual = d.get("caracteristica", "NONE")
	var f_actual = d.get("favorita", 0)
	
	var es_centro_gob = d.edificios.has("Palace") or d.edificios.has("Town Hall")

	if grid_terrenos:
		grid_terrenos.visible = false
		var parent = grid_terrenos.get_parent()
		if parent:
			var idx = grid_terrenos.get_index()
			if idx > 0:
				var prev = parent.get_child(idx - 1)
				if prev is Label: prev.visible = false

	grid_biomas.columns = 1
	for child in grid_biomas.get_children(): child.queue_free()

	var biomes_orden = ["TUNDRA", "GRASSLAND", "PLAINS", "DESERT", "TROPICAL", "MARINE"]
	var combinaciones_por_bioma = {
		"TUNDRA": [
			{"b": "TUNDRA", "t": "FLAT", "txt": "Tundra Flat", "col": Color(0.94, 0.97, 1.0)},
			{"b": "TUNDRA", "t": "ROUGH", "txt": "Tundra Rough", "col": Color(0.85, 0.9, 0.95)},
			{"b": "TUNDRA", "t": "MOUNTAINOUS", "txt": "Tundra Mountain", "col": Color(0.75, 0.8, 0.85)},
			{"b": "TUNDRA", "t": "NAVIGABLE_RIVER", "txt": "Tundra Nav Riv", "col": Color(0.7, 0.75, 0.8)}
		],
		"GRASSLAND": [
			{"b": "GRASSLAND", "t": "FLAT", "txt": "Grass Flat", "col": Color(0.56, 0.93, 0.56)},
			{"b": "GRASSLAND", "t": "ROUGH", "txt": "Grass Rough", "col": Color(0.45, 0.82, 0.45)},
			{"b": "GRASSLAND", "t": "MOUNTAINOUS", "txt": "Grass Mountain", "col": Color(0.35, 0.7, 0.35)},
			{"b": "GRASSLAND", "t": "NAVIGABLE_RIVER", "txt": "Grass Nav Riv", "col": Color(0.3, 0.6, 0.3)}
		],
		"PLAINS": [
			{"b": "PLAINS", "t": "FLAT", "txt": "Plains Flat", "col": Color(1.0, 0.84, 0.0)},
			{"b": "PLAINS", "t": "ROUGH", "txt": "Plains Rough", "col": Color(0.9, 0.74, 0.0)},
			{"b": "PLAINS", "t": "MOUNTAINOUS", "txt": "Plains Mountain", "col": Color(0.8, 0.64, 0.0)},
			{"b": "PLAINS", "t": "NAVIGABLE_RIVER", "txt": "Plains Nav Riv", "col": Color(0.7, 0.54, 0.0)}
		],
		"DESERT": [
			{"b": "DESERT", "t": "FLAT", "txt": "Desert Flat", "col": Color(1.0, 0.65, 0.0)},
			{"b": "DESERT", "t": "ROUGH", "txt": "Desert Rough", "col": Color(0.9, 0.55, 0.0)},
			{"b": "DESERT", "t": "MOUNTAINOUS", "txt": "Desert Mountain", "col": Color(0.8, 0.45, 0.0)},
			{"b": "DESERT", "t": "NAVIGABLE_RIVER", "txt": "Desert Nav Riv", "col": Color(0.7, 0.35, 0.0)}
		],
		"TROPICAL": [
			{"b": "TROPICAL", "t": "FLAT", "txt": "Tropical Flat", "col": Color(0.0, 0.39, 0.0)},
			{"b": "TROPICAL", "t": "ROUGH", "txt": "Tropical Rough", "col": Color(0.0, 0.3, 0.0)},
			{"b": "TROPICAL", "t": "MOUNTAINOUS", "txt": "Tropical Mountain", "col": Color(0.0, 0.2, 0.0)},
			{"b": "TROPICAL", "t": "NAVIGABLE_RIVER", "txt": "Tropical Nav Riv", "col": Color(0.0, 0.15, 0.0)}
		],
		"MARINE": [
			{"b": "MARINE", "t": "LAKE", "txt": "Marine Lake", "col": Color(0.12, 0.7, 0.67)},
			{"b": "MARINE", "t": "COASTAL", "txt": "Marine Coastal", "col": Color(0.53, 0.81, 0.98)},
			{"b": "MARINE", "t": "OCEAN", "txt": "Marine Ocean", "col": Color(0.0, 0.0, 0.55)}
		]
	}

	var iconos_terreno_map = {
		"FLAT": "",
		"ROUGH": "🪨",
		"MOUNTAINOUS": "⛰️",
		"NAVIGABLE_RIVER": "🚢",
		"LAKE": "🛶",
		"COASTAL": "🌊",
		"OCEAN": "🐋"
	}

	for biome_name in biomes_orden:
		if es_centro_gob and biome_name == "MARINE":
			continue

		var hbox_fila = HBoxContainer.new()
		hbox_fila.add_theme_constant_override("separation", 6)
		hbox_fila.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		for comb in combinaciones_por_bioma[biome_name]:
			if es_centro_gob and (comb.t == "MOUNTAINOUS" or comb.t == "NAVIGABLE_RIVER"):
				continue
			if comb.t == "OCEAN":
				var tiene_coastal = false
				for vec in HexMath.VECINOS_HEX:
					var vecino_coord = celda_seleccionada + vec
					if city_grid.has(vecino_coord) and city_grid[vecino_coord].terreno == "COASTAL":
						tiene_coastal = true
						break
				if not tiene_coastal: continue

			var sel = (comb.b == b_actual and comb.t == t_actual)
			var texto_btn = iconos_terreno_map.get(comb.t, "")
			var btn = _crear_btn_opcion(texto_btn, comb.col, sel)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size = Vector2(0, 36)
			btn.tooltip_text = comb.txt
			var b_val = comb.b
			var t_val = comb.t
			btn.pressed.connect(func(): _aplicar_bioma_y_terreno(b_val, t_val))
			hbox_fila.add_child(btn)
			
		grid_biomas.add_child(hbox_fila)

	for child in grid_carac.get_children(): child.queue_free()
	
	var valid_c = ["NONE"]
	var es_marine = (b_actual == "MARINE")

	# Generación segura de valid_c
	if es_marine:
		valid_c.append("AQUATIC")
		valid_c.append("ICE")
	else:
		if t_actual == "FLAT":
			valid_c.append("WET")
			valid_c.append("VEGETATED")
			valid_c.append("FLOODPLAIN")
		if t_actual == "MOUNTAINOUS":
			valid_c.append("VOLCANO")
		if b_actual == "TUNDRA":
			if not "SNOW" in valid_c: valid_c.append("SNOW")
			if not "ICE" in valid_c: valid_c.append("ICE")

	# FIX MARAVILLAS: Evaluación directa contra Constantes garantizando que no se pierda en Tundra Montaña
	var nw_compatible = false
	if "MARAVILLAS_NATURALES" in Constantes:
		for nw in Constantes.MARAVILLAS_NATURALES.values():
			var b_ok = nw.get("biomas", []).is_empty() or b_actual in nw.get("biomas", [])
			var t_ok = nw.get("terrenos", []).is_empty() or t_actual in nw.get("terrenos", [])
			if b_ok and t_ok:
				nw_compatible = true
				break
				
	if nw_compatible and not es_centro_gob:
		if not "NATURAL_WONDER" in valid_c:
			valid_c.append("NATURAL_WONDER")

	if not c_actual in valid_c:
		c_actual = "NONE"
		d.caracteristica = "NONE"

	var carac_ui = {
		"NONE": {"txt": "None", "col": Color(0.86, 0.08, 0.24)},
		"WET": {"txt": "💧 Wet", "col": Color(0.12, 0.6, 0.55)},
		"VEGETATED": {"txt": "🌲 Vegetated", "col": Color(0.2, 0.6, 0.2)},
		"AQUATIC": {"txt": "Aquatic", "col": Color(0.2, 0.2, 0.2)},
		"FLOODPLAIN": {"txt": "🛤️ Floodplain", "col": Color(0.3, 0.7, 0.9)},
		"VOLCANO": {"txt": "🌋 Volcano", "col": Color(0.2, 0.2, 0.2)},
		"ICE": {"txt": "❄️ Ice", "col": Color(0.2, 0.2, 0.2)},
		"SNOW": {"txt": "Snow", "col": Color(0.2, 0.2, 0.2)},
		"NATURAL_WONDER": {"txt": "Nat. Wonder", "col": Color(0.5, 0.0, 0.5), "icon": "res://assets/natural_wonder.png"}
	}
	
	var info_none = carac_ui["NONE"]
	var btn_none = _crear_btn_opcion(info_none.txt, info_none.col, "NONE" == c_actual)
	btn_none.pressed.connect(func(): _aplicar_caracteristica("NONE"))
	grid_carac.add_child(btn_none)
	
	if t_actual == "FLAT" or t_actual == "ROUGH":
		var btn_rio = _crear_btn_opcion("〰️ Minor River", Color(0.2, 0.6, 0.8), d.get("rio", false))
		btn_rio.pressed.connect(_toggle_rio_celda)
		grid_carac.add_child(btn_rio)
		
	for c in valid_c:
		if c == "NONE": continue
		if es_centro_gob and c == "NATURAL_WONDER": continue
		var info = carac_ui[c]
		var btn = _crear_btn_opcion(info.txt if not info.has("icon") else "", info.col, c == c_actual)
		btn.tooltip_text = info.txt
		if info.has("icon") and ResourceLoader.exists(info.icon):
			btn.icon = load(info.icon)
			btn.expand_icon = true
			btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var c_val = c
		btn.pressed.connect(func(): _aplicar_caracteristica(c_val))
		grid_carac.add_child(btn)

	var asent_centro = asentamientos[asentamiento_activo_idx].centro if asentamientos.size() > 0 else Vector2i.ZERO
	var dist_al_centro = HexMath.dist_hex(celda_seleccionada, asent_centro)
	var es_reclamada = d.get("reclamada", false)
	
	if es_reclamada and dist_al_centro > 1 and not celda_tiene_desarrollo(d):
		var btn_unclaim = _crear_btn_opcion("🏳️ Unclaim", Color(0.6, 0.2, 0.2), false)
		btn_unclaim.tooltip_text = "Unclaim Territory"
		btn_unclaim.pressed.connect(func():
			d.reclamada = false
			actualizar_panel_pincel()
			actualizar_panel_construccion()
			actualizar_visibilidad_boton_externos()
			guardar_partida_actual()
			queue_redraw()
		)
		grid_carac.add_child(btn_unclaim)

	if hbox_favs:
		for child in hbox_favs.get_children(): child.queue_free()
		var path_felicidad = resolver_ruta_asset("Happiness B.")
		
		var btn_0 = _crear_btn_opcion("Normal", Color(0.5, 0.5, 0.5), f_actual == 0)
		btn_0.pressed.connect(func(): _marcar_favorita(0))
		hbox_favs.add_child(btn_0)
		
		var btn_1 = _crear_btn_opcion("", Color(0.56, 0.93, 0.56), f_actual == 1)
		if ResourceLoader.exists(path_felicidad):
			btn_1.icon = load(path_felicidad)
			btn_1.expand_icon = true
			btn_1.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		else:
			btn_1.text = "+1"
		btn_1.pressed.connect(func(): _marcar_favorita(1))
		hbox_favs.add_child(btn_1)
		
		var btn_2 = _crear_btn_opcion("", Color(0.13, 0.54, 0.13), f_actual == 2)
		if ResourceLoader.exists(path_felicidad):
			var hb = HBoxContainer.new()
			hb.set_anchors_preset(Control.PRESET_FULL_RECT)
			hb.alignment = BoxContainer.ALIGNMENT_CENTER
			hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var tex = load(path_felicidad)
			for i in range(2):
				var tex_rect_icon = TextureRect.new()
				tex_rect_icon.texture = tex
				tex_rect_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tex_rect_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				tex_rect_icon.custom_minimum_size = Vector2(24, 24)
				tex_rect_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
				hb.add_child(tex_rect_icon)
			btn_2.add_child(hb)
		else:
			btn_2.text = "+2"
		btn_2.pressed.connect(func(): _marcar_favorita(2))
		hbox_favs.add_child(btn_2)

		# ==============================================================================
		# DESPLEGABLE MARAVILLAS NATURALES
		# ==============================================================================
		var parent_container = grid_carac.get_parent()
		if parent_container:
			var old_nw = parent_container.get_node_or_null("NW_Container")
			if old_nw:
				old_nw.name = "ToDelete"
				old_nw.queue_free()

			if c_actual == "NATURAL_WONDER":
				var vbox_nw = VBoxContainer.new()
				vbox_nw.name = "NW_Container"
				vbox_nw.add_theme_constant_override("separation", 6)
				
				vbox_nw.add_child(HSeparator.new())
				
				var lbl_nw = Label.new()
				lbl_nw.text = "SELECT NATURAL WONDER"
				lbl_nw.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lbl_nw.add_theme_font_size_override("font_size", 14)
				lbl_nw.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
				vbox_nw.add_child(lbl_nw)
				
				var opt_nw = OptionButton.new()
				opt_nw.custom_minimum_size = Vector2(0, 32)
				
				var nw_validas = []
				if "MARAVILLAS_NATURALES" in Constantes:
					for nw_name in Constantes.MARAVILLAS_NATURALES.keys():
						var data_nw = Constantes.MARAVILLAS_NATURALES[nw_name]
						var b_ok = data_nw.get("biomas", []).is_empty() or b_actual in data_nw.get("biomas", [])
						var t_ok = data_nw.get("terrenos", []).is_empty() or t_actual in data_nw.get("terrenos", [])
						if b_ok and t_ok:
							nw_validas.append(nw_name)
							
				if nw_validas.size() > 0:
					for nw in nw_validas:
						opt_nw.add_item(nw)
					
					# Guardamos el recurso internamente para mantener la maravilla
					var current_nw = d.get("recurso", "")
					var found = false
					for i in range(opt_nw.item_count):
						if opt_nw.get_item_text(i) == current_nw:
							opt_nw.select(i)
							found = true
							break
					
					if not found:
						opt_nw.select(0)
						d["recurso"] = opt_nw.get_item_text(0)
						
					opt_nw.item_selected.connect(func(idx):
						d["recurso"] = opt_nw.get_item_text(idx)
						queue_redraw()
					)
				else:
					opt_nw.add_item("No valid wonders")
					opt_nw.disabled = true
					
				vbox_nw.add_child(opt_nw)
				parent_container.add_child(vbox_nw)
				# Mover el contenedor al final del panel
				parent_container.move_child(vbox_nw, -1)


func es_mejora_valida(coord: Vector2i, mejora_nombre: String, asent_centro: Vector2i, city_grid: Dictionary, era_actual: String = "Antiquity", civ_actual: String = "None", tipo_asentamiento: String = "Town") -> bool:
	if not city_grid.has(coord): return false
	if city_grid[coord].get("ajeno", false): return false
	if HexMath.dist_hex(coord, asent_centro) > 3: return false
	
	var datos = city_grid[coord]
	
	# ==============================================================================
	# RESTRICCIÓN ESTRICTA DE CONSTRUCCIÓN: MARAVILLAS NATURALES
	# ==============================================================================
	var es_maravilla_natural = (datos.get("caracteristica", "") == "NATURAL_WONDER" or datos.get("terreno", "") == "NATURAL_WONDER")
	
	if es_maravilla_natural:
		if mejora_nombre != "Expedition Base":
			return false
	else:
		if mejora_nombre == "Expedition Base":
			return false
	# ==============================================================================
	
	var t = datos.get("terreno", "").strip_edges().to_upper()
	
	# EXCEPCIÓN AL BLOQUEO DE MONTAÑAS:
	# Si estamos en Antiquity y es montaña, se bloquea todo...
	# EXCEPTO si la montaña es en realidad una Maravilla Natural.
	if era_actual == "Antiquity" and t in ["MOUNTAINOUS", "MONTAÑA"]:
		if not es_maravilla_natural:
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

func _crear_cabecera_panel(texto: String, asset_name: String) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	
	var tex_path = resolver_ruta_asset(asset_name)
	
	var tex_izq = TextureRect.new()
	tex_izq.custom_minimum_size = Vector2(24, 24)
	tex_izq.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_izq.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(tex_path):
		tex_izq.texture = load(tex_path)
		
	var tex_der = tex_izq.duplicate()
	
	var lbl = Label.new()
	lbl.text = texto
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
	
	hbox.add_child(tex_izq)
	hbox.add_child(lbl)
	hbox.add_child(tex_der)
	
	return hbox

func actualizar_panel_construccion():
	if grid_genericos: grid_genericos.visible = false
	if grid_mejoras: grid_mejoras.visible = false
	if grid_edificios: grid_edificios.visible = false
	if grid_maravillas: grid_maravillas.visible = false
	if lbl_header_genericos: lbl_header_genericos.visible = false
	if lbl_header_mejoras: lbl_header_mejoras.visible = false
	if lbl_header_edificios: lbl_header_edificios.visible = false
	if lbl_header_maravillas: lbl_header_maravillas.visible = false
	if contenedor_borrar_edificios: contenedor_borrar_edificios.visible = false

	var scroll_dinamico = panel_construccion.get_node_or_null("ConstruccionDinamico")
	if not scroll_dinamico:
		scroll_dinamico = ScrollContainer.new()
		scroll_dinamico.name = "ConstruccionDinamico"
		scroll_dinamico.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll_dinamico.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel_construccion.add_child(scroll_dinamico)
		
	for child in panel_construccion.get_children():
		if child != scroll_dinamico:
			child.visible = false
		
	var vbox = scroll_dinamico.get_node_or_null("VBoxConstruccionDinamico")
	if not vbox:
		vbox = VBoxContainer.new()
		vbox.name = "VBoxConstruccionDinamico"
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_theme_constant_override("separation", 16)
		scroll_dinamico.add_child(vbox)
		
	for child in vbox.get_children(): child.queue_free()
		
	if not city_grid.has(celda_seleccionada): return
	var datos_c = city_grid[celda_seleccionada]

	if asentamientos.size() == 0 or asentamiento_activo_idx >= asentamientos.size(): return
	var asent_centro = asentamientos[asentamiento_activo_idx].centro
	var asent_tipo = asentamientos[asentamiento_activo_idx].tipo

	var is_reclamada = datos_c.get("reclamada", false)
	
	if not is_reclamada:
		var btn_claim = Button.new()
		btn_claim.text = "🚩 CLAIM TERRITORY"
		btn_claim.custom_minimum_size = Vector2(0, 50)
		var sb_claim = StyleBoxFlat.new()
		sb_claim.bg_color = Color(0.2, 0.6, 0.2)
		sb_claim.set_corner_radius_all(8)
		btn_claim.add_theme_stylebox_override("normal", sb_claim)
		btn_claim.pressed.connect(func():
			datos_c["reclamada"] = true
			actualizar_panel_construccion()
			actualizar_panel_pincel()
			actualizar_visibilidad_boton_externos()
			guardar_partida_actual()
			queue_redraw()
		)
		vbox.add_child(btn_claim)
		return 

	var recurso_celda = datos_c.get("recurso", "")
	var ajeno = datos_c.get("ajeno", false)
	var tiene_maravilla = false
	var es_hielo = datos_c.get("caracteristica", "") == "ICE"
	
	for e in datos_c.edificios:
		if Constantes.DATOS_EDIFICIOS.get(e, {}).get("is_wonder", false):
			tiene_maravilla = true
			break

	# El panel de construcción normal bloquea el uso si la celda es ajena
	if not ajeno and not tiene_maravilla and not es_hielo:
		var es_centro_gob = datos_c.edificios.has("Palace") or datos_c.edificios.has("Town Hall")
		var mejora_actual = datos_c.get("mejora_tipo", "")
		
		if datos_c.edificios.size() == 0 and not es_centro_gob:
			var lista_mejoras_validas = []
			for mej_nombre in Constantes.DATOS_MEJORAS.keys():
				var d_mej = Constantes.DATOS_MEJORAS[mej_nombre]
				
				if d_mej.has("civ") and d_mej.civ != civ_actual and d_mej.civ != civ_sincretismo: continue
				var era_mej = d_mej.get("era", "Antiquity")
				if Constantes.ORDEN_ERAS.get(era_mej, 0) > Constantes.ORDEN_ERAS.get(era_actual, 0): continue
				
				if mejora_actual != "" and mej_nombre not in ["Abattoir", "Obshchina"]: continue
				if mejora_actual == "" and mej_nombre in ["Abattoir", "Obshchina"]: continue
				
				if recurso_celda != "":
					if not es_mejora_compatible_con_recurso(mej_nombre, recurso_celda, era_actual): continue
				
				if ReglasJuego.es_mejora_valida(celda_seleccionada, mej_nombre, asent_centro, city_grid, era_actual, civ_actual, asent_tipo):
					lista_mejoras_validas.append(mej_nombre)
					
			if lista_mejoras_validas.size() > 0:
				vbox.add_child(_crear_cabecera_panel("IMPROVEMENTS", "improvements"))
				var grid_mej = GridContainer.new()
				grid_mej.columns = 5
				grid_mej.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				grid_mej.add_theme_constant_override("h_separation", 6)
				grid_mej.add_theme_constant_override("v_separation", 6)
				for mej_nombre in lista_mejoras_validas:
					var tipo_rend = Constantes.DATOS_MEJORAS[mej_nombre].tipo
					var color_borde = Constantes.obtener_color_rendimiento(tipo_rend.split(" ")[0])
					var btn_vb = crear_boton_icono(mej_nombre, "ROUNDED", color_borde, obtener_tooltip_mejora(mej_nombre), mej_nombre, "CONSTRUCCION", true)
					grid_mej.add_child(btn_vb)
				vbox.add_child(grid_mej)

		if recurso_celda == "":
			var edificios_construidos = {}
			for c in city_grid.values():
				for e in c.edificios:
					if not ReglasJuego.es_edificio_obsoleto(e, c.q * Vector2i.RIGHT + c.r * Vector2i.DOWN, era_actual, city_grid): edificios_construidos[e] = true
					
			var rendimientos_validos = {}
			var maravillas_validas = false
			
			for edif_nombre in Constantes.DATOS_EDIFICIOS.keys():
				var d = Constantes.DATOS_EDIFICIOS[edif_nombre]
				if d.get("is_generic", false) or edif_nombre in ["Palace", "Town Hall"]: continue
				
				var era_edif = d.get("era", "All")
				if era_edif != "All" and Constantes.ORDEN_ERAS.get(era_edif, 0) > Constantes.ORDEN_ERAS.get(era_actual, 0): continue
				if d.has("civ") and d.civ != civ_actual and d.civ != civ_sincretismo: continue
				
				var es_muralla = ReglasJuego.es_edificio_muralla(edif_nombre)
				if edificios_construidos.has(edif_nombre) and not d.get("is_wonder", false) and not es_muralla: continue
				if edif_nombre in datos_c.edificios: continue
				
				if not ReglasJuego.es_ubicacion_valida_para_edificio(celda_seleccionada, edif_nombre, asent_centro, era_actual, civ_actual, city_grid, asent_tipo, asentamientos): continue
				if datos_c.terreno == "NATURAL_WONDER" or datos_c.get("caracteristica", "") == "NATURAL_WONDER": continue
				
				if not es_muralla:
					var reg_count = 0
					var is_full_tile = d.get("full_tile", false) or edif_nombre in ["Aerodrome", "Rail Station"]
					for e in datos_c.edificios:
						if not ReglasJuego.es_edificio_muralla(e) and not ReglasJuego.es_edificio_obsoleto(e, celda_seleccionada, era_actual, city_grid): reg_count += 1
					if reg_count >= 2 and not is_full_tile: continue
					
				if d.get("is_wonder", false): maravillas_validas = true
				else:
					var rend_principal = d.get("rendimiento", "")
					if rend_principal != "": rendimientos_validos[rend_principal] = true
					var rend_secundario = d.get("rendimiento_secundario", "")
					if rend_secundario != "": rendimientos_validos[rend_secundario] = true
					
			var lista_candidatos = []
			var lista_genericos = []
			
			for edif_nombre in Constantes.DATOS_EDIFICIOS.keys():
				var d = Constantes.DATOS_EDIFICIOS[edif_nombre]
				if edif_nombre in ["Palace", "Town Hall"]: continue
				
				var is_wonder = d.get("is_wonder", false)
				var is_generic = d.get("is_generic", false)
				var es_muralla = ReglasJuego.es_edificio_muralla(edif_nombre)
				
				if is_generic:
					var era_edif = d.get("era", "All")
					if era_edif != "All" and Constantes.ORDEN_ERAS.get(era_edif, 0) > Constantes.ORDEN_ERAS.get(era_actual, 0): continue
					if d.has("civ") and d.civ != civ_actual and d.civ != civ_sincretismo: continue
					if is_wonder and not maravillas_validas: continue
					lista_genericos.append({"nombre": edif_nombre, "ady": 0, "d": d, "wonder": is_wonder, "generic": true})
				else:
					var era_edif = d.get("era", "All")
					if era_edif != "All" and Constantes.ORDEN_ERAS.get(era_edif, 0) > Constantes.ORDEN_ERAS.get(era_actual, 0): continue
					if d.has("civ") and d.civ != civ_actual and d.civ != civ_sincretismo: continue
					if edificios_construidos.has(edif_nombre) and not is_wonder and not es_muralla: continue
					if edif_nombre in datos_c.edificios: continue
					
					if not ReglasJuego.es_ubicacion_valida_para_edificio(celda_seleccionada, edif_nombre, asent_centro, era_actual, civ_actual, city_grid, asent_tipo, asentamientos): continue
					if datos_c.terreno == "NATURAL_WONDER" or datos_c.get("caracteristica", "") == "NATURAL_WONDER": continue
				
					if not es_muralla:
						var reg_count = 0
						var is_full_tile = d.get("full_tile", false) or edif_nombre in ["Aerodrome", "Rail Station"]
						for e in datos_c.edificios:
							if not ReglasJuego.es_edificio_muralla(e) and not ReglasJuego.es_edificio_obsoleto(e, celda_seleccionada, era_actual, city_grid): reg_count += 1
						if reg_count >= 2 and not is_full_tile: continue
						
				var ady = 0 if is_generic else ReglasJuego.calcular_bono_edificio(celda_seleccionada, edif_nombre, era_actual, city_grid)
				lista_candidatos.append({"nombre": edif_nombre, "ady": ady, "d": d, "wonder": is_wonder, "generic": is_generic})
				
			lista_candidatos.sort_custom(func(a, b): return a.ady > b.ady)
			
			var grid_edif_c = GridContainer.new()
			grid_edif_c.columns = 5
			grid_edif_c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			grid_edif_c.add_theme_constant_override("h_separation", 6)
			grid_edif_c.add_theme_constant_override("v_separation", 6)

			var grid_mar_c = GridContainer.new()
			grid_mar_c.columns = 5
			grid_mar_c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			grid_mar_c.add_theme_constant_override("h_separation", 6)
			grid_mar_c.add_theme_constant_override("v_separation", 6)

			for gen in lista_genericos:
				if gen.wonder:
					var color_borde = Constantes.obtener_color_rendimiento(gen.d.get("rendimiento", ""))
					var tt = obtener_tooltip_edificio(gen.nombre, 0)
					var btn_vb = crear_boton_icono(gen.nombre, "SQUARE", color_borde, tt, gen.nombre, "CONSTRUCCION", false, false)
					grid_mar_c.add_child(btn_vb)

			for cand in lista_candidatos:
				if cand.generic: continue
				var color_borde = Constantes.obtener_color_rendimiento(cand.d.get("rendimiento", ""))
				var tt = obtener_tooltip_edificio(cand.nombre, cand.ady)
				
				if cand.wonder:
					var btn_vb = crear_boton_icono(cand.nombre, "SQUARE", color_borde, tt, cand.nombre, "CONSTRUCCION", false)
					grid_mar_c.add_child(btn_vb)
				else:
					var btn_vb = crear_boton_icono(cand.nombre, "CIRCLE", color_borde, tt, cand.nombre, "CONSTRUCCION", false)
					grid_edif_c.add_child(btn_vb)

			for gen in lista_genericos:
				if not gen.wonder:
					var color_borde = Constantes.obtener_color_rendimiento(gen.d.get("rendimiento", ""))
					var tt = obtener_tooltip_edificio(gen.nombre, 0)
					var btn_vb = crear_boton_icono(gen.nombre, "CIRCLE", color_borde, tt, gen.nombre, "CONSTRUCCION", false, false)
					grid_edif_c.add_child(btn_vb)

			if grid_edif_c.get_child_count() > 0:
				vbox.add_child(_crear_cabecera_panel("BUILDINGS", "buildings"))
				vbox.add_child(grid_edif_c)
			if grid_mar_c.get_child_count() > 0:
				vbox.add_child(_crear_cabecera_panel("WONDERS", "wonder"))
				vbox.add_child(grid_mar_c)

func _añadir_boton_reclamar_ajeno(vbox_panel_externo: Node, datos_celda: Dictionary):
	if not datos_celda.get("ajeno", false):
		var btn_claim_ajeno = Button.new()
		btn_claim_ajeno.text = "🚩 CLAIM FOR EXTERNAL"
		btn_claim_ajeno.custom_minimum_size = Vector2(0, 44)
		var sb_ajeno = StyleBoxFlat.new()
		sb_ajeno.bg_color = Color(0.6, 0.2, 0.2)
		sb_ajeno.set_corner_radius_all(6)
		btn_claim_ajeno.add_theme_stylebox_override("normal", sb_ajeno)
		
		btn_claim_ajeno.pressed.connect(func():
			datos_celda["ajeno"] = true
			datos_celda["reclamada"] = true
			
			actualizar_panel_externos()
			actualizar_panel_construccion()
			actualizar_panel_ui()
			guardar_partida_actual()
			queue_redraw()
		)
		vbox_panel_externo.add_child(btn_claim_ajeno)
		vbox_panel_externo.add_child(HSeparator.new())
	else:
		var lbl_ajeno = Label.new()
		lbl_ajeno.text = "LOCKED: EXTERNAL USE"
		lbl_ajeno.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_ajeno.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
		vbox_panel_externo.add_child(lbl_ajeno)
		vbox_panel_externo.add_child(HSeparator.new())

func actualizar_panel_externos():
	if lbl_ext_edif: lbl_ext_edif.visible = false
	if lbl_ext_mej: lbl_ext_mej.visible = false
	if scroll_ext_edif: scroll_ext_edif.visible = false
	if scroll_ext_mej: scroll_ext_mej.visible = false
	if contenedor_edificios_externos: contenedor_edificios_externos.visible = false
	if contenedor_mejoras_externas: contenedor_mejoras_externas.visible = false
	
	if not city_grid.has(celda_seleccionada):
		if btn_del_ext: btn_del_ext.visible = false
		return
		
	var d = city_grid[celda_seleccionada]
	
	var scroll_dinamico = panel_externos.get_node_or_null("ExternosDinamico")
	if not scroll_dinamico:
		scroll_dinamico = ScrollContainer.new()
		scroll_dinamico.name = "ExternosDinamico"
		scroll_dinamico.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll_dinamico.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel_externos.add_child(scroll_dinamico)
		panel_externos.move_child(scroll_dinamico, 0)
		
	var vbox = scroll_dinamico.get_node_or_null("VBoxDinamico")
	if not vbox:
		vbox = VBoxContainer.new()
		vbox.name = "VBoxDinamico"
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_theme_constant_override("separation", 16)
		scroll_dinamico.add_child(vbox)
		
	for child in vbox.get_children(): child.queue_free()
	
	if asentamientos.size() == 0 or asentamiento_activo_idx >= asentamientos.size(): return
	var asent_centro = asentamientos[asentamiento_activo_idx].centro
	var asent_tipo = asentamientos[asentamiento_activo_idx].tipo
	var dist = HexMath.dist_hex(celda_seleccionada, asent_centro)
	var es_anillo_4 = (dist == 4)
	
	_añadir_boton_reclamar_ajeno(vbox, d)
	
	var tiene_mejora = d.get("mejora_tipo", "") != ""
	var tiene_wonder = false
	var tiene_edificio_normal = false
	
	for e in d.get("edificios", []):
		var edif_data = Constantes.DATOS_EDIFICIOS.get(e, {})
		if edif_data.get("is_wonder", false):
			tiene_wonder = true
		else:
			tiene_edificio_normal = true

	var tiene_algo_construido = d.get("ajeno", false) or tiene_mejora or d.get("edificios", []).size() > 0
	if tiene_algo_construido:
		var btn_borrar = Button.new()
		btn_borrar.text = "🗑️ Clear External"
		btn_borrar.custom_minimum_size = Vector2(160, 38)
		btn_borrar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var style_del = StyleBoxFlat.new()
		style_del.bg_color = Color(0.4, 0.15, 0.15)
		style_del.border_color = Color(0.8, 0.3, 0.3)
		style_del.set_border_width_all(1)
		style_del.set_corner_radius_all(6)
		btn_borrar.add_theme_stylebox_override("normal", style_del)
		btn_borrar.pressed.connect(func(): GestorConstruccion.borrar_externo(self))
		vbox.add_child(btn_borrar)
		
		var sep = HSeparator.new()
		vbox.add_child(sep)

	if btn_del_ext: btn_del_ext.visible = false

	if tiene_wonder:
		return

	var lista_mejoras = []
	var lista_edificios = []
	var lista_maravillas = []
	var recurso_celda = d.get("recurso", "")

	var permitir_mejoras = not tiene_edificio_normal
	var permitir_maravillas = not tiene_edificio_normal

	if permitir_mejoras:
		for mej_nombre in Constantes.DATOS_MEJORAS.keys():
			var d_mej = Constantes.DATOS_MEJORAS[mej_nombre]
			var era_mej = d_mej.get("era", "Antiquity")
			if Constantes.ORDEN_ERAS.get(era_mej, 0) > Constantes.ORDEN_ERAS.get(era_actual, 0): continue
			
			if d.get("mejora_tipo", "") == mej_nombre: continue
			
			if recurso_celda != "":
				if not es_mejora_compatible_con_recurso(mej_nombre, recurso_celda, era_actual): continue
					
			var mejora_valida = false
			if es_anillo_4:
				if d.terreno not in ["MOUNTAINOUS", "OCEAN"] and d.get("caracteristica", "") not in ["ICE", "NATURAL_WONDER"]:
					mejora_valida = true
			else:
				mejora_valida = ReglasJuego.es_mejora_valida(celda_seleccionada, mej_nombre, asent_centro, city_grid, era_actual, civ_actual, asent_tipo)
				
			if mejora_valida:
				lista_mejoras.append(mej_nombre)
				
	if recurso_celda == "":
		for edif_nombre in Constantes.DATOS_EDIFICIOS.keys():
			var d_edif = Constantes.DATOS_EDIFICIOS[edif_nombre]
			if edif_nombre in ["Palace", "Town Hall"]: continue
			if d_edif.get("is_generic", false): continue
			
			var era_edif = d_edif.get("era", "All")
			if era_edif != "All" and Constantes.ORDEN_ERAS.get(era_edif, 0) > Constantes.ORDEN_ERAS.get(era_actual, 0): continue
			
			if edif_nombre in d.get("edificios", []): continue
			
			var es_maravilla = d_edif.get("is_wonder", false)
			if es_maravilla and not permitir_maravillas: continue
			
			var edif_valido = false
			if es_anillo_4:
				if d.terreno not in ["MOUNTAINOUS", "OCEAN"] and d.get("caracteristica", "") not in ["ICE", "NATURAL_WONDER"]:
					edif_valido = true
			else:
				edif_valido = ReglasJuego.es_ubicacion_valida_para_edificio(celda_seleccionada, edif_nombre, asent_centro, era_actual, civ_actual, city_grid, asent_tipo, asentamientos)
				
			if not edif_valido: continue
			if d.terreno == "NATURAL_WONDER" or d.get("caracteristica", "") == "NATURAL_WONDER": continue
			
			if es_maravilla: 
				lista_maravillas.append({"nombre": edif_nombre, "d": d_edif})
			else: 
				lista_edificios.append({"nombre": edif_nombre, "d": d_edif})
			
	if lista_mejoras.size() > 0:
		vbox.add_child(_crear_cabecera_panel("IMPROVEMENTS", "improvements"))
		var grid_mej = GridContainer.new()
		grid_mej.columns = 5
		grid_mej.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		grid_mej.add_theme_constant_override("h_separation", 6)
		grid_mej.add_theme_constant_override("v_separation", 6)
		for mej_nombre in lista_mejoras:
			var tipo_rend = Constantes.DATOS_MEJORAS[mej_nombre].tipo
			var color_borde = Constantes.obtener_color_rendimiento(tipo_rend.split(" ")[0])
			var b_vb = crear_boton_icono(mej_nombre, "ROUNDED", color_borde, obtener_tooltip_mejora(mej_nombre), mej_nombre, "EXTERNOS", true)
			grid_mej.add_child(b_vb)
		vbox.add_child(grid_mej)
		
	if lista_edificios.size() > 0:
		vbox.add_child(_crear_cabecera_panel("BUILDINGS", "buildings"))
		var grid_edif = GridContainer.new()
		grid_edif.columns = 5
		grid_edif.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		grid_edif.add_theme_constant_override("h_separation", 6)
		grid_edif.add_theme_constant_override("v_separation", 6)
		for item in lista_edificios:
			var edif_nombre = item.nombre
			var color_borde = Constantes.obtener_color_rendimiento(item.d.get("rendimiento", ""))
			var b_vb = crear_boton_icono(edif_nombre, "CIRCLE", color_borde, obtener_tooltip_edificio(edif_nombre, 0), edif_nombre, "EXTERNOS", false)
			grid_edif.add_child(b_vb)
		vbox.add_child(grid_edif)
		
	if lista_maravillas.size() > 0:
		vbox.add_child(_crear_cabecera_panel("WONDERS", "wonder"))
		var grid_mar = GridContainer.new()
		grid_mar.columns = 5
		grid_mar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		grid_mar.add_theme_constant_override("h_separation", 6)
		grid_mar.add_theme_constant_override("v_separation", 6)
		for item in lista_maravillas:
			var edif_nombre = item.nombre
			var color_borde = Constantes.obtener_color_rendimiento(item.d.get("rendimiento", ""))
			var b_vb = crear_boton_icono(edif_nombre, "SQUARE", color_borde, obtener_tooltip_edificio(edif_nombre, 0), edif_nombre, "EXTERNOS", false)
			grid_mar.add_child(b_vb)
		vbox.add_child(grid_mar)

func cambiar_seccion(nueva_seccion: String):
	seccion_actual = nueva_seccion
	if panel_biomas: panel_biomas.visible = (nueva_seccion == "PINCEL")
	if panel_construccion: panel_construccion.visible = (nueva_seccion == "CONSTRUCCION")
	if panel_externos: panel_externos.visible = (nueva_seccion == "EXTERNOS")
	if panel_asentamientos_ui: panel_asentamientos_ui.visible = (nueva_seccion == "ASENTAMIENTOS")
	if panel_maravillas: panel_maravillas.visible = (nueva_seccion == "MARAVILLAS")
	
	var mostrar_info = (nueva_seccion != "ASENTAMIENTOS" and nueva_seccion != "EXTERNOS")
	if panel_info: panel_info.visible = mostrar_info

	if lbl_info:
		lbl_info.visible = mostrar_info
		var padre = lbl_info.get_parent()
		if padre:
			var dyn_node = padre.get_node_or_null("ContenedorInfoDinamico")
			if dyn_node: dyn_node.visible = mostrar_info

	if btn_menu_asentamientos: btn_menu_asentamientos.modulate = Color(1.3, 1.3, 1.3) if seccion_actual == "ASENTAMIENTOS" else Color(0.7, 0.7, 0.7)
	if btn_menu_pincel: btn_menu_pincel.modulate = Color(1.3, 1.3, 1.3) if seccion_actual == "PINCEL" else Color(0.7, 0.7, 0.7)
	if btn_modo_construccion: btn_modo_construccion.modulate = Color(1.3, 1.3, 1.3) if seccion_actual == "CONSTRUCCION" else Color(0.7, 0.7, 0.7)
	if btn_modo_externos: btn_modo_externos.modulate = Color(1.3, 1.3, 1.3) if seccion_actual == "EXTERNOS" else Color(0.7, 0.7, 0.7)
	if btn_menu_maravillas:
		var es_wonder = city_grid.has(celda_seleccionada) and city_grid[celda_seleccionada].get("caracteristica", "") == "NATURAL_WONDER"
		btn_menu_maravillas.visible = es_wonder
		if es_wonder:
			btn_menu_maravillas.modulate = Color(1.3, 1.3, 1.3) if seccion_actual == "MARAVILLAS" else Color(0.7, 0.7, 0.7)

	if seccion_actual == "PINCEL": actualizar_panel_pincel()
	elif seccion_actual == "MARAVILLAS": actualizar_panel_maravillas_naturales()
	elif seccion_actual == "CONSTRUCCION":
		actualizar_sugerencias_cache()
		actualizar_panel_construccion()
		actualizar_iconos_todos()
	elif seccion_actual == "EXTERNOS": actualizar_panel_externos()
	elif seccion_actual == "ASENTAMIENTOS": actualizar_panel_gestion_ui()

	actualizar_iconos_todos()
	actualizar_visibilidad_boton_externos()
	actualizar_panel_ui()
	centrar_camara_en_activo()
	queue_redraw()

func actualizar_panel_ui():
	if not lbl_info: return
	if not city_grid.has(celda_seleccionada): return
	var d = city_grid[celda_seleccionada]
	var es_pincel = (seccion_actual == "PINCEL")
	
	var parent = lbl_info.get_parent()
	var dyn_node = parent.get_node_or_null("ContenedorInfoDinamico")
	if not dyn_node:
		dyn_node = VBoxContainer.new()
		dyn_node.name = "ContenedorInfoDinamico"
		dyn_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dyn_node.add_theme_constant_override("separation", 10)
		parent.add_child(dyn_node)
		
	lbl_info.visible = false
	for c in dyn_node.get_children(): c.queue_free()
	
	var appeal_val = d.get("favorita", 0)
	if appeal_val > 0:
		var hbox_appeal = HBoxContainer.new()
		hbox_appeal.alignment = BoxContainer.ALIGNMENT_END
		var path_hap = resolver_ruta_asset("Happiness B.")
		if ResourceLoader.exists(path_hap):
			for i in range(appeal_val):
				var tex_rect = TextureRect.new()
				tex_rect.texture = load(path_hap)
				tex_rect.custom_minimum_size = Vector2(24, 24)
				tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				hbox_appeal.add_child(tex_rect)
		dyn_node.add_child(hbox_appeal)
		
	var asent_centro = asentamientos[asentamiento_activo_idx].centro if (asentamientos.size() > 0 and asentamiento_activo_idx < asentamientos.size()) else Vector2i.ZERO
	var es_reclamada = d.get("reclamada", HexMath.dist_hex(celda_seleccionada, asent_centro) <= 1)
	
	if es_reclamada or d.get("ajeno", false):
		var ter_desc = d.terreno.to_lower().capitalize()
		if ter_desc == "Flat": ter_desc = ""
		var carac = d.get("caracteristica", "NONE")
		var carac_desc = "" if carac == "NONE" else carac.to_lower().capitalize()
		
		var combinada = d.bioma.to_upper()
		if ter_desc != "": combinada += " " + ter_desc.to_upper()
		if carac_desc != "": combinada += " " + carac_desc.to_upper()
		if d.get("rio", false): combinada += " MINOR RIVER"
	
		var hbox_ter = HBoxContainer.new()
		hbox_ter.add_theme_constant_override("separation", 6)
		
		if es_reclamada:
			var panel_claim = PanelContainer.new()
			var sb_claim = StyleBoxFlat.new()
			sb_claim.bg_color = Color.WHITE
			sb_claim.set_corner_radius_all(4)
			panel_claim.add_theme_stylebox_override("panel", sb_claim)
			var lbl_claim = Label.new()
			lbl_claim.text = " 🏴 "
			lbl_claim.add_theme_color_override("font_color", Color.BLACK)
			lbl_claim.add_theme_font_size_override("font_size", 14)
			panel_claim.add_child(lbl_claim)
			hbox_ter.add_child(panel_claim)
			
		var panel_ter = PanelContainer.new()
		var sb_ter = StyleBoxFlat.new()
		sb_ter.bg_color = Constantes.COLORES_BIOMA.get(d.bioma, Color(0.5, 0.5, 0.5))
		sb_ter.set_corner_radius_all(4)
		panel_ter.add_theme_stylebox_override("panel", sb_ter)
		var lbl_ter = Label.new()
		lbl_ter.text = " " + combinada + " "
		lbl_ter.add_theme_color_override("font_color", Color.BLACK)
		lbl_ter.add_theme_font_size_override("font_size", 14)
		panel_ter.add_child(lbl_ter)
		hbox_ter.add_child(panel_ter)
		
		var es_urbano = _es_celda_urbana(celda_seleccionada)
		var tipo_celda_str = "URBAN" if es_urbano else "RURAL"
		var color_fondo_tipo = Color(0.2, 0.4, 0.8) if es_urbano else Color(0.85, 0.2, 0.2)
		
		var panel_tipo = PanelContainer.new()
		var sb_tipo = StyleBoxFlat.new()
		sb_tipo.bg_color = color_fondo_tipo
		sb_tipo.set_corner_radius_all(4)
		panel_tipo.add_theme_stylebox_override("panel", sb_tipo)
		var lbl_tipo = Label.new()
		lbl_tipo.text = " " + tipo_celda_str + " "
		lbl_tipo.add_theme_color_override("font_color", Color.WHITE)
		lbl_tipo.add_theme_font_size_override("font_size", 14)
		panel_tipo.add_child(lbl_tipo)
		hbox_ter.add_child(panel_tipo)
		dyn_node.add_child(hbox_ter)
	
	var r_yield = ReglasJuego.calcular_rendimiento_celda(d.bioma, d.terreno, d.get("caracteristica", "NONE"), d.get("recurso", ""), d.get("rio", false), era_actual)
	var yields_sum = {
		"Food": r_yield.get("Food", 0), "Production": r_yield.get("Production", 0), 
		"Gold": r_yield.get("Gold", 0), "Culture": r_yield.get("Culture", 0), 
		"Science": r_yield.get("Science", 0), "Happiness": r_yield.get("Happiness", 0), 
		"Influence": r_yield.get("Influence", 0)
	}
	
	var era_mult = obtener_multiplicador_era()
	var l_bonos_lista = Constantes.DATOS_LIDERES.get(lider_actual, {}).get("bonos", [])
	
	if not es_pincel:
		for edif in d.edificios:
			if edif == "Palace":
				yields_sum["Food"] += 5 * era_mult
				yields_sum["Production"] += 5 * era_mult
				if asentamiento_tiene_agua_dulce(celda_seleccionada):
					yields_sum["Happiness"] += 5 * era_mult
					
				var adj_palacio = calcular_adyacencia_palacio(celda_seleccionada)
				yields_sum["Science"] += adj_palacio["Science"] * era_mult
				yields_sum["Culture"] += adj_palacio["Culture"] * era_mult
				
			elif edif == "Town Hall":
				yields_sum["Food"] += 3 * era_mult
				yields_sum["Production"] += 3 * era_mult
				
				var asent_t = "Town"
				for asent in asentamientos:
					if asent.grid.has(celda_seleccionada) or asent.centro == celda_seleccionada:
						asent_t = asent.tipo
						break
				if (asent_t == "City" or asent_t == "Capital") and asentamiento_tiene_agua_dulce(celda_seleccionada):
					yields_sum["Happiness"] += 3 * era_mult
			
			elif Constantes.DATOS_EDIFICIOS.has(edif) and not ReglasJuego.es_edificio_obsoleto(edif, celda_seleccionada, era_actual, city_grid):
				var datos_edif = Constantes.DATOS_EDIFICIOS[edif]
				var rend = datos_edif.get("rendimiento", "")
				var base = datos_edif.get("base", 0)
				var ady = ReglasJuego.calcular_bono_edificio(celda_seleccionada, edif, era_actual, city_grid) if not datos_edif.get("is_generic", false) else 0
				
				var is_unique = datos_edif.has("civ")
				if "building_mountain_adj" in l_bonos_lista:
					var m_count = 0
					for vec in HexMath.VECINOS_HEX:
						var ac = celda_seleccionada + vec
						if city_grid.has(ac) and city_grid[ac].terreno.to_upper() in ["MOUNTAINOUS", "MONTAÑA"]: m_count += 1
					if yields_sum.has("Food"): yields_sum["Food"] += m_count
				if "military_science_wall_adj" in l_bonos_lista and rend in ["Science", "Influence"]:
					var w_count = 0
					for vec in HexMath.VECINOS_HEX:
						var ac = celda_seleccionada + vec
						if city_grid.has(ac):
							for e in city_grid[ac].edificios:
								if ReglasJuego.es_edificio_muralla(e): w_count += 1
					if yields_sum.has("Happiness"): yields_sum["Happiness"] += w_count
				if "happy_building_improvement_adj" in l_bonos_lista and (rend in ["Food", "Happiness"] or is_unique):
					var imp_count = 0
					for vec in HexMath.VECINOS_HEX:
						var ac = celda_seleccionada + vec
						if city_grid.has(ac) and city_grid[ac].get("mejora_tipo", "") != "": imp_count += 1
					if yields_sum.has("Happiness"): yields_sum["Happiness"] += imp_count
				if "science_on_prod_science_bldgs" in l_bonos_lista and rend in ["Production", "Science"]:
					if yields_sum.has("Science"): yields_sum["Science"] += 1 * era_mult
				if "happiness_on_dip_bldgs" in l_bonos_lista and rend in ["Happiness", "Influence"]:
					if yields_sum.has("Happiness"): yields_sum["Happiness"] += 2 * era_mult
				if "yields_on_uniques" in l_bonos_lista and is_unique:
					if yields_sum.has("Culture"): yields_sum["Culture"] += 1 * era_mult
					if yields_sum.has("Gold"): yields_sum["Gold"] += 1 * era_mult

				if yields_sum.has(rend): yields_sum[rend] += base + ady
				
			elif Constantes.MARAVILLAS_NATURALES.has(edif):
				var w_data = Constantes.MARAVILLAS_NATURALES[edif]
				var w_yields = w_data.get("yields", {})
				for wk in w_yields.keys():
					if yields_sum.has(wk): yields_sum[wk] += w_yields[wk]
		
		if d.get("mejora_tipo", "") != "":
			var d_mej = Constantes.DATOS_MEJORAS.get(d.mejora_tipo, {})
			if "yields_on_uniques" in l_bonos_lista and d_mej.has("civ"):
				if yields_sum.has("Culture"): yields_sum["Culture"] += 1 * era_mult
				if yields_sum.has("Gold"): yields_sum["Gold"] += 1 * era_mult
				
		if "gold_per_resource" in l_bonos_lista and d.get("recurso", "") != "" and d.get("mejora_tipo", "") != "":
			if yields_sum.has("Gold"): yields_sum["Gold"] += 1 * era_mult
			
		if "natural_wonder_boost" in l_bonos_lista and (d.get("caracteristica", "") == "NATURAL_WONDER" or d.terreno == "NATURAL_WONDER"):
			var nw_count = 0
			for cell in city_grid.values():
				if cell.get("caracteristica", "") == "NATURAL_WONDER" or cell.terreno == "NATURAL_WONDER": nw_count += 1
			for k in yields_sum.keys():
				if yields_sum[k] > 0: yields_sum[k] += int(yields_sum[k] * 0.5 * nw_count)

	# --- CAJA DE RENDIMIENTOS GENERALES DE LA CELDA ---
	var panel_y = PanelContainer.new()
	var sb_y = StyleBoxFlat.new()
	sb_y.bg_color = Color(0.12, 0.12, 0.15)
	sb_y.border_color = Color(0.4, 0.4, 0.45)
	sb_y.set_border_width_all(2)
	sb_y.set_corner_radius_all(6)
	panel_y.add_theme_stylebox_override("panel", sb_y)
	
	var margin_y = MarginContainer.new()
	margin_y.add_theme_constant_override("margin_top", 4)
	margin_y.add_theme_constant_override("margin_bottom", 4)
	margin_y.add_theme_constant_override("margin_left", 8)
	margin_y.add_theme_constant_override("margin_right", 8)
	
	var hbox_y = HBoxContainer.new()
	hbox_y.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_y.add_theme_constant_override("separation", 10)
	
	var has_yield = false
	for k in ["Food", "Production", "Gold", "Culture", "Science", "Happiness", "Influence"]:
		if yields_sum[k] > 0 or yields_sum[k] < 0:
			has_yield = true
			var hb_i = HBoxContainer.new()
			hb_i.alignment = BoxContainer.ALIGNMENT_CENTER
			hb_i.add_theme_constant_override("separation", 2)
			var lbl_val = Label.new()
			lbl_val.text = str(yields_sum[k])
			lbl_val.add_theme_font_size_override("font_size", 14)
			hb_i.add_child(lbl_val)
			var path_icon = resolver_ruta_asset(obtener_nombre_asset_rendimiento(k))
			if ResourceLoader.exists(path_icon):
				var tex_rect = TextureRect.new()
				tex_rect.texture = load(path_icon)
				tex_rect.custom_minimum_size = Vector2(18, 18)
				tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				hb_i.add_child(tex_rect)
			hbox_y.add_child(hb_i)
			
	if not has_yield:
		var lbl_0 = Label.new()
		lbl_0.text = "0"
		hbox_y.add_child(lbl_0)
		
	margin_y.add_child(hbox_y)
	panel_y.add_child(margin_y)
	dyn_node.add_child(panel_y)
	
	var vbox_bldgs = VBoxContainer.new()
	vbox_bldgs.add_theme_constant_override("separation", 8)
	
	var crear_boton_borrar_estilizado = func(accion_conexion: Callable) -> Button:
		var btn = Button.new()
		btn.text = "×"
		btn.tooltip_text = "Remove"
		btn.custom_minimum_size = Vector2(26, 26)
		btn.add_theme_font_size_override("font_size", 16)
		btn.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.5, 0.5))
		var sb_del = StyleBoxFlat.new()
		sb_del.bg_color = Color(0.2, 0.12, 0.12)
		sb_del.border_color = Color(0.5, 0.2, 0.2)
		sb_del.set_border_width_all(1)
		sb_del.set_corner_radius_all(6)
		btn.add_theme_stylebox_override("normal", sb_del)
		var sb_del_hover = sb_del.duplicate()
		sb_del_hover.bg_color = Color(0.35, 0.15, 0.15)
		btn.add_theme_stylebox_override("hover", sb_del_hover)
		btn.pressed.connect(accion_conexion)
		return btn
	
	# --- IMPLEMENTACIÓN VISUAL POR EDIFICIO ---
	for edif in d.edificios:
		var is_obsolete = ReglasJuego.es_edificio_obsoleto(edif, celda_seleccionada, era_actual, city_grid)
		
		var panel_bldg = PanelContainer.new()
		var sb_bldg = StyleBoxFlat.new()
		sb_bldg.bg_color = Color(0.15, 0.15, 0.18)
		if is_obsolete:
			sb_bldg.bg_color = Color(0.2, 0.2, 0.2)
			sb_bldg.border_color = Color(0.4, 0.4, 0.4)
			sb_bldg.set_border_width_all(1)
		sb_bldg.set_corner_radius_all(6)
		panel_bldg.add_theme_stylebox_override("panel", sb_bldg)
		
		var margin_bldg = MarginContainer.new()
		margin_bldg.add_theme_constant_override("margin_left", 8)
		margin_bldg.add_theme_constant_override("margin_right", 8)
		margin_bldg.add_theme_constant_override("margin_top", 6)
		margin_bldg.add_theme_constant_override("margin_bottom", 6)
		
		var hbox_bldg_main = HBoxContainer.new()
		hbox_bldg_main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var hbox_left = HBoxContainer.new()
		hbox_left.alignment = BoxContainer.ALIGNMENT_BEGIN
		hbox_left.add_theme_constant_override("separation", 8)
		
		if edif not in ["Palace", "Town Hall"]:
			var edif_c = edif
			var btn_del = crear_boton_borrar_estilizado.call(func(): _borrar_edificio_especifico(edif_c))
			hbox_left.add_child(btn_del)
		else:
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(26, 0)
			hbox_left.add_child(spacer)
			
		var asset_name = edif
		if ReglasJuego.es_edificio_muralla(edif): asset_name = edif
		elif edif == "Marvel" or Constantes.DATOS_EDIFICIOS.get(edif, {}).get("is_wonder", false):
			asset_name = "wonder" if not ResourceLoader.exists(resolver_ruta_asset(asset_name)) else edif
		
		var tex_path = resolver_ruta_asset(asset_name)
		if ResourceLoader.exists(tex_path):
			var tex_rect = TextureRect.new()
			tex_rect.texture = load(tex_path)
			tex_rect.custom_minimum_size = Vector2(24, 24)
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hbox_left.add_child(tex_rect)
			
		var lbl_name = Label.new()
		var nom_text = edif.to_upper()
		if is_obsolete: nom_text += " (OBSOLETE)"
		lbl_name.text = nom_text
		if is_obsolete: lbl_name.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
		lbl_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox_left.add_child(lbl_name)
		
		hbox_bldg_main.add_child(hbox_left)
		
		var spacer_mid = Control.new()
		spacer_mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox_bldg_main.add_child(spacer_mid)
		
		var hbox_yields = HBoxContainer.new()
		hbox_yields.alignment = BoxContainer.ALIGNMENT_END
		hbox_yields.add_theme_constant_override("separation", 6)
		
		if not es_pincel:
			var e_yields = {}
			if Constantes.MARAVILLAS_NATURALES.has(edif):
				e_yields = Constantes.MARAVILLAS_NATURALES[edif].get("yields", {}).duplicate()
			elif edif == "Palace":
				e_yields["Food"] = 5 * era_mult
				e_yields["Production"] = 5 * era_mult
				if asentamiento_tiene_agua_dulce(celda_seleccionada): e_yields["Happiness"] = 5 * era_mult
				var adj_palacio = calcular_adyacencia_palacio(celda_seleccionada)
				if adj_palacio["Science"] > 0: e_yields["Science"] = adj_palacio["Science"] * era_mult
				if adj_palacio["Culture"] > 0: e_yields["Culture"] = adj_palacio["Culture"] * era_mult
			elif edif == "Town Hall":
				e_yields["Food"] = 3 * era_mult
				e_yields["Production"] = 3 * era_mult
				var asent_t = "Town"
				for asent in asentamientos:
					if asent.grid.has(celda_seleccionada) or asent.centro == celda_seleccionada:
						asent_t = asent.tipo
						break
				if (asent_t == "City" or asent_t == "Capital") and asentamiento_tiene_agua_dulce(celda_seleccionada):
					e_yields["Happiness"] = 3 * era_mult
			elif not ReglasJuego.es_edificio_muralla(edif):
				var d_e = Constantes.DATOS_EDIFICIOS.get(edif, {})
				var b_base = d_e.get("base", 0)
				var b_ady = ReglasJuego.calcular_bono_edificio(celda_seleccionada, edif, era_actual, city_grid) if not d_e.get("is_generic", false) else 0
				var total_e = b_base + b_ady
				if total_e > 0:
					e_yields[d_e.get("rendimiento", "")] = total_e
					
			for k in e_yields.keys():
				if e_yields[k] > 0:
					var p_panel = PanelContainer.new()
					var p_sb = StyleBoxFlat.new()
					p_sb.bg_color = Color(0.12, 0.12, 0.15)
					p_sb.border_color = Color(0.4, 0.4, 0.45)
					p_sb.set_border_width_all(2)
					p_sb.set_corner_radius_all(6)
					p_panel.add_theme_stylebox_override("panel", p_sb)
					
					var p_mar = MarginContainer.new()
					p_mar.add_theme_constant_override("margin_left", 6)
					p_mar.add_theme_constant_override("margin_right", 6)
					p_mar.add_theme_constant_override("margin_top", 2)
					p_mar.add_theme_constant_override("margin_bottom", 2)
					
					var p_hb = HBoxContainer.new()
					p_hb.alignment = BoxContainer.ALIGNMENT_CENTER
					p_hb.add_theme_constant_override("separation", 4)
					
					var l_val = Label.new()
					l_val.text = str(e_yields[k])
					l_val.add_theme_font_size_override("font_size", 13)
					p_hb.add_child(l_val)
					
					var path_icon = resolver_ruta_asset(obtener_nombre_asset_rendimiento(k))
					if ResourceLoader.exists(path_icon):
						var t_icon = TextureRect.new()
						t_icon.texture = load(path_icon)
						t_icon.custom_minimum_size = Vector2(16, 16)
						t_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
						t_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
						p_hb.add_child(t_icon)
						
					p_mar.add_child(p_hb)
					p_panel.add_child(p_mar)
					hbox_yields.add_child(p_panel)
					
		if hbox_yields.get_child_count() > 0:
			hbox_bldg_main.add_child(hbox_yields)

		margin_bldg.add_child(hbox_bldg_main)
		panel_bldg.add_child(margin_bldg)
		vbox_bldgs.add_child(panel_bldg)
		
	if d.get("mejora_tipo", "") != "":
		var panel_mej = PanelContainer.new()
		var sb_mej = StyleBoxFlat.new()
		sb_mej.bg_color = Color(0.15, 0.15, 0.18)
		sb_mej.set_corner_radius_all(6)
		panel_mej.add_theme_stylebox_override("panel", sb_mej)
		
		var margin_mej = MarginContainer.new()
		margin_mej.add_theme_constant_override("margin_left", 8)
		margin_mej.add_theme_constant_override("margin_right", 8)
		margin_mej.add_theme_constant_override("margin_top", 6)
		margin_mej.add_theme_constant_override("margin_bottom", 6)
		
		var hbox_mej = HBoxContainer.new()
		hbox_mej.alignment = BoxContainer.ALIGNMENT_BEGIN
		hbox_mej.add_theme_constant_override("separation", 8)
		
		var btn_del = crear_boton_borrar_estilizado.call(_borrar_mejora)
		hbox_mej.add_child(btn_del)
		
		var tex_path = resolver_ruta_asset(d.mejora_tipo)
		if ResourceLoader.exists(tex_path):
			var tex_rect = TextureRect.new()
			tex_rect.texture = load(tex_path)
			tex_rect.custom_minimum_size = Vector2(24, 24)
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hbox_mej.add_child(tex_rect)
			
		var lbl_name = Label.new()
		lbl_name.text = d.mejora_tipo.to_upper()
		lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox_mej.add_child(lbl_name)
		
		margin_mej.add_child(hbox_mej)
		panel_mej.add_child(margin_mej)
		vbox_bldgs.add_child(panel_mej)
		
	if d.get("ajeno", false):
		var lbl_ajeno = Label.new()
		lbl_ajeno.text = "EXTERNAL CONTENT"
		lbl_ajeno.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_ajeno.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
		vbox_bldgs.add_child(lbl_ajeno)
		
	if vbox_bldgs.get_child_count() > 0: dyn_node.add_child(vbox_bldgs)
		
	var tiene_desarrollo = celda_tiene_desarrollo(d)
	if btn_quitar_recurso:
		btn_quitar_recurso.visible = not tiene_desarrollo and (d.get("recurso", "") != "") and (d.get("caracteristica", "") != "NATURAL_WONDER")
		
	# Actualizar el recuento flotante de mejoras permitidas
	actualizar_panel_recuento_mejoras()

func actualizar_panel_recuento_mejoras():
	var canvas_mejoras = get_node_or_null("CanvasMejoras")
	if not canvas_mejoras:
		canvas_mejoras = CanvasLayer.new()
		canvas_mejoras.name = "CanvasMejoras"
		canvas_mejoras.layer = 5
		add_child(canvas_mejoras)
		
	var panel = canvas_mejoras.get_node_or_null("PanelRecuentoMejoras")
	if not panel:
		panel = PanelContainer.new()
		panel.name = "PanelRecuentoMejoras"
		panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
		panel.offset_left = -315
		panel.offset_right = -15
		canvas_mejoras.add_child(panel)
		
	for c in panel.get_children(): c.queue_free()
	
	if asentamientos.size() == 0 or asentamiento_activo_idx >= asentamientos.size():
		panel.visible = false
		return
		
	if seccion_actual not in ["CONSTRUCCION", "EXTERNOS"]:
		panel.visible = false
		return
		
	panel.visible = true
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	
	var m_in = MarginContainer.new()
	m_in.add_theme_constant_override("margin_left", 12)
	m_in.add_theme_constant_override("margin_right", 12)
	m_in.add_theme_constant_override("margin_top", 12)
	m_in.add_theme_constant_override("margin_bottom", 12)
	m_in.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var sb_panel = StyleBoxFlat.new()
	sb_panel.bg_color = Color(0.12, 0.12, 0.16, 0.95)
	sb_panel.border_color = Color(0.4, 0.6, 0.8)
	sb_panel.set_border_width_all(2)
	sb_panel.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", sb_panel)
	
	# ==========================================================================
	# 1. SECCIÓN SUPERIOR: DATOS DEL ASENTAMIENTO
	# ==========================================================================
	var asent = asentamientos[asentamiento_activo_idx]
	var asent_centro = asent.centro
	var asent_tipo = asent.tipo
	
	var hb_asent_head = HBoxContainer.new()
	hb_asent_head.alignment = BoxContainer.ALIGNMENT_CENTER
	hb_asent_head.add_theme_constant_override("separation", 8)
	
	var asent_icon_name = "town"
	if asent.tipo == "Capital": asent_icon_name = "palace"
	elif asent.tipo == "City": asent_icon_name = "settlement"
	
	var path_asent_icon = resolver_ruta_asset(asent_icon_name)
	if not ResourceLoader.exists(path_asent_icon):
		path_asent_icon = resolver_ruta_asset("town")
		
	var tex_asent = TextureRect.new()
	if ResourceLoader.exists(path_asent_icon): tex_asent.texture = load(path_asent_icon)
	tex_asent.custom_minimum_size = Vector2(24, 24)
	tex_asent.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_asent.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hb_asent_head.add_child(tex_asent)
	
	var lbl_asent_name = Label.new()
	lbl_asent_name.text = asent.nombre.to_upper()
	lbl_asent_name.add_theme_font_size_override("font_size", 16)
	lbl_asent_name.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
	hb_asent_head.add_child(lbl_asent_name)
	
	vbox.add_child(hb_asent_head)
	
	var total_yields = {"Food": 0, "Production": 0, "Gold": 0, "Science": 0, "Culture": 0, "Happiness": 0, "Influence": 0}
	var improved_resources = []
	var warehouses_construidos = {}
	
	var celdas_asent = asent.get("grid", [])
	if celdas_asent.size() == 0:
		for coord in city_grid.keys():
			if HexMath.dist_hex(coord, asent_centro) <= 3:
				celdas_asent.append(coord)
				
	for coord in celdas_asent:
		if not city_grid.has(coord): continue
		var d_c = city_grid[coord]
		
		for edif in d_c.get("edificios", []):
			warehouses_construidos[edif] = true
		
		var rec = d_c.get("recurso", "")
		var mej = d_c.get("mejora_tipo", "")
		if rec != "" and mej != "":
			improved_resources.append(rec)
			
		var tiene_mejora = (mej != "")
		var tiene_edificios = (d_c.get("edificios", []).size() > 0)
		var es_maravilla = (d_c.get("caracteristica", "") == "NATURAL_WONDER" or d_c.get("terreno", "") == "NATURAL_WONDER")
		
		if tiene_mejora or tiene_edificios or es_maravilla:
			var r_yield = ReglasJuego.calcular_rendimiento_celda(d_c.bioma, d_c.terreno, d_c.get("caracteristica", "NONE"), d_c.get("recurso", ""), d_c.get("rio", false), era_actual)
			for k in r_yield.keys():
				if total_yields.has(k): total_yields[k] += r_yield[k]
			
		var era_mult = obtener_multiplicador_era()
		for edif in d_c.edificios:
			if edif == "Palace":
				total_yields["Food"] += 5 * era_mult
				total_yields["Production"] += 5 * era_mult
				if asentamiento_tiene_agua_dulce(coord): total_yields["Happiness"] += 5 * era_mult
				var adj_palacio = calcular_adyacencia_palacio(coord)
				total_yields["Science"] += adj_palacio["Science"] * era_mult
				total_yields["Culture"] += adj_palacio["Culture"] * era_mult
			elif edif == "Town Hall":
				total_yields["Food"] += 3 * era_mult
				total_yields["Production"] += 3 * era_mult
				if (asent.tipo == "City" or asent.tipo == "Capital") and asentamiento_tiene_agua_dulce(coord):
					total_yields["Happiness"] += 3 * era_mult
			elif Constantes.DATOS_EDIFICIOS.has(edif) and not ReglasJuego.es_edificio_obsoleto(edif, coord, era_actual, city_grid):
				var d_e = Constantes.DATOS_EDIFICIOS[edif]
				var rend = d_e.get("rendimiento", "")
				var base = d_e.get("base", 0)
				var ady = ReglasJuego.calcular_bono_edificio(coord, edif, era_actual, city_grid) if not d_e.get("is_generic", false) else 0
				if total_yields.has(rend): total_yields[rend] += base + ady
			elif Constantes.MARAVILLAS_NATURALES.has(edif):
				var w_yields = Constantes.MARAVILLAS_NATURALES[edif].get("yields", {})
				for wk in w_yields.keys():
					if total_yields.has(wk): total_yields[wk] += w_yields[wk]
					
	var active_yields = []
	for yk in ["Food", "Production", "Gold", "Science", "Culture", "Happiness", "Influence"]:
		if total_yields.get(yk, 0) > 0:
			active_yields.append(yk)
			
	if active_yields.size() > 0:
		var vbox_yields = VBoxContainer.new()
		vbox_yields.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox_yields.add_theme_constant_override("separation", 3)
		
		var hb_y_row1 = HBoxContainer.new()
		hb_y_row1.alignment = BoxContainer.ALIGNMENT_CENTER
		hb_y_row1.add_theme_constant_override("separation", 8)
		
		var hb_y_row2 = HBoxContainer.new()
		hb_y_row2.alignment = BoxContainer.ALIGNMENT_CENTER
		hb_y_row2.add_theme_constant_override("separation", 8)
		
		for i in range(active_yields.size()):
			var yk = active_yields[i]
			var hb_y_item = HBoxContainer.new()
			hb_y_item.alignment = BoxContainer.ALIGNMENT_CENTER
			hb_y_item.add_theme_constant_override("separation", 2)
			
			var lbl_y_val = Label.new()
			lbl_y_val.text = str(total_yields[yk])
			lbl_y_val.add_theme_font_size_override("font_size", 13)
			hb_y_item.add_child(lbl_y_val)
			
			var path_y_icon = resolver_ruta_asset(obtener_nombre_asset_rendimiento(yk))
			if ResourceLoader.exists(path_y_icon):
				var tex_y_icon = TextureRect.new()
				tex_y_icon.texture = load(path_y_icon)
				tex_y_icon.custom_minimum_size = Vector2(18, 18)
				tex_y_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tex_y_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				hb_y_item.add_child(tex_y_icon)
				
			if i < 4:
				hb_y_row1.add_child(hb_y_item)
			else:
				hb_y_row2.add_child(hb_y_item)
				
		vbox_yields.add_child(hb_y_row1)
		if hb_y_row2.get_child_count() > 0:
			vbox_yields.add_child(hb_y_row2)
		vbox.add_child(vbox_yields)
	
	if improved_resources.size() > 0:
		var hb_res = HBoxContainer.new()
		hb_res.alignment = BoxContainer.ALIGNMENT_CENTER
		hb_res.add_theme_constant_override("separation", 6)
		
		for res_name in improved_resources:
			var path_res = resolver_ruta_asset(res_name)
			if ResourceLoader.exists(path_res):
				var tex_res = TextureRect.new()
				tex_res.texture = load(path_res)
				tex_res.custom_minimum_size = Vector2(20, 20)
				tex_res.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tex_res.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				hb_res.add_child(tex_res)
				
		vbox.add_child(hb_res)
		
	vbox.add_child(HSeparator.new())
	
	# ==========================================================================
	# 2. SECCIÓN IMPROVEMENTS
	# ==========================================================================
	var hb_head = HBoxContainer.new()
	hb_head.alignment = BoxContainer.ALIGNMENT_CENTER
	hb_head.add_theme_constant_override("separation", 8)
	
	var path_icon = resolver_ruta_asset("improvements")
	var tex_left = TextureRect.new()
	if ResourceLoader.exists(path_icon): tex_left.texture = load(path_icon)
	tex_left.custom_minimum_size = Vector2(22, 22)
	tex_left.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hb_head.add_child(tex_left)
	
	var lbl_title = Label.new()
	lbl_title.text = "IMPROVEMENTS"
	lbl_title.add_theme_font_size_override("font_size", 16)
	lbl_title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	hb_head.add_child(lbl_title)
	
	var tex_right = TextureRect.new()
	if ResourceLoader.exists(path_icon): tex_right.texture = load(path_icon)
	tex_right.custom_minimum_size = Vector2(22, 22)
	tex_right.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hb_head.add_child(tex_right)
	
	vbox.add_child(hb_head)
	vbox.add_child(HSeparator.new())
	
	var mejoras_permitidas = ["Farm", "Pasture", "Plantation", "Fishing Boat", "Camp", "Woodcutter", "Mine", "Quarry", "Clay Pit"]
	var conteo_construidas = {}
	var conteo_disponibles = {}
	for m in mejoras_permitidas:
		conteo_construidas[m] = 0
		conteo_disponibles[m] = 0
		
	for coord in celdas_asent:
		if not city_grid.has(coord): continue
		var d_c = city_grid[coord]
		
		if d_c.get("ajeno", false): continue 
		if d_c.get("caracteristica", "") == "NATURAL_WONDER" or d_c.get("terreno", "") == "NATURAL_WONDER": continue
		if d_c.get("edificios", []).size() > 0: continue
		
		var mej_colocada = d_c.get("mejora_tipo", "")
		if mej_colocada != "":
			if mej_colocada in mejoras_permitidas:
				conteo_construidas[mej_colocada] += 1
			continue 
			
		var recurso_celda = d_c.get("recurso", "")
		for mej_nombre in mejoras_permitidas:
			if recurso_celda != "" and not es_mejora_compatible_con_recurso(mej_nombre, recurso_celda, era_actual):
				continue
			
			if ReglasJuego.es_mejora_valida(coord, mej_nombre, asent_centro, city_grid, era_actual, civ_actual, asent_tipo):
				conteo_disponibles[mej_nombre] += 1
				
	var hb_imp_headers = HBoxContainer.new()
	hb_imp_headers.alignment = BoxContainer.ALIGNMENT_BEGIN
	hb_imp_headers.add_theme_constant_override("separation", 8)
	
	var lbl_h_dummy = Label.new()
	lbl_h_dummy.custom_minimum_size = Vector2(95, 0)
	lbl_h_dummy.text = ""
	hb_imp_headers.add_child(lbl_h_dummy)
	
	for h_text in ["Disp", "Const", "Sum"]:
		var lbl_col = Label.new()
		lbl_col.text = h_text
		lbl_col.custom_minimum_size = Vector2(40, 0)
		lbl_col.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_col.add_theme_font_size_override("font_size", 11)
		lbl_col.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		hb_imp_headers.add_child(lbl_col)
	vbox.add_child(hb_imp_headers)
	
	var count_shown = 0
	var grid = GridContainer.new()
	grid.columns = 1
	grid.add_theme_constant_override("v_separation", 2)
	
	for i in range(mejoras_permitidas.size()):
		var mej_nombre = mejoras_permitidas[i]
		var disp = conteo_disponibles[mej_nombre]
		var constr = conteo_construidas[mej_nombre]
		var suma = disp + constr
		
		if suma > 0:
			count_shown += 1
			var hb_m = HBoxContainer.new()
			hb_m.alignment = BoxContainer.ALIGNMENT_BEGIN
			hb_m.add_theme_constant_override("separation", 8)
			
			var path_m = resolver_ruta_asset(mej_nombre)
			var tex_m = TextureRect.new()
			if ResourceLoader.exists(path_m): tex_m.texture = load(path_m)
			tex_m.custom_minimum_size = Vector2(20, 20)
			tex_m.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_m.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hb_m.add_child(tex_m)
			
			var lbl_m = Label.new()
			lbl_m.text = mej_nombre
			lbl_m.custom_minimum_size = Vector2(95, 0)
			lbl_m.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl_m.add_theme_font_size_override("font_size", 13)
			hb_m.add_child(lbl_m)
			
			var color_contador = Color(0.5, 1.0, 0.5) if i < 4 else Color(1.0, 0.4, 0.4)
			
			for val in [disp, constr, suma]:
				var lbl_val = Label.new()
				lbl_val.text = str(val)
				lbl_val.custom_minimum_size = Vector2(40, 0)
				lbl_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lbl_val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				lbl_val.add_theme_color_override("font_color", color_contador)
				lbl_val.add_theme_font_size_override("font_size", 13)
				hb_m.add_child(lbl_val)
				
			grid.add_child(hb_m)
			
	if count_shown > 0:
		vbox.add_child(grid)
	else:
		var lbl_none = Label.new()
		lbl_none.text = "No available improvements"
		lbl_none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_none.add_theme_font_size_override("font_size", 13)
		lbl_none.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		vbox.add_child(lbl_none)
		
	# ==========================================================================
	# 3. SECCIÓN WAREHOUSE
	# ==========================================================================
	var warehouse_targets = {
		"Granary": ["Farm", "Pasture", "Plantation"],
		"Fishing Quay": ["Fishing Boat"],
		"Saw Pit": ["Camp", "Woodcutter"],
		"Brickyard": ["Mine", "Quarry", "Clay Pit"],
		"Gristmill": ["Farm", "Pasture", "Plantation"],
		"Stonecutter": ["Mine", "Quarry"],
		"Sawmill": ["Camp", "Woodcutter"],
		"Grocer": ["Farm", "Pasture", "Plantation", "Fishing Boat", "Camp"],
		"Ironworks": ["Mine", "Quarry", "Clay Pit", "Woodcutter"]
	}
	
	var warehouse_yields = {
		"Granary": "food",
		"Fishing Quay": "food",
		"Saw Pit": "production",
		"Brickyard": "production",
		"Gristmill": "food",
		"Stonecutter": "production",
		"Sawmill": "production",
		"Grocer": "food",
		"Ironworks": "production"
	}
	
	var order_warehouses = [
		"Granary", "Fishing Quay", "Saw Pit", "Brickyard",
		"Gristmill", "Stonecutter", "Sawmill",
		"Grocer", "Ironworks"
	]
	
	var grid_wh = GridContainer.new()
	grid_wh.columns = 1
	grid_wh.add_theme_constant_override("v_separation", 2)
	var count_wh_shown = 0
	
	for idx in range(order_warehouses.size()):
		var wh = order_warehouses[idx]
		var boost_built = 0
		var boost_available = 0
		
		if warehouse_targets.has(wh):
			for target in warehouse_targets[wh]:
				boost_built += conteo_construidas.get(target, 0)
				boost_available += conteo_disponibles.get(target, 0)
				
		var is_warehouse_built = warehouses_construidos.has(wh)
		var total_potential = boost_built + boost_available
		
		if total_potential > 0:
			count_wh_shown += 1
			var hb_w = HBoxContainer.new()
			hb_w.alignment = BoxContainer.ALIGNMENT_BEGIN
			hb_w.add_theme_constant_override("separation", 8)
			
			var path_w = resolver_ruta_asset(wh)
			var tex_w = TextureRect.new()
			if ResourceLoader.exists(path_w): tex_w.texture = load(path_w)
			tex_w.custom_minimum_size = Vector2(20, 20)
			tex_w.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_w.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hb_w.add_child(tex_w)
			
			var lbl_w = Label.new()
			lbl_w.text = wh
			lbl_w.custom_minimum_size = Vector2(95, 0)
			lbl_w.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl_w.add_theme_font_size_override("font_size", 13)
			hb_w.add_child(lbl_w)
			
			var yield_type = warehouse_yields.get(wh, "food")
			var path_yield = resolver_ruta_asset(yield_type)
			
			var hb_col1 = HBoxContainer.new()
			hb_col1.alignment = BoxContainer.ALIGNMENT_CENTER
			hb_col1.add_theme_constant_override("separation", 2)
			hb_col1.custom_minimum_size = Vector2(40, 0)
			
			if is_warehouse_built:
				var lbl_c1 = Label.new()
				lbl_c1.text = str(boost_built)
				lbl_c1.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
				lbl_c1.add_theme_font_size_override("font_size", 13)
				hb_col1.add_child(lbl_c1)
				if ResourceLoader.exists(path_yield):
					var tex_y1 = TextureRect.new()
					tex_y1.texture = load(path_yield)
					tex_y1.custom_minimum_size = Vector2(16, 16)
					tex_y1.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					tex_y1.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					hb_col1.add_child(tex_y1)
			else:
				var lbl_dash = Label.new()
				lbl_dash.text = "-"
				lbl_dash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lbl_dash.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
				hb_col1.add_child(lbl_dash)
			hb_w.add_child(hb_col1)
			
			var hb_col2 = HBoxContainer.new()
			hb_col2.alignment = BoxContainer.ALIGNMENT_CENTER
			hb_col2.add_theme_constant_override("separation", 2)
			hb_col2.custom_minimum_size = Vector2(40, 0)
			
			var lbl_c2 = Label.new()
			lbl_c2.text = str(boost_available)
			lbl_c2.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
			lbl_c2.add_theme_font_size_override("font_size", 13)
			hb_col2.add_child(lbl_c2)
			if ResourceLoader.exists(path_yield):
				var tex_y2 = TextureRect.new()
				tex_y2.texture = load(path_yield)
				tex_y2.custom_minimum_size = Vector2(16, 16)
				tex_y2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tex_y2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				hb_col2.add_child(tex_y2)
			hb_w.add_child(hb_col2)
			
			grid_wh.add_child(hb_w)
			
		if idx == 3 or idx == 6:
			grid_wh.add_child(HSeparator.new())
			
	if count_wh_shown > 0:
		vbox.add_child(HSeparator.new())
		
		var hb_head_wh = HBoxContainer.new()
		hb_head_wh.alignment = BoxContainer.ALIGNMENT_CENTER
		hb_head_wh.add_theme_constant_override("separation", 8)
		
		var path_icon_wh = resolver_ruta_asset("warehouse")
		var tex_l_wh = TextureRect.new()
		if ResourceLoader.exists(path_icon_wh): tex_l_wh.texture = load(path_icon_wh)
		tex_l_wh.custom_minimum_size = Vector2(20, 20)
		tex_l_wh.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hb_head_wh.add_child(tex_l_wh)
		
		var lbl_title_wh = Label.new()
		lbl_title_wh.text = "WAREHOUSE"
		lbl_title_wh.add_theme_font_size_override("font_size", 16)
		lbl_title_wh.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
		hb_head_wh.add_child(lbl_title_wh)
		
		var tex_r_wh = TextureRect.new()
		if ResourceLoader.exists(path_icon_wh): tex_r_wh.texture = load(path_icon_wh)
		tex_r_wh.custom_minimum_size = Vector2(20, 20)
		tex_r_wh.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hb_head_wh.add_child(tex_r_wh)
		
		vbox.add_child(hb_head_wh)
		vbox.add_child(HSeparator.new())
		vbox.add_child(grid_wh)
		
	m_in.add_child(vbox)
	panel.add_child(m_in)
	
	# Ajuste automático de altura basado en el contenido real para centrar verticalmente sin espacio vacío
	var content_height = panel.get_combined_minimum_size().y
	panel.offset_top = -content_height * 0.5
	panel.offset_bottom = content_height * 0.5

# ==============================================================================
# FUNCIONES DIBUJO E INPUTS
# ==============================================================================

func _process(delta: float) -> void:
	var focus_owner = get_viewport().gui_get_focus_owner()
	if focus_owner is LineEdit or focus_owner is TextEdit: return

	var dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): dir.x += 1
	
	if dir != Vector2.ZERO and camera:
		camera.position += dir.normalized() * 700 * delta / camera.zoom.x

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed: puntos_tactiles[event.index] = event.position
		else: puntos_tactiles.erase(event.index)
		
		if puntos_tactiles.size() == 2:
			var keys = puntos_tactiles.keys()
			distancia_pinch_inicial = puntos_tactiles[keys[0]].distance_to(puntos_tactiles[keys[1]])
		else: distancia_pinch_inicial = 0.0

	elif event is InputEventScreenDrag:
		puntos_tactiles[event.index] = event.position
		if puntos_tactiles.size() == 1 and camera:
			camera.position -= event.relative / camera.zoom.x
		elif puntos_tactiles.size() == 2 and camera:
			var keys = puntos_tactiles.keys()
			var dist_actual = puntos_tactiles[keys[0]].distance_to(puntos_tactiles[keys[1]])
			if distancia_pinch_inicial > 0:
				var factor = dist_actual / distancia_pinch_inicial
				if abs(factor - 1.0) > 0.005:
					camera.zoom = clamp(camera.zoom * factor, Vector2(0.3, 0.3), Vector2(2.5, 2.5))
					distancia_pinch_inicial = dist_actual
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			arrastrando = event.pressed
			ultimo_pos_raton = event.position
	elif event is InputEventMouseMotion and arrastrando:
		if camera: camera.position -= event.relative / camera.zoom.x

func obtener_nombre_asset_rendimiento(rendimiento: String) -> String:
	match rendimiento.strip_edges().to_lower():
		"food": return "food"
		"production": return "production"
		"gold": return "gold"
		"science": return "science"
		"culture": return "culture"
		"happiness": return "happiness"
		"influence": return "influence"
		_: return ""

func obtener_tooltip_edificio(nombre_edif: String, adyacencia: int) -> String:
	if Constantes.DATOS_EDIFICIOS.has(nombre_edif):
		var d = Constantes.DATOS_EDIFICIOS[nombre_edif]
		var txt = nombre_edif.to_upper() + "\n"
		if d.get("base", 0) > 0: txt += "Base Yield: +" + str(d.get("base", 0)) + " " + d.get("rendimiento", "") + "\n"
		if adyacencia > 0: txt += "Adjacency Bonus: +" + str(adyacencia) + "\n"
		if d.get("desc", "") != "": txt += d.get("desc", "")
		return txt
	return nombre_edif.to_upper()
	
func obtener_tooltip_mejora(nombre_mej: String) -> String:
	var d = Constantes.DATOS_MEJORAS[nombre_mej]
	var txt = nombre_mej.to_upper() + "\n"
	txt += "Yields: " + d.tipo
	return txt

func crear_boton_icono(item_name: String, forma: String, color_borde: Color, tooltip: String, id_press: String, tipo_accion: String = "CONSTRUCCION", es_mejora: bool = false, mostrar_texto: bool = true) -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(58, 58)
	btn.tooltip_text = tooltip
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.12, 0.16)
	sb.border_color = color_borde
	sb.set_border_width_all(3)
	
	if forma == "CIRCLE": sb.set_corner_radius_all(29)
	elif forma == "SQUARE": sb.set_corner_radius_all(4)
	elif forma == "ROUNDED": sb.set_corner_radius_all(12)
		
	btn.add_theme_stylebox_override("normal", sb)
	var sb_hover = sb.duplicate()
	sb_hover.bg_color = Color(0.25, 0.25, 0.3)
	btn.add_theme_stylebox_override("hover", sb_hover)
	
	var tex_path = resolver_ruta_asset(item_name)
	if item_name == "Palace": tex_path = "res://assets/palace.png"
	elif item_name == "Town Hall": tex_path = "res://assets/city_hall.png"
	elif item_name == "Marvel" or item_name.begins_with("Generic_"): tex_path = "res://assets/wonder.png"
	
	if item_name.begins_with("Generic_"):
		var rend_sub = item_name.trim_prefix("Generic_")
		tex_path = resolver_ruta_asset(obtener_nombre_asset_rendimiento(rend_sub))
		
	if ResourceLoader.exists(tex_path):
		var tex = load(tex_path)
		btn.icon = tex
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.expand_icon = true
	else:
		var txt_label = item_name
		if item_name.begins_with("Generic_"): txt_label = item_name.trim_prefix("Generic_")
		btn.text = txt_label.substr(0, 5)
		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_color_override("font_color", Color.WHITE)
		
	vbox.add_child(btn)
	
	var lbl = Label.new()
	if mostrar_texto:
		var display_name = item_name
		if item_name.begins_with("Generic_"): display_name = item_name.trim_prefix("Generic_")
		var trunc_name = display_name.capitalize() if display_name.length() <= 12 else display_name.substr(0, 10) + ".."
		lbl.text = trunc_name
	else: lbl.text = ""
		
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(lbl)
	
	if tipo_accion == "CONSTRUCCION":
		if es_mejora: btn.pressed.connect(func(): _aplicar_mejora(id_press))
		else: btn.pressed.connect(func(): _aplicar_edificio(id_press))
	elif tipo_accion == "EXTERNOS":
		if es_mejora: btn.pressed.connect(func(): _aplicar_mejora_externo(id_press))
		else: btn.pressed.connect(func(): _aplicar_edificio_externo(id_press))
		
	return vbox

func _draw() -> void:
	if asentamientos.size() == 0 or asentamiento_activo_idx >= asentamientos.size(): return
	var asent_centro = asentamientos[asentamiento_activo_idx].centro
	
	for coord in city_grid.keys():
		var datos = city_grid[coord]
		var centro = HexMath.cubo_a_pixel(radio_hex, coord.x, coord.y, -coord.x - coord.y)
		var color_base = Color.LIGHT_GREEN
		var terreno_upper = datos.terreno.strip_edges().to_upper()
		
		if coord == celda_seleccionada: color_base = Color.MAGENTA
		elif Constantes.COLORES_BIOMA.has(datos.bioma):
			color_base = Constantes.COLORES_BIOMA[datos.bioma]
			if terreno_upper in ["OCEAN", "OCEANO"]: color_base = Color(0.05, 0.2, 0.5)
			elif terreno_upper == "NATURAL_WONDER" or datos.get("caracteristica", "") == "NATURAL_WONDER": color_base = Color(0.8, 0.2, 0.5)
			elif terreno_upper in ["LAKE", "LAGO"]: color_base = Color(0.1, 0.65, 0.65)
			elif terreno_upper in ["COASTAL", "COSTA"]: color_base = Color(0.2, 0.5, 0.8)
			
		var puntos = HexMath.obtener_puntos_hex(centro, radio_hex, 1.0)
		draw_colored_polygon(puntos, color_base)
		
		# --- CORRECCIÓN MAPA GRIS PARA OBSOLETOS ---
		var tiene_obsoleto = false
		for e in datos.edificios:
			if ReglasJuego.es_edificio_obsoleto(e, coord, era_actual, city_grid):
				tiene_obsoleto = true
				break
		
		var color_borde = Color(0.1, 0.1, 0.1, 0.3)
		var grosor_borde = 1.5
		if datos.get("ajeno", false):
			color_borde = Color.RED
			grosor_borde = 4.0
		elif tiene_obsoleto:
			color_borde = Color(0.6, 0.6, 0.6, 0.8)
			grosor_borde = 3.5
			
		draw_polyline(puntos + PackedVector2Array([puntos[0]]), color_borde, grosor_borde)

	for coord in city_grid.keys():
		if HexMath.dist_hex(coord, asent_centro) <= 1:
			var centro = HexMath.cubo_a_pixel(radio_hex, coord.x, coord.y, -coord.x - coord.y)
			var puntos = HexMath.obtener_puntos_hex(centro, radio_hex, 1.0)
			for i in range(6):
				var n = coord + HexMath.VECINOS_HEX[i]
				if HexMath.dist_hex(n, asent_centro) > 1:
					draw_line(puntos[i], puntos[(i + 1) % 6], Color.RED, 3.0)

	for coord in city_grid.keys():
		var datos = city_grid[coord]
		var es_reclamada = datos.get("reclamada", HexMath.dist_hex(coord, asent_centro) <= 1)
		if es_reclamada:
			var centro = HexMath.cubo_a_pixel(radio_hex, coord.x, coord.y, -coord.x - coord.y)
			var puntos = HexMath.obtener_puntos_hex(centro, radio_hex, 1.0)
			for i in range(6):
				var n = coord + HexMath.VECINOS_HEX[i]
				var vecino_reclamado = city_grid.has(n) and city_grid[n].get("reclamada", HexMath.dist_hex(n, asent_centro) <= 1)
				if not vecino_reclamado:
					draw_line(puntos[i], puntos[(i + 1) % 6], Color(1.0, 0.85, 0.1), 3.5)

	for coord in city_grid.keys():
		if HexMath.dist_hex(coord, asent_centro) <= 3:
			var centro = HexMath.cubo_a_pixel(radio_hex, coord.x, coord.y, -coord.x - coord.y)
			var puntos = HexMath.obtener_puntos_hex(centro, radio_hex, 1.0)
			for i in range(6):
				var n = coord + HexMath.VECINOS_HEX[i]
				if HexMath.dist_hex(n, asent_centro) > 3 or not city_grid.has(n):
					draw_line(puntos[i], puntos[(i + 1) % 6], Color.BLACK, 4.0)

	var lineas_rio_dibujadas = {}
	for coord in city_grid.keys():
		if city_grid[coord].rio:
			var centro = HexMath.cubo_a_pixel(radio_hex, coord.x, coord.y, -coord.x - coord.y)
			var tiene_vecino_rio = false
			for vec in HexMath.VECINOS_HEX:
				var n = coord + vec
				if city_grid.has(n) and city_grid[n].rio:
					tiene_vecino_rio = true
					var clave_par = [coord, n] if (coord.x < n.x or (coord.x == n.x and coord.y < n.y)) else [n, coord]
					if not lineas_rio_dibujadas.has(clave_par):
						lineas_rio_dibujadas[clave_par] = true
						var centro_n = HexMath.cubo_a_pixel(radio_hex, n.x, n.y, -n.x - n.y)
						draw_line(centro, centro_n, Color(0.15, 0.55, 0.95), 8.0, true)
			if not tiene_vecino_rio: draw_circle(centro, 6.0, Color(0.15, 0.55, 0.95))

func actualizar_icono_celda(coord: Vector2i):
	if not city_grid.has(coord): return
	var datos = city_grid[coord]
	var centro_px = HexMath.cubo_a_pixel(radio_hex, coord.x, coord.y, -coord.x - coord.y)
	
	if not is_instance_valid(datos.get("nodo_icono")) or not (datos.nodo_icono is GridContainer):
		if is_instance_valid(datos.get("nodo_icono")): datos.nodo_icono.queue_free()
		var grid_icono = GridContainer.new()
		grid_icono.columns = 2
		grid_icono.add_theme_constant_override("h_separation", 2)
		grid_icono.add_theme_constant_override("v_separation", 2)
		grid_icono.custom_minimum_size = Vector2(40, 40)
		add_child(grid_icono)
		datos.nodo_icono = grid_icono
		
	if not is_instance_valid(datos.get("nodo_recurso")):
		var hbox_recurso = HBoxContainer.new()
		hbox_recurso.custom_minimum_size = Vector2(24, 24)
		hbox_recurso.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox_recurso.position = centro_px - Vector2(12, radio_hex * 0.75)
		add_child(hbox_recurso)
		datos.nodo_recurso = hbox_recurso
		
	if not is_instance_valid(datos.get("nodo_terreno")):
		var hbox_terreno = HBoxContainer.new()
		hbox_terreno.custom_minimum_size = Vector2(40, 40)
		hbox_terreno.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox_terreno.position = centro_px - Vector2(20, -radio_hex * 0.15)
		add_child(hbox_terreno)
		datos.nodo_terreno = hbox_terreno
	
	if is_instance_valid(datos.nodo_recurso):
		for child in datos.nodo_recurso.get_children(): child.queue_free()
	if is_instance_valid(datos.nodo_terreno):
		for child in datos.nodo_terreno.get_children(): child.queue_free()
	if is_instance_valid(datos.nodo_icono):
		for child in datos.nodo_icono.get_children(): child.queue_free()
	
	var anadir_elemento_visual = func(container: Control, asset_name: String, nombre_fallback: String, tam_minimo: float, texto_visible: bool = true):
		var path = ""
		if asset_name != "": path = resolver_ruta_asset(asset_name)
		if path != "" and ResourceLoader.exists(path):
			var texture_rect = TextureRect.new()
			texture_rect.texture = load(path)
			texture_rect.custom_minimum_size = Vector2(tam_minimo, tam_minimo)
			texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			container.add_child(texture_rect)
		elif texto_visible:
			var lbl = Label.new()
			lbl.text = nombre_fallback
			lbl.add_theme_font_size_override("font_size", 12)
			lbl.add_theme_color_override("font_color", Color.WHITE)
			container.add_child(lbl)

	if datos.get("recurso", "") != "" and datos.mejora_tipo == "":
		anadir_elemento_visual.call(datos.nodo_recurso, datos.recurso, datos.recurso, 24.0, true)
	elif datos.get("recurso", "") != "" and datos.mejora_tipo != "":
		anadir_elemento_visual.call(datos.nodo_recurso, datos.recurso, datos.recurso, 24.0, true)
		
	if datos.terreno != "FLAT" or datos.caracteristica in ["WET", "VEGETATED", "FLOODPLAIN"]:
		var txt_icono = Constantes.ICONOS_TERRENO.get(datos.terreno, "")
		if datos.caracteristica == "WET": txt_icono = "💧"
		elif datos.caracteristica == "VEGETATED": txt_icono = "🌲"
		elif datos.caracteristica == "FLOODPLAIN": txt_icono = "🛤️"
		anadir_elemento_visual.call(datos.nodo_terreno, "", txt_icono, 32.0, true)
		
	var edificios_visibles = []
	for edif in datos.edificios:
		if not ReglasJuego.es_edificio_muralla(edif):
			edificios_visibles.append(edif)
			
	if edificios_visibles.size() > 0:
		var num_edif = edificios_visibles.size()
		var size_edif = 36.0 if num_edif <= 2 else 26.0
		var cols = min(num_edif, 2)
		var rows = int(ceil(float(num_edif) / 2.0))
		var h_sep = 4.0
		var v_sep = 4.0
		var ancho_total = (cols * size_edif) + ((cols - 1) * h_sep)
		var alto_total = (rows * size_edif) + ((rows - 1) * v_sep)
		
		datos.nodo_icono.columns = cols
		datos.nodo_icono.add_theme_constant_override("h_separation", int(h_sep))
		datos.nodo_icono.add_theme_constant_override("v_separation", int(v_sep))
		datos.nodo_icono.custom_minimum_size = Vector2(ancho_total, alto_total)
		datos.nodo_icono.position = centro_px - Vector2(ancho_total * 0.5, alto_total * 0.5)
		
		for edif in edificios_visibles:
			if ReglasJuego.es_edificio_obsoleto(edif, coord, era_actual, city_grid):
				anadir_elemento_visual.call(datos.nodo_icono, "warning", "⚠️ Obsolete", size_edif, true)
			else:
				var asset_name = edif
				var es_maravilla = Constantes.DATOS_EDIFICIOS.get(edif, {}).get("is_wonder", false)
				var es_maravilla_natural = Constantes.MARAVILLAS_NATURALES.has(edif)
				
				if edif == "Palace" or edif == "Town Hall": asset_name = "palace" if edif == "Palace" else "city_hall"
				elif edif == "Marvel" or (es_maravilla and not ResourceLoader.exists(resolver_ruta_asset(asset_name))): asset_name = "wonder"
					
				if es_maravilla_natural:
					var path = resolver_ruta_asset(asset_name)
					if path != "" and ResourceLoader.exists(path):
						datos.nodo_icono.position = centro_px - Vector2(42, 48)
						datos.nodo_icono.custom_minimum_size = Vector2(84, 96)
						datos.nodo_icono.clip_contents = true
						var texture_rect = TextureRect.new()
						texture_rect.texture = load(path)
						texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
						texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
						texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
						texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
						datos.nodo_icono.add_child(texture_rect)
					else:
						anadir_elemento_visual.call(datos.nodo_icono, asset_name, edif, size_edif, true)
				else:
					anadir_elemento_visual.call(datos.nodo_icono, asset_name, edif, size_edif, true)
	elif datos.mejora_tipo != "":
		datos.nodo_icono.columns = 1
		var ancho = 36.0
		if cache_puentes_urbanos.has(coord) and not datos.get("ajeno", false):
			datos.nodo_icono.columns = 2
			ancho = 64.0
			
		datos.nodo_icono.custom_minimum_size = Vector2(ancho, 36)
		datos.nodo_icono.position = centro_px - Vector2(ancho * 0.5, 18)
		anadir_elemento_visual.call(datos.nodo_icono, datos.mejora_tipo, datos.mejora_tipo, 36.0, true)
		
		if datos.get("recurso", "") != "":
			if is_instance_valid(datos.nodo_recurso):
				datos.nodo_recurso.position = centro_px - Vector2(24, radio_hex * 0.75)
		
		if cache_puentes_urbanos.has(coord) and not datos.get("ajeno", false):
			anadir_elemento_visual.call(datos.nodo_icono, "warning", "⚠️", 24.0, true)
			
	elif datos.get("ajeno", false):
		datos.nodo_icono.columns = 1
		datos.nodo_icono.custom_minimum_size = Vector2(36, 36)
		datos.nodo_icono.position = centro_px - Vector2(18, 18)
		anadir_elemento_visual.call(datos.nodo_icono, "influence", "External", 36.0, true)
		
	elif cache_puentes_urbanos.has(coord):
		datos.nodo_icono.columns = 1
		datos.nodo_icono.custom_minimum_size = Vector2(40, 50)
		datos.nodo_icono.position = centro_px - Vector2(20, 25)
		
		var vbox_link = VBoxContainer.new()
		vbox_link.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox_link.add_theme_constant_override("separation", 2)
		vbox_link.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var tex_rect = TextureRect.new()
		var path_warning = resolver_ruta_asset("warning")
		if ResourceLoader.exists(path_warning): tex_rect.texture = load(path_warning)
		tex_rect.custom_minimum_size = Vector2(26, 26)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox_link.add_child(tex_rect)
		
		var lbl_sub = Label.new()
		lbl_sub.text = "urban"
		lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_sub.add_theme_font_size_override("font_size", 9)
		lbl_sub.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
		lbl_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox_link.add_child(lbl_sub)
		
		datos.nodo_icono.add_child(vbox_link)
		
	elif seccion_actual == "CONSTRUCCION":
		if sugerencias_cache.has(coord):
			var iconos_agregados = {}
			var lista_sug_validas = []
			for sug in sugerencias_cache[coord]:
				var d_sug = Constantes.DATOS_EDIFICIOS.get(sug.edificio, {})
				var asset_sug = ""
				
				# Las maravillas y los almacenes utilizan el icono "wonder" para resaltarse en el mapa
				if d_sug.get("is_wonder", false) or d_sug.get("tipo", "") == "Warehouse":
					asset_sug = "wonder"
				else:
					asset_sug = obtener_nombre_asset_rendimiento(d_sug.get("rendimiento", ""))
					
				if not iconos_agregados.has(asset_sug) and asset_sug != "":
					lista_sug_validas.append(asset_sug)
					iconos_agregados[asset_sug] = true
			
			if lista_sug_validas.size() > 0:
				var num = lista_sug_validas.size()
				var tam_icono = 16.0
				var h_sep = 2.0
				var v_sep = 2.0
				var cols = min(num, 2)
				var rows = int(ceil(float(num) / 2.0))
				
				var ancho_total = (cols * tam_icono) + ((cols - 1) * h_sep)
				var alto_total = (rows * tam_icono) + ((rows - 1) * v_sep)
				
				datos.nodo_icono.columns = 2
				datos.nodo_icono.add_theme_constant_override("h_separation", int(h_sep))
				datos.nodo_icono.add_theme_constant_override("v_separation", int(v_sep))
				datos.nodo_icono.custom_minimum_size = Vector2(ancho_total, alto_total)
				datos.nodo_icono.position = centro_px - Vector2(ancho_total * 0.5, alto_total * 0.5)
				
				for asset_sug in lista_sug_validas:
					anadir_elemento_visual.call(datos.nodo_icono, asset_sug, "", tam_icono, false)

func actualizar_iconos_todos():
	cache_puentes_urbanos = _calcular_celdas_puente_requeridas()
	for coord in city_grid.keys(): actualizar_icono_celda(coord)
	actualizar_panel_estadisticas()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var raton_local = get_local_mouse_position()
		var hex = HexMath.pixel_a_cubo(radio_hex, raton_local)
		if city_grid.has(hex):
			celda_seleccionada = hex
			actualizar_botones_recursos_ui()
			actualizar_panel_pincel()
			actualizar_panel_construccion()
			actualizar_panel_externos()
			actualizar_visibilidad_boton_externos()
			actualizar_visibilidad_boton_construccion()
			actualizar_panel_ui()
			queue_redraw()
			
func actualizar_visibilidad_boton_construccion():
	if not btn_modo_construccion: return
	if asentamientos.size() == 0 or asentamiento_activo_idx >= asentamientos.size(): return
	var asent_centro = asentamientos[asentamiento_activo_idx].centro
	var dist = HexMath.dist_hex(celda_seleccionada, asent_centro)
	var es_ring_4 = (dist == 4)
	
	btn_modo_construccion.visible = not es_ring_4
	if es_ring_4 and seccion_actual == "CONSTRUCCION":
		cambiar_seccion("EXTERNOS" if es_celda_externos_valida() else "ASENTAMIENTOS")

func mostrar_pantalla_partidas_guardadas():
	if panel_construccion: panel_construccion.visible = false
	if panel_info: panel_info.visible = true
	
	if not lbl_info: return
	var parent = lbl_info.get_parent()
	var dyn_node = parent.get_node_or_null("ContenedorInfoDinamico")
	if not dyn_node:
		dyn_node = VBoxContainer.new()
		dyn_node.name = "ContenedorInfoDinamico"
		dyn_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dyn_node.add_theme_constant_override("separation", 14)
		parent.add_child(dyn_node)
		
	lbl_info.visible = false
	for c in dyn_node.get_children(): c.queue_free()
	
	var lbl_titulo = Label.new()
	lbl_titulo.text = "HEX CITY BUILDER"
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_titulo.add_theme_font_size_override("font_size", 20)
	dyn_node.add_child(lbl_titulo)
	
	var btn_new = Button.new()
	btn_new.text = "➕ New Game"
	btn_new.custom_minimum_size = Vector2(0, 48)
	var sb_new = StyleBoxFlat.new()
	sb_new.bg_color = Color(0.2, 0.55, 0.3)
	sb_new.set_corner_radius_all(6)
	btn_new.add_theme_stylebox_override("normal", sb_new)
	
	var sb_new_hover = sb_new.duplicate()
	sb_new_hover.bg_color = Color(0.25, 0.65, 0.35)
	btn_new.add_theme_stylebox_override("hover", sb_new_hover)
	
	btn_new.pressed.connect(func():
		_controlar_botones_navegacion(true)
		mostrar_dialogo_lideres_inicio(true)
	)
	dyn_node.add_child(btn_new)
	
	dyn_node.add_child(HSeparator.new())
	
	var lbl_saved = Label.new()
	lbl_saved.text = "Loaded / Saved Games"
	lbl_saved.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dyn_node.add_child(lbl_saved)
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 320)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vbox_saves = VBoxContainer.new()
	vbox_saves.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_saves.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox_saves)
	dyn_node.add_child(scroll)
	
	partidas_guardadas = GestorArchivos.cargar_local()
	if partidas_guardadas.keys().size() == 0:
		var lbl_none = Label.new()
		lbl_none.text = "(No saved games found)"
		lbl_none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_none.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		vbox_saves.add_child(lbl_none)
	else:
		for save_name in partidas_guardadas.keys():
			var save_data = partidas_guardadas[save_name]
			
			var btn_save = Button.new()
			btn_save.custom_minimum_size = Vector2(0, 46)
			var sb_save = StyleBoxFlat.new()
			sb_save.bg_color = Color(0.25, 0.25, 0.32)
			sb_save.set_corner_radius_all(6)
			sb_save.content_margin_left = 12
			sb_save.content_margin_right = 12
			btn_save.add_theme_stylebox_override("normal", sb_save)
			
			var sb_save_hover = sb_save.duplicate()
			sb_save_hover.bg_color = Color(0.35, 0.35, 0.45)
			btn_save.add_theme_stylebox_override("hover", sb_save_hover)
			
			var hbox_row = HBoxContainer.new()
			hbox_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			hbox_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hbox_row.alignment = BoxContainer.ALIGNMENT_CENTER
			hbox_row.add_theme_constant_override("separation", 10)
			btn_save.add_child(hbox_row)
			
			var lider_nombre = save_data.get("lider_actual", "")
			if lider_nombre != "":
				var path_lider = resolver_ruta_asset(lider_nombre)
				if ResourceLoader.exists(path_lider):
					var tex_lider = TextureRect.new()
					tex_lider.texture = load(path_lider)
					tex_lider.custom_minimum_size = Vector2(30, 30)
					tex_lider.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					tex_lider.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					hbox_row.add_child(tex_lider)
			
			var civ_nombre = save_data.get("civ_actual", "")
			if civ_nombre != "":
				var path_civ = resolver_ruta_asset(civ_nombre)
				if ResourceLoader.exists(path_civ):
					var tex_civ = TextureRect.new()
					tex_civ.texture = load(path_civ)
					tex_civ.custom_minimum_size = Vector2(30, 30)
					tex_civ.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					tex_civ.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					hbox_row.add_child(tex_civ)
			
			var lbl_name = Label.new()
			lbl_name.text = save_name
			lbl_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			hbox_row.add_child(lbl_name)
			
			var s_name = save_name
			btn_save.pressed.connect(func():
				_controlar_botones_navegacion(true)
				GestorArchivos.cargar_partida_especifica(self, s_name)
				cambiar_seccion("ASENTAMIENTOS")
			)
			vbox_saves.add_child(btn_save)
	
func _controlar_botones_navegacion(mostrar: bool):
	if btn_menu_pincel: btn_menu_pincel.visible = mostrar
	if btn_menu_asentamientos: btn_menu_asentamientos.visible = mostrar
	if btn_menu_maravillas: btn_menu_maravillas.visible = mostrar
	if btn_modo_construccion: btn_modo_construccion.visible = mostrar
	if btn_modo_externos: btn_modo_externos.visible = mostrar

func _crear_panel_estadisticas():
	var canvas_hud = CanvasLayer.new()
	canvas_hud.layer = 5
	
	panel_estadisticas = MarginContainer.new()
	panel_estadisticas.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel_estadisticas.add_theme_constant_override("margin_top", 16)
	panel_estadisticas.add_theme_constant_override("margin_right", 16)
	
	var fondo_panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.12, 0.15, 0.9)
	sb.border_color = Color(0.35, 0.35, 0.4)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	fondo_panel.add_theme_stylebox_override("panel", sb)
	
	var margen_interno = MarginContainer.new()
	margen_interno.add_theme_constant_override("margin_left", 14)
	margen_interno.add_theme_constant_override("margin_right", 14)
	margen_interno.add_theme_constant_override("margin_top", 12)
	margen_interno.add_theme_constant_override("margin_bottom", 12)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	
	var lbl_title = Label.new()
	lbl_title.text = "SETTLEMENT CONTENT"
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_size_override("font_size", 13)
	lbl_title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	vbox.add_child(lbl_title)
	
	vbox.add_child(HSeparator.new())
	
	grid_estadisticas = GridContainer.new()
	grid_estadisticas.columns = 2
	grid_estadisticas.add_theme_constant_override("h_separation", 16)
	grid_estadisticas.add_theme_constant_override("v_separation", 6)
	vbox.add_child(grid_estadisticas)
	
	margen_interno.add_child(vbox)
	fondo_panel.add_child(margen_interno)
	panel_estadisticas.add_child(fondo_panel)
	
	canvas_hud.add_child(panel_estadisticas)
	add_child(canvas_hud)

func actualizar_panel_estadisticas():
	if not grid_estadisticas: return
	for c in grid_estadisticas.get_children(): c.queue_free()
	
	if asentamientos.size() == 0 or asentamiento_activo_idx >= asentamientos.size():
		panel_estadisticas.visible = false
		return
		
	# Solo mostrar si no estamos gestionando imperios globalmente
	panel_estadisticas.visible = (seccion_actual != "ASENTAMIENTOS" and seccion_actual != "PINCEL")
	
	var asent = asentamientos[asentamiento_activo_idx]
	var mejoras = {}
	var edificios = {}
	
	for coord in asent.grid:
		if city_grid.has(coord):
			var d = city_grid[coord]
			if d.mejora_tipo != "":
				mejoras[d.mejora_tipo] = mejoras.get(d.mejora_tipo, 0) + 1
			for e in d.edificios:
				if not ReglasJuego.es_edificio_muralla(e):
					edificios[e] = edificios.get(e, 0) + 1
					
	var crear_item = func(nombre: String, cant: int):
		var hb = HBoxContainer.new()
		hb.alignment = BoxContainer.ALIGNMENT_BEGIN
		hb.add_theme_constant_override("separation", 6)
		
		# Intentar obtener Asset (si no, icono genérico)
		var p = resolver_ruta_asset(nombre)
		if ResourceLoader.exists(p):
			var tex_rect = TextureRect.new()
			tex_rect.texture = load(p)
			tex_rect.custom_minimum_size = Vector2(18, 18)
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hb.add_child(tex_rect) 
		else:
			var l_dot = Label.new()
			l_dot.text = "•"
			hb.add_child(l_dot)
			
		var l = Label.new()
		var trunc_name = nombre.capitalize() if nombre.length() <= 15 else nombre.substr(0, 13) + ".."
		l.text = trunc_name + " x" + str(cant)
		l.add_theme_font_size_override("font_size", 12)
		hb.add_child(l)
		grid_estadisticas.add_child(hb)
		
	var arr_m = mejoras.keys()
	arr_m.sort()
	for m in arr_m: crear_item.call(m, mejoras[m])
	
	var arr_e = edificios.keys()
	arr_e.sort()
	for e in arr_e: crear_item.call(e, edificios[e])

func es_edificio_valido(coord, edificio_nombre, grid_celdas, era):
	if not grid_celdas.has(coord): return false
	var d_c = grid_celdas[coord]
	
	# PROHIBICIÓN TOTAL: Las maravillas naturales no admiten edificios ni maravillas normales
	var es_maravilla_natural = (d_c.get("caracteristica", "") == "NATURAL_WONDER" or d_c.get("terreno", "") == "NATURAL_WONDER")
	if es_maravilla_natural:
		return false
		
	# Comprobaciones estándar de edificios
	if not "DATOS_EDIFICIOS" in Constantes or not Constantes.DATOS_EDIFICIOS.has(edificio_nombre):
		return false
		
	return true
