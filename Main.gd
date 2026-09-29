extends Node2D

# ==============================================================================

# CIV7 - ARCHIVO PRINCIPAL UNIFICADO
# ------------------------------------------------------------------------------
# Este archivo contiene TODA la logica del juego y de la interfaz:
#   1) La clase principal (Main, extends Node2D) con el estado de la partida,
#      los paneles, la entrada, el dibujo del mapa y las pantallas.
#   2) Los MODULOS INTERNOS (clases anidadas al final del archivo), que antes
#      eran scripts sueltos cargados como autoloads:
#         MaravillasNaturales-> motor de reglas de maravillas naturales
#         HexMath            -> matematicas de hexagonos
#         ReglasJuego        -> reglas/validaciones puras del juego
#         GestorPincel       -> edicion de terreno (bioma, recurso, rio...)
#         GestorConstruccion -> construccion de edificios y mejoras + sugerencias
#         GestorAsentamientos-> ciclo de vida de asentamientos y eras
#         GestorArchivos     -> guardado/carga de partidas (JSON)
#         GestorMementos     -> reglas de seleccion de mementos
#         GestorPoliticas    -> reglas de politicas y tradiciones heredadas
#         GestorDialogos     -> dialogos modales (lider, era, renombrar...)
#         GestorInterfaz     -> construccion del arbol de interfaz
#
# TODO el proyecto se reparte en DOS scripts: este (Main.gd: clase principal +
# modulos internos) y "Constantes.gd" (datos estaticos y valores por defecto).
# Aqui NO vive ningun diccionario de datos: lideres, edificios, mejoras,
# maravillas, civilizaciones, recursos, biomas, mementos y politicas se leen de
# "Constantes.gd" (Constantes.DATOS_*).
#
# INDICE DEL ARCHIVO
#   - ESTADO DE LA PARTIDA Y REFERENCIAS DE UI .... variables de la clase
#   - ARRANQUE .................................... _ready()
#   - API DE DELEGACION (puentes hacia los modulos internos, usada por la UI)
#   - LOGICA LOCAL (camara, adyacencias, agua dulce, validadores auxiliares)
#   - CONSTRUCCION DE UI (botones, iconos, tooltips, listas)
#   - PANELES (pincel, construccion, externos, asentamientos, maravillas,
#     estadisticas y recuentos)
#   - NAVEGACION Y ENTRADA (cambiar_seccion, _process, _input, _unhandled_input)
#   - DIBUJO DEL MAPA (_draw, actualizar_icono_celda, actualizar_iconos_todos)
#   - PANTALLAS (partidas guardadas, estadisticas)
#   - MODULOS INTERNOS (clases anidadas al final del archivo)
# ==============================================================================

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

# --- SISTEMAS NUEVOS (Mementos, Rivales, Políticas) ---
# Selección de mementos activa por Era (máximo Constantes.MEMENTOS_MAXIMO_POR_ERA).
var mementos_activos: Dictionary = {"Antiquity": [], "Exploration": [], "Modern Age": []}

# Políticas activas por Era (Social/Crisis/Ideology). El contador total de la
# UI INCLUYE además las tradiciones activas (máximos por defecto:
# Constantes.MAXIMO_POLITICAS_POR_ERA y Constantes.MAXIMO_TRADICIONES_POR_ERA).
var politicas_activas: Dictionary = {"Antiquity": [], "Exploration": [], "Modern Age": []}

# Tradiciones activas por Era (tope exclusivo MAXIMO_TRADICIONES_POR_ERA).
var tradiciones_activas: Dictionary = {"Antiquity": [], "Exploration": [], "Modern Age": []}

# Tradiciones que han estado activas en algún momento: se GUARDAN y se acoplan
# a las listas de las Eras siguientes (quedan disponibles para reseleccionarse).
var tradiciones_historicas: Array = []

# Topes de disponibilidad ampliables con los botones "+" del modal de
# Políticas y Tradiciones (se guardan con la partida). Invariant: pol >= trad.
var tope_politicas: int = Constantes.MAXIMO_POLITICAS_POR_ERA
var tope_tradiciones: int = Constantes.MAXIMO_TRADICIONES_POR_ERA
# Configuración de rivales: [{"lider": String, "civ": String, "relacion": String, "rutas": int}, ...]
var rivales_config: Array = []

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
var btn_menu_felicidad: Button

var panel_biomas: Control
var scroll_biomas: ScrollContainer
var grid_biomas: GridContainer
var grid_terrenos: GridContainer
var grid_carac: GridContainer
var panel_maravillas: Control
var panel_felicidad: Control
var grid_maravillas_naturales: GridContainer

var panel_construccion: VBoxContainer
var grid_recursos: GridContainer
var btn_quitar_recurso: Button
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
	btn_menu_felicidad = refs.get("btn_menu_felicidad")
	panel_biomas = refs.get("panel_biomas")
	scroll_biomas = refs.get("scroll_biomas")
	grid_biomas = refs.get("grid_biomas")
	grid_terrenos = refs.get("grid_terrenos")
	grid_carac = refs.get("grid_carac")
	panel_maravillas = refs.get("panel_maravillas")
	panel_felicidad = refs.get("panel_felicidad")
	grid_maravillas_naturales = refs.get("grid_maravillas_naturales")
	panel_construccion = refs.get("panel_construccion")
	grid_recursos = refs.get("grid_recursos")
	btn_quitar_recurso = refs.get("btn_quitar_recurso")
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
# API DE DELEGACIÓN: PUENTES HACIA LOS MÓDULOS INTERNOS (LOS INVOCA LA UI)
# ==============================================================================

func guardar_partida_actual(): GestorArchivos.guardar_partida_actual(self)
func cargar_partida_especifica(nombre: String) -> bool: return GestorArchivos.cargar_partida_especifica(self, nombre)
func mostrar_dialogo_cargar(): GestorArchivos.mostrar_dialogo_cargar(self)

func celda_tiene_desarrollo(datos: Dictionary) -> bool:
	return GestorPincel.celda_tiene_desarrollo(datos)

func _aplicar_bioma_y_terreno(b: String, t: String): GestorPincel.aplicar_bioma_y_terreno(self, b, t)
func _aplicar_caracteristica(c: String): GestorPincel.aplicar_caracteristica(self, c)
func _aplicar_recurso(recurso_nombre: String): GestorPincel.aplicar_recurso(self, recurso_nombre)
func _aplicar_maravilla_natural(maravilla_nombre: String): GestorPincel.aplicar_maravilla_natural(self, maravilla_nombre)
func _borrar_maravilla_natural(): GestorPincel.borrar_maravilla_natural(self)
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

# Al pulsar el botón de cambiar Era se abre primero el panel de Políticas y
# Tradiciones para seleccionar las tradiciones que pasarán a la siguiente Era.
func mostrar_panel_politicas_cambio_era(): GestorDialogos.mostrar_dialogo_politicas(self, true)
func mostrar_dialogo_sincretismo(): GestorDialogos.mostrar_dialogo_sincretismo(self)
func mostrar_dialogo_lideres_inicio(iniciar_nueva_partida_despues: bool = true): GestorDialogos.mostrar_dialogo_lideres_inicio(self, iniciar_nueva_partida_despues)
func mostrar_dialogo_mementos(): GestorDialogos.mostrar_dialogo_mementos(self)
func mostrar_dialogo_rivales(): GestorDialogos.mostrar_dialogo_rivales(self)
func mostrar_dialogo_politicas(): GestorDialogos.mostrar_dialogo_politicas(self)
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
			"FELICIDAD": panel_activo = panel_felicidad
			
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
			actualizar_panel_gestion_ui()
		centrar_camara_en_activo()
		dialog.queue_free()
	)
	dialog.close_requested.connect(func():
		centrar_camara_en_activo()
		dialog.queue_free()
	)
	# Apertura centralizada: garantiza un único modal activo y evita el error
	# "Attempting to make child window exclusive...".
	GestorInterfaz.abrir_modal(self, dialog, null, false, Vector2(320, 160))

func es_mejora_compatible_con_recurso(mej_nombre: String, recurso: String, era: String) -> bool:
	# Toda la información del recurso (mejora + eras) vive en DATOS_RECURSOS.
	return ReglasJuego.recurso_compatible_con_mejora(recurso, mej_nombre, era)

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
	# Gullfoss / Iguazú Falls otorgan agua dulce al asentamiento cuando su
	# celda de maravilla está activada con "Expedition Base".
	return MaravillasNaturales.otorga_agua_dulce(city_grid)

# Punto central de consulta del bono de producción de caballería.
# Seongsan Ilchulbong aporta +20% por cada celda activada.
func multiplicador_produccion_caballeria() -> float:
	return MaravillasNaturales.multiplicador_produccion_caballeria(city_grid)


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
				# Sin vecino más cercano al centro (celdas dispersas o sin camino
				# hacia él): no hay por dónde avanzar, se corta para no girar sin fin.
				if mejor_vecino == actual:
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
		# Regla general: el botón de la sección activa permanece oculto.
		if seccion_actual == "EXTERNOS":
			var sigue_valida = es_celda_externos_valida()
			btn_modo_externos.visible = false
			if not sigue_valida:
				cambiar_seccion("CONSTRUCCION")
			return
		var visible_val = es_celda_externos_valida()
		btn_modo_externos.visible = visible_val

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
				# El cupo de especialistas depende del tipo del asentamiento: al
				# promocionar a Ciudad se abren los cupos de todas sus celdas, y el
				# panel de la celda se repinta para que la fila aparezca en ese
				# instante en vez de esperar a la siguiente actualización.
				GestorAsentamientos.sincronizar_especialistas_asentamiento(self, index_t)
				actualizar_lista_asentamientos_ui()
				actualizar_panel_ui()
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
	var carac_actual = datos_celda.get("caracteristica", "NONE")
	
	# La validez terreno/feature de cada recurso la decide DATOS_RECURSOS
	# (es_recurso_valido_en_celda); aquí solo se excluyen casos estructurales.
	# Las maravillas naturales (features) tampoco gestionan recursos.
	if es_centro or carac_actual in ["ICE", "NATURAL_WONDER"] or MaravillasNaturales.es_maravilla(datos_celda):
		if header_node: header_node.visible = false
		grid_recursos.visible = false
		if btn_quitar_recurso: btn_quitar_recurso.visible = false
		return
	

	if header_node and header_node is HBoxContainer:
		for child in header_node.get_children():
			if child is Label:
				child.text = "RESOURCES"
				break
	if header_node: header_node.visible = true
	grid_recursos.columns = 6

	var recurso_actual = datos_celda.get("recurso", "")
	# Un nombre de maravilla natural en "recurso" no es un recurso: esas celdas
	# no muestran el botón de quitar recurso (se gestionan desde Features).
	if recurso_actual != "" and Constantes.MARAVILLAS_NATURALES.has(recurso_actual):
		grid_recursos.visible = false
		if header_node: header_node.visible = false
		if btn_quitar_recurso: btn_quitar_recurso.visible = false
		return
	if recurso_actual != "":
		grid_recursos.visible = false
		if header_node: header_node.visible = false
		if btn_quitar_recurso: btn_quitar_recurso.visible = true
		return
	else:
		grid_recursos.visible = true
		if header_node: header_node.visible = true
		if btn_quitar_recurso: btn_quitar_recurso.visible = false

	var hay_botones = false
	for rec_name in Constantes.DATOS_RECURSOS.keys():
		if not ReglasJuego.es_recurso_valido_en_celda(rec_name, datos_celda, era_actual): continue
		hay_botones = true

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

	# Sin recursos válidos para la celda: se oculta la sección completa.
	if not hay_botones:
		grid_recursos.visible = false
		if header_node: header_node.visible = false

# Devuelve las maravillas naturales válidas para una celda: cumplen bioma/terreno,
# respetan el límite de casillas por asentamiento y excluyen las que quedarían
# adyacentes a una maravilla natural distinta ya presente en el tablero.
func listar_maravillas_disponibles_celda(coord: Vector2i) -> Array:
	var disponibles: Array = []
	if not city_grid.has(coord): return disponibles
	if asentamientos.size() == 0 or asentamiento_activo_idx >= asentamientos.size(): return disponibles
	var d = city_grid[coord]
	# En una maravilla natural (feature) sí se listan sus botones: permiten
	# gestionarla o sustituirla; solo se excluye si hay otro desarrollo.
	if celda_tiene_desarrollo(d) and not MaravillasNaturales.es_maravilla(d): return disponibles
	if d.edificios.has("Palace") or d.edificios.has("Town Hall"): return disponibles
	var b_actual = d.bioma
	var t_actual = d.terreno
	var recurso_actual = str(d.get("recurso", ""))
	for mar_name in Constantes.MARAVILLAS_NATURALES.keys():
		var m_data = Constantes.MARAVILLAS_NATURALES[mar_name]
		var ter_validos = m_data.get("terreno", [])
		var bio_validos = m_data.get("bioma", [])
		var ter_ok = ("TODOS" in ter_validos) or (t_actual in ter_validos)
		var bio_ok = bioma_es_valido(b_actual, bio_validos)
		if not (ter_ok and bio_ok): continue
		# Límite estricto por asentamiento. Si la celda ya tiene esta misma
		# maravilla, su propia instancia no consumiría una plaza adicional.
		var ya = MaravillasNaturales.contar_celdas(city_grid, mar_name)
		if recurso_actual == mar_name:
			ya -= 1
		if ya >= MaravillasNaturales.limite(mar_name): continue
		# Regla de exclusión: dos maravillas naturales distintas nunca pueden
		# ser adyacentes. Si una celda vecina ya contiene una maravilla de
		# distinto nombre, esta no se ofrece: su botón desaparece del panel
		# y la colocación queda bloqueada.
		var bloqueada_por_adyacencia = false
		for coord_vecina in city_grid:
			if HexMath.dist_hex(coord, coord_vecina) != 1: continue
			var d_vecina = city_grid[coord_vecina]
			if d_vecina.get("caracteristica", "") != "NATURAL_WONDER": continue
			var mar_vecina = str(d_vecina.get("recurso", ""))
			if mar_vecina != "" and mar_vecina != mar_name:
				bloqueada_por_adyacencia = true
				break
		if bloqueada_por_adyacencia: continue
		disponibles.append(mar_name)
	return disponibles


func actualizar_panel_maravillas_naturales():
	if not grid_maravillas_naturales: return
	for child in grid_maravillas_naturales.get_children(): child.queue_free()
	
	if not city_grid.has(celda_seleccionada): return
	var d = city_grid[celda_seleccionada]
	if d.get("caracteristica", "") != "NATURAL_WONDER": return

	for mar_name in listar_maravillas_disponibles_celda(celda_seleccionada):
			
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
	if celda_tiene_desarrollo(d) and not MaravillasNaturales.es_maravilla(d):
		for child in grid_biomas.get_children(): child.queue_free()
		for child in grid_carac.get_children(): child.queue_free()
		if grid_terrenos: grid_terrenos.visible = false
		return

	var b_actual = d.bioma
	var t_actual = d.terreno
	var c_actual = d.get("caracteristica", "NONE")
	
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
			# Regla crítica: el floodplain solo se ofrece con río menor presente.
			if d.get("rio", false): valid_c.append("FLOODPLAIN")
		# ... o directamente sobre una celda de río navegable.
		if t_actual == "NAVIGABLE_RIVER":
			valid_c.append("FLOODPLAIN")
		if t_actual == "MOUNTAINOUS":
			valid_c.append("VOLCANO")
		if b_actual == "TUNDRA":
			if not "SNOW" in valid_c: valid_c.append("SNOW")
			if not "ICE" in valid_c: valid_c.append("ICE")

	# La lista de maravillas válidas sustituye al antiguo flag genérico: no se añade
	# "NATURAL_WONDER" a valid_c y no se resetea la característica por ello.
	if c_actual == "NATURAL_WONDER" and d.get("recurso", "") != "":
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
		"ICE": {"txt": "❄️ Ice", "col": Color(0.85, 0.93, 1.0)},
		"SNOW": {"txt": "Snow", "col": Color(1.0, 1.0, 1.0)},
	}
	
	var info_none = carac_ui["NONE"]
	var btn_none = _crear_btn_opcion(info_none.txt, info_none.col, "NONE" == c_actual)
	btn_none.pressed.connect(func(): _aplicar_caracteristica("NONE"))
	grid_carac.add_child(btn_none)
	
	if t_actual == "FLAT" or t_actual == "ROUGH":
		var btn_rio = _crear_btn_opcion("〰️ Minor River", Color(0.2, 0.6, 0.8), d.get("rio", false))
		btn_rio.pressed.connect(_toggle_rio_celda)
		grid_carac.add_child(btn_rio)
		
	# Un botón por cada maravilla natural válida en la celda (bioma/terreno,
	# límite de casillas y exclusión de adyacencia con otra maravilla
	# distinta); las bloqueadas no se listan y su botón desaparece de
	# Features. Ya no existe el botón genérico.
	var nw_disponibles = listar_maravillas_disponibles_celda(celda_seleccionada)
	# Características normales (sin el botón genérico de maravilla).
	for c in valid_c:
		if c == "NONE": continue
		if c == "NATURAL_WONDER": continue
		var info = carac_ui[c]
		var btn = _crear_btn_opcion(info.txt, info.col, c == c_actual)
		btn.tooltip_text = info.txt
		var c_val = c
		btn.pressed.connect(func(): _aplicar_caracteristica(c_val))
		grid_carac.add_child(btn)
	for mar_name in nw_disponibles:
		var tex_nw = resolver_ruta_asset(mar_name)
		var btn_nw = _crear_btn_opcion(mar_name, Color(0.5, 0.0, 0.5), d.get("recurso", "") == mar_name)
		btn_nw.tooltip_text = mar_name
		if tex_nw != "" and ResourceLoader.exists(tex_nw):
			btn_nw.icon = load(tex_nw)
			btn_nw.expand_icon = true
			btn_nw.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var mar_val = mar_name
		btn_nw.pressed.connect(func(): _aplicar_maravilla_natural(mar_val))
		grid_carac.add_child(btn_nw)

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

	# La selección de maravillas se realiza únicamente con los botones
	# individuales válidos generados arriba; no existe un desplegable global.


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
	# Sin escena cargada (arranque headless) el panel aún no existe:
	# no hay nada que refrescar.
	if panel_construccion == null: return
	# BLINDAJE ANTI-ESPECIALISTAS: los especialistas NO son elementos
	# construibles. Su UI (contador X/Y + botones [+] [-]) pertenece en exclusiva
	# al panel de información de la celda, justo debajo de sus rendimientos; si
	# alguna vez quedara colgada de este panel, se retira aquí antes de pintar
	# las listas de mejoras/edificios/maravillas.
	_retirar_fila_especialistas(panel_construccion)
	if grid_mejoras: grid_mejoras.visible = false
	if grid_edificios: grid_edificios.visible = false
	if grid_maravillas: grid_maravillas.visible = false
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
			# Una celda de maravilla natural solo admite "Expedition Base";
			# su nombre se guarda en "recurso", por lo que debe tratarse antes
			# del filtro normal de compatibilidad con recursos.
			var es_maravilla_celda = MaravillasNaturales.es_maravilla(datos_c)
			for mej_nombre in Constantes.DATOS_MEJORAS.keys():
				# Filtro de construibles: la UI de especialistas (y cualquier
				# pseudo-elemento de Constantes.ELEMENTOS_NO_CONSTRUIBLES) NO se
				# construye, así que no puede colarse en esta lista.
				if not ReglasJuego.es_construible(mej_nombre): continue
				var d_mej = Constantes.DATOS_MEJORAS[mej_nombre]

				if d_mej.has("civ") and d_mej.civ != civ_actual and d_mej.civ != civ_sincretismo: continue
				var era_mej = d_mej.get("era", "Antiquity")
				if Constantes.ORDEN_ERAS.get(era_mej, 0) > Constantes.ORDEN_ERAS.get(era_actual, 0): continue

				if mejora_actual != "" and mej_nombre not in ["Abattoir", "Obshchina"]: continue
				if mejora_actual == "" and mej_nombre in ["Abattoir", "Obshchina"]: continue

				if es_maravilla_celda:
					if mej_nombre != MaravillasNaturales.MEJORA_ACTIVACION: continue
				elif recurso_celda != "":
					if not es_mejora_compatible_con_recurso(mej_nombre, recurso_celda, era_actual): continue

				if ReglasJuego.es_mejora_valida(celda_seleccionada, mej_nombre, asent_centro, city_grid, era_actual, civ_actual, asent_tipo, civ_sincretismo):
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
					
			var lista_candidatos = []
			
			for edif_nombre in Constantes.DATOS_EDIFICIOS.keys():
				# Filtro de construibles: los especialistas no son edificios.
				if not ReglasJuego.es_construible(edif_nombre): continue
				var d = Constantes.DATOS_EDIFICIOS[edif_nombre]
				if edif_nombre in ["Palace", "Town Hall"]: continue
				
				var is_wonder = d.get("is_wonder", false)
				var es_muralla = ReglasJuego.es_edificio_muralla(edif_nombre)
				
				var era_edif = d.get("era", "All")
				# Solo edificios de la ERA ACTUAL: los de eras anteriores se
				# retiran del menú. Excepción: los almacenes (Warehouse) de eras
				# anteriores siguen listándose hasta que se construyan (la
				# comprobación de "ya construido" más abajo los oculta después).
				if era_edif != "All":
					var orden_edif = Constantes.ORDEN_ERAS.get(era_edif, 0)
					var orden_actual_panel = Constantes.ORDEN_ERAS.get(era_actual, 0)
					if orden_edif != orden_actual_panel and not (orden_edif < orden_actual_panel and d.get("tipo", "") == "Warehouse"): continue
				if d.has("civ") and d.civ != civ_actual and d.civ != civ_sincretismo: continue
				if ReglasJuego.se_oculta_por_ya_construido(edif_nombre, edificios_construidos): continue
				if edif_nombre in datos_c.edificios: continue
				
				if not ReglasJuego.es_ubicacion_valida_para_edificio(celda_seleccionada, edif_nombre, asent_centro, era_actual, civ_actual, city_grid, asent_tipo, asentamientos): continue
				if datos_c.terreno == "NATURAL_WONDER" or datos_c.get("caracteristica", "") == "NATURAL_WONDER": continue
				
				if not es_muralla:
					var reg_count = 0
					var is_full_tile = d.get("full_tile", false) or edif_nombre in ["Aerodrome", "Rail Station"]
					for e in datos_c.edificios:
						if not ReglasJuego.es_edificio_muralla(e) and not ReglasJuego.es_edificio_obsoleto(e, celda_seleccionada, era_actual, city_grid): reg_count += 1
					if reg_count >= 2 and not is_full_tile: continue
					
				var ady = ReglasJuego.calcular_bono_edificio(celda_seleccionada, edif_nombre, era_actual, city_grid)
				lista_candidatos.append({"nombre": edif_nombre, "ady": ady, "d": d, "wonder": is_wonder})
				
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

			for cand in lista_candidatos:
				var color_borde = Constantes.obtener_color_rendimiento(cand.d.get("rendimiento", ""))
				var tt = obtener_tooltip_edificio(cand.nombre, cand.ady)
				
				if cand.wonder:
					var btn_vb = crear_boton_icono(cand.nombre, "SQUARE", color_borde, tt, cand.nombre, "CONSTRUCCION", false)
					grid_mar_c.add_child(btn_vb)
				else:
					var btn_vb = crear_boton_icono(cand.nombre, "CIRCLE", color_borde, tt, cand.nombre, "CONSTRUCCION", false)
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
	# Blindaje: este panel también lista elementos construibles/externos, nunca
	# la UI de especialistas (que vive en el panel de información de la celda).
	_retirar_fila_especialistas(panel_externos)
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
	# El nombre de una maravilla natural no es un recurso: no debe filtrar
	# mejoras ni bloquear edificios en este panel de exteriores.
	if MaravillasNaturales.es_maravilla(d):
		recurso_celda = ""

	var permitir_mejoras = not tiene_edificio_normal
	var permitir_maravillas = not tiene_edificio_normal

	if permitir_mejoras:
		for mej_nombre in Constantes.DATOS_MEJORAS.keys():
			# Mismo filtro de construibles que el panel de construcción.
			if not ReglasJuego.es_construible(mej_nombre): continue
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
				mejora_valida = ReglasJuego.es_mejora_valida(celda_seleccionada, mej_nombre, asent_centro, city_grid, era_actual, civ_actual, asent_tipo, civ_sincretismo)
				
			if mejora_valida:
				lista_mejoras.append(mej_nombre)
				
	if recurso_celda == "":
		var edificios_construidos_ext = {}
		for c_ext in city_grid.values():
			for e_ext in c_ext.edificios:
				if not ReglasJuego.es_edificio_obsoleto(e_ext, c_ext.q * Vector2i.RIGHT + c_ext.r * Vector2i.DOWN, era_actual, city_grid):
					edificios_construidos_ext[e_ext] = true
		for edif_nombre in Constantes.DATOS_EDIFICIOS.keys():
			# Mismo filtro de construibles que el panel de construcción.
			if not ReglasJuego.es_construible(edif_nombre): continue
			var d_edif = Constantes.DATOS_EDIFICIOS[edif_nombre]
			if edif_nombre in ["Palace", "Town Hall"]: continue
						
			var era_edif = d_edif.get("era", "All")
			# Misma regla que el panel principal: solo la era actual, más los
			# almacenes (Warehouse) de eras anteriores todavía sin construir.
			if era_edif != "All":
				var orden_edif = Constantes.ORDEN_ERAS.get(era_edif, 0)
				var orden_actual_ext = Constantes.ORDEN_ERAS.get(era_actual, 0)
				if orden_edif != orden_actual_ext and not (orden_edif < orden_actual_ext and d_edif.get("tipo", "") == "Warehouse" and not edificios_construidos_ext.has(edif_nombre)): continue
			
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
	if nueva_seccion == "FELICIDAD" and asentamientos.is_empty():
		return
	seccion_actual = nueva_seccion
	if panel_biomas: panel_biomas.visible = (nueva_seccion == "PINCEL")
	if panel_construccion: panel_construccion.visible = (nueva_seccion == "CONSTRUCCION")
	if panel_externos: panel_externos.visible = (nueva_seccion == "EXTERNOS")
	if panel_asentamientos_ui: panel_asentamientos_ui.visible = (nueva_seccion == "ASENTAMIENTOS")
	if panel_maravillas: panel_maravillas.visible = (nueva_seccion == "MARAVILLAS")
	if panel_felicidad:
		panel_felicidad.visible = (nueva_seccion == "FELICIDAD")
	_actualizar_etiqueta_felicidad()
	# La información de celda permanece disponible también en el visor de
	# felicidad: allí es donde la felicidad se integra en la caja de rendimientos.
	var mostrar_info = (nueva_seccion != "ASENTAMIENTOS" and nueva_seccion != "EXTERNOS")

	if panel_info: panel_info.visible = mostrar_info

	if lbl_info:
		lbl_info.visible = mostrar_info
		var padre = lbl_info.get_parent()
		if padre:
			var dyn_node = padre.get_node_or_null("ContenedorInfoDinamico")
			if dyn_node: dyn_node.visible = mostrar_info

	if nueva_seccion == "PINCEL": actualizar_panel_pincel()
	elif nueva_seccion == "MARAVILLAS": actualizar_panel_maravillas_naturales()
	elif nueva_seccion == "CONSTRUCCION":
		actualizar_sugerencias_cache()
		actualizar_panel_construccion()
	elif nueva_seccion == "EXTERNOS": actualizar_panel_externos()
	elif nueva_seccion == "ASENTAMIENTOS": actualizar_panel_gestion_ui()

	actualizar_iconos_todos()
	_actualizar_botones_navegacion()
	actualizar_panel_ui()
	centrar_camara_en_activo()
	queue_redraw()

# Regla única de visibilidad de los botones del panel vertical:
# - El botón de la sección activa se oculta (incluidos Felicidad y Maravillas).
# - Construcción y Externos dependen además de la celda seleccionada:
#   Construcción se oculta en el anillo 4, Externos solo aparece en celda externa
#   válida (anillo >= 2, sin desarrollo propio, con terreno/característica aptos).
# - Maravillas solo existe sobre una maravilla natural (salvo en su propia sección,
#   donde queda oculto por la regla general); Felicidad siempre visible salvo activo.
func _actualizar_botones_navegacion() -> void:
	if btn_menu_asentamientos:
		btn_menu_asentamientos.visible = (seccion_actual != "ASENTAMIENTOS")
		btn_menu_asentamientos.modulate = Color(0.7, 0.7, 0.7)
	if btn_menu_pincel:
		btn_menu_pincel.visible = (seccion_actual != "PINCEL")
		btn_menu_pincel.modulate = Color(0.7, 0.7, 0.7)
	if btn_modo_construccion:
		btn_modo_construccion.modulate = Color(0.7, 0.7, 0.7)
		if seccion_actual == "CONSTRUCCION":
			btn_modo_construccion.visible = false
		else:
			actualizar_visibilidad_boton_construccion()
	if btn_modo_externos:
		btn_modo_externos.modulate = Color(0.7, 0.7, 0.7)
		if seccion_actual == "EXTERNOS":
			btn_modo_externos.visible = false
		else:
			actualizar_visibilidad_boton_externos()
	if btn_menu_felicidad:
		btn_menu_felicidad.visible = (seccion_actual != "FELICIDAD")
		btn_menu_felicidad.modulate = Color(0.7, 0.7, 0.7)
	if btn_menu_maravillas:
		var es_wonder = city_grid.has(celda_seleccionada) and city_grid[celda_seleccionada].get("caracteristica", "") == "NATURAL_WONDER"
		if seccion_actual == "MARAVILLAS":
			btn_menu_maravillas.visible = false
		else:
			btn_menu_maravillas.visible = es_wonder
			if es_wonder:
				btn_menu_maravillas.modulate = Color(0.7, 0.7, 0.7)

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
	# Se RETIRAN ya mismo (remove_child + queue_free) y no solo queue_free():
	# un nodo en cola de borrado sigue en el árbol hasta final de frame y, si se
	# repinta dos veces el mismo frame, colisiona el nombre de la fila de
	# especialistas (Godot la renombraría con un "@..." que rompe las búsquedas
	# por nombre) y se pintarían duplicados de un frame a otro.
	for c in dyn_node.get_children():
		dyn_node.remove_child(c)
		c.queue_free()
	
	var asent_centro = asentamientos[asentamiento_activo_idx].centro if (asentamientos.size() > 0 and asentamiento_activo_idx < asentamientos.size()) else Vector2i.ZERO
	var es_reclamada = d.get("reclamada", HexMath.dist_hex(celda_seleccionada, asent_centro) <= 1)
	
	var es_urbano = false
	var tipo_celda_str = "RURAL"
	var color_fondo_tipo = Color(0.85, 0.2, 0.2)
	if es_reclamada or d.get("ajeno", false):
		es_urbano = _es_celda_urbana(celda_seleccionada)
		tipo_celda_str = "URBAN" if es_urbano else "RURAL"
		color_fondo_tipo = Color(0.2, 0.4, 0.8) if es_urbano else Color(0.85, 0.2, 0.2)
	# Tipo del asentamiento dueño de la celda: es el que decide si puede haber
	# especialistas (solo Ciudades y Capitales; en los pueblos ninguno).
	var tipo_asent_celda: String = ReglasJuego.tipo_asentamiento_de_celda(celda_seleccionada, asentamientos, asentamiento_activo_idx)
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

	# Los rendimientos base de una celda de maravilla sustituyen a los del
	# terreno subyacente y se toman exactamente de Constantes.
	var base_maravilla = MaravillasNaturales.rendimientos_base_celda(d)
	if not base_maravilla.is_empty():
		yields_sum = base_maravilla.duplicate()
	
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
				
				var asent_t: String = ReglasJuego.tipo_asentamiento_de_celda(celda_seleccionada, asentamientos, asentamiento_activo_idx)
				if (asent_t == "City" or asent_t == "Capital") and asentamiento_tiene_agua_dulce(celda_seleccionada):
					yields_sum["Happiness"] += 3 * era_mult
			
			elif Constantes.DATOS_EDIFICIOS.has(edif) and not ReglasJuego.es_edificio_obsoleto(edif, celda_seleccionada, era_actual, city_grid):
				var datos_edif = Constantes.DATOS_EDIFICIOS[edif]
				var rend = datos_edif.get("rendimiento", "")
				var base = datos_edif.get("base", 0)
				var ady = ReglasJuego.calcular_bono_edificio(celda_seleccionada, edif, era_actual, city_grid)
				
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
		# --- ESPECIALISTAS DE ESTA CELDA (mecánica Civ VII) ---
		# ACTIVOS: cada especialista multiplica la adyacencia de los edificios de
		# la celda (+50% de adyacencia base por especialista) y consume -2
		# Alimento. La Felicidad que consume depende de las políticas activas
		# (Ethics / Scholars la elevan a -1 por especialista).
		# EN LETARGO (pueblo, edificio obsoleto o almacén: ver
		# ReglasJuego.especialistas_en_letargo_celda): no aportan adyacencia ni
		# bonos de políticas; solo consumen -1 Alimento y -1 Felicidad cada uno.
		# La celda se sincroniza con su tipo y sus edificios ANTES de leer los
		# asignados, así que los datos nunca quedan desfasados.
		ReglasJuego.sincronizar_especialistas_celda(d, tipo_asent_celda)
		var num_esp_celda: int = int(d.get("especialistas_asignados", 0))
		var esp_en_letargo: bool = ReglasJuego.especialistas_en_letargo_celda(d, tipo_asent_celda, celda_seleccionada, era_actual, city_grid)
		if esp_en_letargo and num_esp_celda > 0 and not es_pincel:
			# LETARGO: sin rendimiento, sin adyacencia y sin bonos de políticas;
			# mantenimiento fijo de -1 Alimento y -1 Felicidad por especialista
			# (sustituye al -2 Alimento normal y a los costes de políticas).
			yields_sum["Food"] = int(yields_sum.get("Food", 0)) + Constantes.ESPECIALISTAS_LETARGO_ALIMENTO * num_esp_celda
			yields_sum["Happiness"] = int(yields_sum.get("Happiness", 0)) + Constantes.ESPECIALISTAS_LETARGO_FELICIDAD * num_esp_celda
		elif num_esp_celda > 0 and not es_pincel:
			var ady_extra_esp := 0.0
			for edif_esp in d.edificios:
				if Constantes.DATOS_EDIFICIOS.has(edif_esp) and not ReglasJuego.es_edificio_obsoleto(edif_esp, celda_seleccionada, era_actual, city_grid):
					ady_extra_esp += float(ReglasJuego.calcular_bono_edificio(celda_seleccionada, edif_esp, era_actual, city_grid)) * Constantes.ESPECIALISTAS_BONO_ADYACENCIA * float(num_esp_celda)
			var rend_esp: String = ""
			for edif_esp in d.edificios:
				if edif_esp == "Palace" or edif_esp == "Town Hall":
					continue
				rend_esp = str(Constantes.DATOS_EDIFICIOS.get(edif_esp, {}).get("rendimiento", ""))
				break
			if rend_esp != "" and yields_sum.has(rend_esp):
				yields_sum[rend_esp] = int(yields_sum[rend_esp]) + int(round(ady_extra_esp))
			yields_sum["Food"] = int(yields_sum.get("Food", 0)) + Constantes.ESPECIALISTAS_ALIMENTO_MANTENIMIENTO * num_esp_celda
			var politicas_celda: Array = GestorPoliticas.politicas_y_tradiciones_activas(era_actual, politicas_activas, tradiciones_activas)
			ReglasJuego.aplicar_bonos_politicas_especialistas(yields_sum, politicas_celda, num_esp_celda)


		
		if d.get("mejora_tipo", "") != "":
			var d_mej = Constantes.DATOS_MEJORAS.get(d.mejora_tipo, {})
			if "yields_on_uniques" in l_bonos_lista and d_mej.has("civ"):
				if yields_sum.has("Culture"): yields_sum["Culture"] += 1 * era_mult
				if yields_sum.has("Gold"): yields_sum["Gold"] += 1 * era_mult
				
		# Las maravillas naturales (features) no cuentan como recursos ni con
		# mejora: su bono procede de natural_wonder_boost, no de este líder.
		if "gold_per_resource" in l_bonos_lista and d.get("recurso", "") != "" and d.get("mejora_tipo", "") != "" and not MaravillasNaturales.es_maravilla(d):
			if yields_sum.has("Gold"): yields_sum["Gold"] += 1 * era_mult
			
		if "natural_wonder_boost" in l_bonos_lista and (d.get("caracteristica", "") == "NATURAL_WONDER" or d.terreno == "NATURAL_WONDER"):
			var nw_count = 0
			for cell in city_grid.values():
				if cell.get("caracteristica", "") == "NATURAL_WONDER" or cell.terreno == "NATURAL_WONDER": nw_count += 1
			for k in yields_sum.keys():
				if yields_sum[k] > 0: yields_sum[k] += int(yields_sum[k] * 0.5 * nw_count)

	# Bono especial de las maravillas activadas con Expedition Base que recae
	# sobre esta celda concreta del asentamiento activo.
	var bonos_maravilla = MaravillasNaturales.rendimientos_especiales_para_celda(city_grid, celda_seleccionada)
	for clave in bonos_maravilla.keys():
		if yields_sum.has(clave):
			yields_sum[clave] = int(yields_sum[clave]) + int(bonos_maravilla[clave])

	# El atractivo de la celda (visor de felicidad) aporta felicidad directa
	# a la caja de rendimientos: Atractivo = +1, Encantador = +2.
	yields_sum["Happiness"] = int(yields_sum.get("Happiness", 0)) + int(d.get("favorita", 0))

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
		# La felicidad se muestra siempre dentro de esta caja, incluso en 0.
		if k == "Happiness" or yields_sum[k] > 0 or yields_sum[k] < 0:
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
	# La caja de rendimientos lleva nombre propio: fija que la fila de
	# especialistas va JUSTO DEBAJO de los rendimientos de la celda (los tests
	# comprueban ese orden por índice de hermanos).
	panel_y.name = Constantes.NODO_CAJA_RENDIMIENTOS_CELDA
	dyn_node.add_child(panel_y)
	
	# --- ESPECIALISTAS DE LA CELDA (mecánica Civ VII) ---
	# La UI de especialistas (contador X/Y + botones [+]/[-]) vive ÚNICA Y
	# EXCLUSIVAMENTE aquí: en el panel de información de la celda, justo debajo
	# de su caja de rendimientos. El panel de construcción NO la pinta nunca:
	# los especialistas no son elementos construibles (ver
	# ReglasJuego.es_construible() y el blindaje de actualizar_panel_construccion).
	_crear_fila_especialistas_celda(dyn_node, celda_seleccionada, d, tipo_asent_celda, es_urbano, es_pincel)

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
		# El panel del pincel no muestra edificios, mejoras ni maravillas
		# construibles: solo se mantienen las maravillas naturales, que se
		# pintan con el pincel y no se construyen.
		if es_pincel and not Constantes.MARAVILLAS_NATURALES.has(edif): continue
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
		
		# El botón [X] se desactiva para los edificios que nunca se eliminan: los
		# centros de gobierno, las murallas (solo se sustituyen por la de la era
		# siguiente) y los OBSOLETOS: estos solo desaparecen si el jugador
		# construye un edificio nuevo encima (sobreconstrucción). Las maravillas
		# construibles SÍ llevan [X] mientras dura la era a la que corresponden;
		# pasado ese plazo quedan como hito permanente.
		var es_wonder = Constantes.DATOS_EDIFICIOS.get(edif, {}).get("is_wonder", false)
		var wonder_fuera_de_era = es_wonder and not ReglasJuego.es_maravilla_borrable_en_era(edif, era_actual)
		var es_no_removible = edif in ["Palace", "Town Hall"] or ReglasJuego.es_edificio_muralla(edif) or wonder_fuera_de_era or is_obsolete
		if not es_no_removible:
			var edif_c = edif
			var btn_del = crear_boton_borrar_estilizado.call(func(): _borrar_edificio_especifico(edif_c))
			hbox_left.add_child(btn_del)
		else:
			# Hueco equivalente sin botón para conservar la alineación del icono.
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(26, 0)
			hbox_left.add_child(spacer)
			
		var asset_name = edif
		if ReglasJuego.es_edificio_muralla(edif): asset_name = edif
		elif Constantes.DATOS_EDIFICIOS.get(edif, {}).get("is_wonder", false):
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
				var asent_t_ext: String = ReglasJuego.tipo_asentamiento_de_celda(celda_seleccionada, asentamientos, asentamiento_activo_idx)
				if (asent_t_ext == "City" or asent_t_ext == "Capital") and asentamiento_tiene_agua_dulce(celda_seleccionada):
					e_yields["Happiness"] = 3 * era_mult
			elif not ReglasJuego.es_edificio_muralla(edif):
				var d_e = Constantes.DATOS_EDIFICIOS.get(edif, {})
				var b_base = d_e.get("base", 0)
				var b_ady = ReglasJuego.calcular_bono_edificio(celda_seleccionada, edif, era_actual, city_grid)
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
		
	# Las mejoras tampoco se muestran en el panel del pincel.
	if d.get("mejora_tipo", "") != "" and not es_pincel:
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
		var rec_btn = str(d.get("recurso", ""))
		# El botón solo aparece sobre un recurso real; las maravillas naturales
		# (features) se gestionan y eliminan desde el panel de Features.
		btn_quitar_recurso.visible = not tiene_desarrollo and rec_btn != "" \
			and not MaravillasNaturales.es_maravilla(d) \
			and not Constantes.MARAVILLAS_NATURALES.has(rec_btn)
		
	# Actualizar el recuento flotante de mejoras permitidas
	actualizar_panel_recuento_mejoras()

# ==============================================================================
# ESPECIALISTAS (mecánica Civ VII): asignación por celda y recálculo
# ==============================================================================
# Los especialistas viven en cada celda urbana (especialistas_asignados, de 0 a
# limite_especialistas). Esta es la ÚNICA puerta de entrada para cambiarlos
# desde la UI: los botones [+]/[-] de la fila ESPECIALISTAS llaman aquí con
# delta +1/-1. Se respeta el intervalo [0, limite], se sincroniza el límite por
# si han cambiado los edificios y se refrescan los rendimientos llamando a
# actualizar_panel_ui() (caja de la celda, que además repinta el panel de
# totales del asentamiento) y actualizar_panel_gestion_ui(), además de guardar
# la partida.
# ------------------------------------------------------------------------------
# FILA DE ESPECIALISTAS DEL PANEL DE INFORMACIÓN DE LA CELDA
# ------------------------------------------------------------------------------
# ÚNICO sitio del juego donde se pinta la UI de especialistas: el panel que
# muestra los rendimientos de la casilla seleccionada, JUSTO DEBAJO de su caja
# de rendimientos. El panel de construcción está blindado contra ella (ver
# actualizar_panel_construccion): los especialistas NO se construyen, se asignan
# con [+] / [-] desde aquí.
#   * Solo se muestra donde la regla lo permite: celda urbana propia con AL
#     MENOS UN edificio real (1 o 2; ni murallas ni maravillas desbloquean) de
#     una Ciudad o Capital; en los pueblos no puede haber especialistas.
#   * El cupo se calcula con la regla (no se lee del guardado), así nunca queda
#     desfasado. X = asignados, Y = cupo de esta celda.
# ------------------------------------------------------------------------------
func _crear_fila_especialistas_celda(dyn_node: Node, coord: Vector2i, d: Dictionary, tipo_asent_celda: String, es_urbano: bool, es_pincel: bool) -> void:
	if dyn_node == null or d == null:
		return
	# PUEBLOS: la UI de especialistas (el texto y los botones [+] y [-]) se oculta
	# por completo. En los Towns no hay interacción activa con especialistas: los
	# que hubiera quedan en LETARGO y despiertan al promocionar el Pueblo a Ciudad.
	# VALIDACIÓN VISUAL ESTRICTA para el PanelInfoCelda (actualizar_panel_ui):
	# si la celda pertenece a un asentamiento de tipo "Town", el nodo contenedor
	# de especialistas se OCULTA explícitamente con .hide() además de no crearse,
	# por si quedara visible de un repintado anterior.
	if not Constantes.ESPECIALISTAS_TIPOS_ASENTAMIENTO.has(tipo_asent_celda):
		# Se recorren los hijos por PREFIJO: si hubo dos repintados en el mismo
		# frame, Godot renombra el nodo duplicado y una búsqueda por nombre
		# exacto se lo perdería.
		for hijo in dyn_node.get_children():
			if str(hijo.name).begins_with(Constantes.NODO_FILA_ESPECIALISTAS):
				hijo.hide()
				dyn_node.remove_child(hijo)
				hijo.queue_free()
		return
	var limite_esp: int = ReglasJuego.limite_especialistas_celda(d, tipo_asent_celda)
	if not es_urbano or limite_esp <= 0 or es_pincel:
		return
	var asignados_esp: int = int(d.get("especialistas_asignados", 0))
	var esp_en_letargo: bool = ReglasJuego.especialistas_en_letargo_celda(d, tipo_asent_celda, coord, era_actual, city_grid)
	var panel_esp = PanelContainer.new()
	panel_esp.name = Constantes.NODO_FILA_ESPECIALISTAS
	panel_esp.tooltip_text = "Especialistas de la celda: se asignan aquí, en el panel de información (no son elementos construibles)."
	var sb_esp = StyleBoxFlat.new()
	sb_esp.bg_color = Color(0.16, 0.14, 0.08)
	sb_esp.border_color = Color(0.75, 0.6, 0.2)
	sb_esp.set_border_width_all(1)
	sb_esp.set_corner_radius_all(6)
	panel_esp.add_theme_stylebox_override("panel", sb_esp)
	var margen_esp = MarginContainer.new()
	margen_esp.add_theme_constant_override("margin_left", 6)
	margen_esp.add_theme_constant_override("margin_right", 6)
	margen_esp.add_theme_constant_override("margin_top", 2)
	margen_esp.add_theme_constant_override("margin_bottom", 2)
	var hbox_esp = HBoxContainer.new()
	hbox_esp.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_esp.add_theme_constant_override("separation", 8)
	var lbl_esp = Label.new()
	var texto_esp := "ESPECIALISTAS %d/%d" % [asignados_esp, limite_esp]
	if esp_en_letargo and asignados_esp > 0:
		texto_esp += " (LETARGO)"
	lbl_esp.text = texto_esp
	lbl_esp.tooltip_text = "Cupo de la celda: cada edificio real aporta 1 y el distrito suma +1 (ningún edificio concreto lo desbloquea; ni murallas ni maravillas tienen especialistas asociados). Solo hay especialistas en celdas con al menos un edificio de una Ciudad o Capital; en los pueblos no puede haber." \
		+ (" Están EN LETARGO (pueblo, edificio obsoleto o almacén): no rinden y consumen -1 Alimento y -1 Felicidad cada uno." if (esp_en_letargo and asignados_esp > 0) else "")
	lbl_esp.add_theme_font_size_override("font_size", 14)
	lbl_esp.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	hbox_esp.add_child(lbl_esp)
	var coord_esp: Vector2i = coord
	var btn_esp_mas = Button.new()
	btn_esp_mas.text = "[+]"
	btn_esp_mas.tooltip_text = "Asignar un especialista (consume Alimento y Felicidad según políticas)"
	btn_esp_mas.custom_minimum_size = Vector2(36, 26)
	btn_esp_mas.pressed.connect(func(): _cambiar_especialistas_celda(coord_esp, 1))
	hbox_esp.add_child(btn_esp_mas)
	var btn_esp_menos = Button.new()
	btn_esp_menos.text = "[-]"
	btn_esp_menos.tooltip_text = "Retirar un especialista de esta celda"
	btn_esp_menos.custom_minimum_size = Vector2(36, 26)
	btn_esp_menos.pressed.connect(func(): _cambiar_especialistas_celda(coord_esp, -1))
	hbox_esp.add_child(btn_esp_menos)
	margen_esp.add_child(hbox_esp)
	panel_esp.add_child(margen_esp)
	dyn_node.add_child(panel_esp)

# Blindaje de los paneles que listan elementos construibles: retira la fila de
# especialistas si alguna vez quedara colgada de ellos. La UI de especialistas
# pertenece en exclusiva al panel de información de la celda.
func _retirar_fila_especialistas(raiz: Node) -> void:
	if raiz == null:
		return
	# Búsqueda por PREFIJO (no por nombre exacto): un segundo repintado en el
	# mismo frame renombra el nodo duplicado y una búsqueda exacta se lo
	# perdería.
	for hijo in raiz.get_children():
		if not str(hijo.name).begins_with(Constantes.NODO_FILA_ESPECIALISTAS):
			continue
		# Fuera del árbol ya mismo (queue_free() solo libera al final del frame,
		# así que el nodo seguiría localizable) y liberada acto seguido.
		raiz.remove_child(hijo)
		hijo.queue_free()

func _cambiar_especialistas_celda(coord: Vector2i, delta: int) -> void:
	if not city_grid.has(coord):
		return
	var datos: Dictionary = city_grid[coord]
	# El cupo puede haber cambiado con los edificios de la celda o con el tipo de
	# asentamiento, así que se sincroniza antes de aplicar el delta para que
	# [+]/[-] nunca se salgan del cupo real.
	var tipo_asent: String = ReglasJuego.tipo_asentamiento_de_celda(coord, asentamientos, asentamiento_activo_idx)
	# PUEBLOS: no hay interacción con especialistas (la fila del panel está
	# oculta). Se corta aquí para que ninguna llamada pueda retirar los que están
	# en letargo: solo despiertan al promocionar el Pueblo a Ciudad.
	if not Constantes.ESPECIALISTAS_TIPOS_ASENTAMIENTO.has(tipo_asent):
		return
	ReglasJuego.sincronizar_especialistas_celda(datos, tipo_asent)
	var limite: int = int(datos["limite_especialistas"])
	var actuales: int = int(datos.get("especialistas_asignados", 0))
	actuales = clampi(actuales + delta, 0, limite)
	datos["especialistas_asignados"] = actuales
	# Enlace con el recálculo de rendimientos: refresca la caja de la celda y
	# los totales del asentamiento, redibuja el mapa y persiste el cambio.
	actualizar_panel_ui()
	actualizar_panel_gestion_ui()
	actualizar_iconos_todos()
	guardar_partida_actual()
	queue_redraw()


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

	# El rendimiento agregado se calcula sobre el grid propio del asentamiento.
	var grid_asent: Dictionary = asent.get("grid", {})
	var celdas_asent: Array = []
	if grid_asent.size() > 0:
		celdas_asent.assign(grid_asent.keys())
	else:
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
		if rec != "" and mej != "" and not MaravillasNaturales.es_maravilla(d_c):
			improved_resources.append(rec)

		var tiene_mejora = (mej != "")
		var tiene_edificios = (d_c.get("edificios", []).size() > 0)
		var es_maravilla = MaravillasNaturales.es_maravilla(d_c)

		# En maravillas, base y bonos especiales se añaden después con el motor
		# para no duplicar ni mezclar los rendimientos del terreno subyacente.
		if not es_maravilla and (tiene_mejora or tiene_edificios):
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
				var ady = ReglasJuego.calcular_bono_edificio(coord, edif, era_actual, city_grid)
				if total_yields.has(rend): total_yields[rend] += base + ady
			elif Constantes.MARAVILLAS_NATURALES.has(edif):
				var w_yields = Constantes.MARAVILLAS_NATURALES[edif].get("yields", {})
				for wk in w_yields.keys():
					if total_yields.has(wk): total_yields[wk] += w_yields[wk]
					
	# --- ESPECIALISTAS DEL ASENTAMIENTO (mecánica Civ VII) ---
	# Bloque FUERA del bucle de celdas: se recorre el asentamiento UNA sola vez
	# (dentro del bucle de rendimientos por celda se duplicaría). Se separan en:
	#   * ACTIVOS: multiplican la adyacencia de los edificios activos de su celda
	#     (+50% por especialista), consumen -2 Alimento y reciben los bonos de
	#     Ethics/Scholars (función centralizada de más abajo).
	#   * EN LETARGO (pueblo, edificio obsoleto o almacén: ver
	#     ReglasJuego.especialistas_en_letargo_celda): no rinden NADA ni reciben
	#     bonos de políticas; solo consumen -1 Alimento y -1 Felicidad cada uno.
	var tipo_asent_actual: String = str(asent.get("tipo", "Town"))
	var esp_activos: int = 0
	var esp_letargo: int = 0
	for coord_esp in celdas_asent:
		if not city_grid.has(coord_esp):
			continue
		var d_esp: Dictionary = city_grid[coord_esp]
		var n_esp: int = int(d_esp.get("especialistas_asignados", 0))
		if n_esp <= 0:
			continue
		if ReglasJuego.especialistas_en_letargo_celda(d_esp, tipo_asent_actual, coord_esp, era_actual, city_grid):
			esp_letargo += n_esp
			total_yields["Food"] = int(total_yields.get("Food", 0)) + Constantes.ESPECIALISTAS_LETARGO_ALIMENTO * n_esp
			total_yields["Happiness"] = int(total_yields.get("Happiness", 0)) + Constantes.ESPECIALISTAS_LETARGO_FELICIDAD * n_esp
			continue
		esp_activos += n_esp
		var ady_extra_asent := 0.0
		var rend_esp_asent := ""
		for edif_esp in d_esp.get("edificios", []):
			if edif_esp == "Palace" or edif_esp == "Town Hall":
				continue
			if Constantes.DATOS_EDIFICIOS.has(edif_esp) and not ReglasJuego.es_edificio_obsoleto(edif_esp, coord_esp, era_actual, city_grid):
				ady_extra_asent += float(ReglasJuego.calcular_bono_edificio(coord_esp, edif_esp, era_actual, city_grid)) * Constantes.ESPECIALISTAS_BONO_ADYACENCIA * float(n_esp)
				if rend_esp_asent == "":
					rend_esp_asent = str(Constantes.DATOS_EDIFICIOS.get(edif_esp, {}).get("rendimiento", ""))
		if rend_esp_asent != "" and total_yields.has(rend_esp_asent):
			total_yields[rend_esp_asent] = int(total_yields[rend_esp_asent]) + int(round(ady_extra_asent))
		total_yields["Food"] = int(total_yields.get("Food", 0)) + Constantes.ESPECIALISTAS_ALIMENTO_MANTENIMIENTO * n_esp
	var num_esp_asent: int = esp_activos + esp_letargo
	# --- BONOS DE POLÍTICAS Y TRADICIONES (función centralizada) ---
	# Intercepta el total del asentamiento ANTES de pintarlo y una sola vez:
	# aplicarlo por celda multiplicaría los bonos por el nº de celdas.
	var politicas_asent: Array = GestorPoliticas.politicas_y_tradiciones_activas(era_actual, politicas_activas, tradiciones_activas)
	var edificios_asent: Array = []
	for coord_bono in celdas_asent:
		if city_grid.has(coord_bono):
			for edif_bono in city_grid[coord_bono].get("edificios", []):
				if not edificios_asent.has(edif_bono):
					edificios_asent.append(edif_bono)
	ReglasJuego.aplicar_bonos_politicas(total_yields, politicas_asent, tipo_asent_actual, esp_activos, edificios_asent)
	# Volcado del total en el propio panel nada más interceptarlo con las
	# políticas: sirve para depurar y es el punto de comprobación de las pruebas
	# (mismo patrón que los set_meta() de los modales). Refleja los rendimientos
	# tras especialistas y políticas, justo antes de sumar las maravillas.
	panel.set_meta("total_yields", total_yields.duplicate(true))
	panel.set_meta("especialistas", num_esp_asent)
	panel.set_meta("especialistas_activos", esp_activos)
	panel.set_meta("especialistas_letargo", esp_letargo)


	# Base y bonos especiales de maravillas, calculados solo con el grid propio.
	var grid_rendimientos: Dictionary = grid_asent
	if grid_rendimientos.is_empty():
		for coord in celdas_asent:
			if city_grid.has(coord):
				grid_rendimientos[coord] = city_grid[coord]
	var rendimientos_maravillas = MaravillasNaturales.rendimientos_totales(grid_rendimientos)
	for clave in rendimientos_maravillas.keys():
		if total_yields.has(clave):
			total_yields[clave] += int(rendimientos_maravillas[clave])

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

	# Nº de especialistas del asentamiento: solo los ACTIVOS activan los bonos de
	# Ethics y Scholars, así que se muestran —junto a los que están en letargo,
	# que siguen costando mantenimiento— justo bajo el total de rendimientos.
	if num_esp_asent > 0:
		var lbl_esp_total = Label.new()
		var texto_esp_total := "ESPECIALISTAS: %d" % num_esp_asent
		if esp_letargo > 0:
			texto_esp_total += " (%d en letargo)" % esp_letargo
		lbl_esp_total.text = texto_esp_total
		lbl_esp_total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_esp_total.add_theme_font_size_override("font_size", 12)
		lbl_esp_total.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
		vbox.add_child(lbl_esp_total)
	
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
	
	var mejoras_permitidas = ["Farm", "Pasture", "Plantation", "Fishing Boat", "Camp", "Woodcutter", "Mine", "Quarry", "Clay Pit", "Expedition Base"]
	var conteo_construidas = {}
	var conteo_disponibles = {}
	for m in mejoras_permitidas:
		conteo_construidas[m] = 0
		conteo_disponibles[m] = 0
		
	for coord in celdas_asent:
		if not city_grid.has(coord): continue
		var d_c = city_grid[coord]
		
		if d_c.get("ajeno", false): continue
		if d_c.get("edificios", []).size() > 0: continue

		var mej_colocada = d_c.get("mejora_tipo", "")
		var es_maravilla_c = MaravillasNaturales.es_maravilla(d_c)
		if es_maravilla_c:
			# Las maravillas solo admiten Expedition Base en este recuento.
			if mej_colocada == MaravillasNaturales.MEJORA_ACTIVACION:
				conteo_construidas[MaravillasNaturales.MEJORA_ACTIVACION] += 1
			elif ReglasJuego.es_mejora_valida(coord, MaravillasNaturales.MEJORA_ACTIVACION, asent_centro, city_grid, era_actual, civ_actual, asent_tipo, civ_sincretismo):
				conteo_disponibles[MaravillasNaturales.MEJORA_ACTIVACION] += 1
			continue

		if mej_colocada != "":
			if mej_colocada in mejoras_permitidas:
				conteo_construidas[mej_colocada] += 1
			continue
			
		var recurso_celda = d_c.get("recurso", "")
		for mej_nombre in mejoras_permitidas:
			if recurso_celda != "" and not es_mejora_compatible_con_recurso(mej_nombre, recurso_celda, era_actual):
				continue
			
			if ReglasJuego.es_mejora_valida(coord, mej_nombre, asent_centro, city_grid, era_actual, civ_actual, asent_tipo, civ_sincretismo):
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
	if nombre_mej == MaravillasNaturales.MEJORA_ACTIVACION:
		txt += "\nActivates this natural wonder's special bonus."
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
		
			
	if ResourceLoader.exists(tex_path):
		var tex = load(tex_path)
		btn.icon = tex
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.expand_icon = true
	else:
		var txt_label = item_name
		btn.text = txt_label.substr(0, 5)
		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_color_override("font_color", Color.WHITE)
		
	vbox.add_child(btn)
	
	var lbl = Label.new()
	if mostrar_texto:
		var display_name = item_name
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

		if seccion_actual == "FELICIDAD":
			# Visor de felicidad: gris = Normal, verde claro = Atractivo, verde oscuro = Encantador.
			# Las Maravillas Naturales se fuerzan a azul oscuro y bloquean la edición con clic.
			# La celda seleccionada conserva su color de estado para no ocultar la información.
			if celda_tiene_maravilla_natural(datos):
				color_base = Color(0.07, 0.13, 0.38)
			else:
				match int(datos.get("favorita", 0)):
					1: color_base = Color(0.56, 0.93, 0.56)
					2: color_base = Color(0.13, 0.54, 0.13)
					_: color_base = Color(0.5, 0.5, 0.5)
		elif coord == celda_seleccionada: color_base = Color.MAGENTA
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

	# Franja azul ancha para terrenos de río navegable: mismo criterio
	# secuencial que el minor river (segmentos entre celdas contiguas y
	# círculo si la celda queda aislada), pero con el doble de ancho.
	var lineas_nav_dibujadas = {}
	for coord in city_grid.keys():
		if city_grid[coord].terreno != "NAVIGABLE_RIVER": continue
		var centro = HexMath.cubo_a_pixel(radio_hex, coord.x, coord.y, -coord.x - coord.y)
		var tiene_vecino_nav = false
		for vec in HexMath.VECINOS_HEX:
			var n = coord + vec
			if city_grid.has(n) and city_grid[n].terreno == "NAVIGABLE_RIVER":
				tiene_vecino_nav = true
				var clave_par = [coord, n] if (coord.x < n.x or (coord.x == n.x and coord.y < n.y)) else [n, coord]
				if not lineas_nav_dibujadas.has(clave_par):
					lineas_nav_dibujadas[clave_par] = true
					var centro_n = HexMath.cubo_a_pixel(radio_hex, n.x, n.y, -n.x - n.y)
					draw_line(centro, centro_n, Color(0.15, 0.55, 0.95), 16.0, true)
		if not tiene_vecino_nav: draw_circle(centro, 12.0, Color(0.15, 0.55, 0.95))

# Superpone el aviso de obsolescencia (⚠️) sobre el arte original de un sello de
# edificio. El nodo hijo queda anclado al borde inferior del contenedor y se
# dimensiona a escala (42% del sello, entre 10 y 16 px) para no tapar el icono:
# el edificio caducado conserva SIEMPRE su icono original.
func _anadir_overlay_obsoleto(contenedor_padre: Control, tam_icono: float) -> void:
	var tam_warn = clampf(tam_icono * 0.42, 10.0, 16.0)
	var path_warning = resolver_ruta_asset("warning")
	var overlay: Control = null
	if path_warning != "" and ResourceLoader.exists(path_warning):
		var tex_warn = TextureRect.new()
		tex_warn.texture = load(path_warning)
		tex_warn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_warn.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		overlay = tex_warn
	else:
		var lbl_warn = Label.new()
		lbl_warn.text = "⚠️"
		lbl_warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_warn.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_warn.add_theme_font_size_override("font_size", int(tam_warn))
		overlay = lbl_warn
	overlay.name = "OverlayObsoleto"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.tooltip_text = "Obsolete"
	# Anclaje al centro del borde inferior del sello (anchors + offsets).
	overlay.anchor_left = 0.5
	overlay.anchor_right = 0.5
	overlay.anchor_top = 1.0
	overlay.anchor_bottom = 1.0
	overlay.offset_left = -tam_warn * 0.5
	overlay.offset_right = tam_warn * 0.5
	overlay.offset_top = -tam_warn
	overlay.offset_bottom = 0.0
	contenedor_padre.add_child(overlay)

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
		
	# El icono de terreno es una etiqueta propia, hija directa del mapa:
	# así su caja y posición no las toca ningún contenedor y el emoji
	# puede centrarse exactamente en el centro de la celda. Si una celda
	# aún tiene el HBoxContainer antiguo, se recrea como Label (mismo
	# criterio defensivo que nodo_icono).
	if not is_instance_valid(datos.get("nodo_terreno")) or not (datos.nodo_terreno is Label):
		if is_instance_valid(datos.get("nodo_terreno")): datos.nodo_terreno.queue_free()
		var lbl_terreno = Label.new()
		lbl_terreno.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_terreno.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_terreno.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(lbl_terreno)
		datos.nodo_terreno = lbl_terreno
	
	# Orden visual del mapa (requisito): los emojis de terreno/features se
	# pintan por DEBAJO; los recursos (nodo_recurso) y las construcciones
	# (nodo_icono: mejoras, edificios y maravillas) se pintan POR ENCIMA.
	datos.nodo_terreno.z_index = 0
	datos.nodo_recurso.z_index = 1
	datos.nodo_icono.z_index = 1
	
	if is_instance_valid(datos.nodo_recurso):
		for child in datos.nodo_recurso.get_children(): child.queue_free()
	if is_instance_valid(datos.nodo_terreno):
		for child in datos.nodo_terreno.get_children(): child.queue_free()
		datos.nodo_terreno.text = ""
	if is_instance_valid(datos.nodo_icono):
		for child in datos.nodo_icono.get_children(): child.queue_free()

	# En el visor de felicidad se ocultan todos los iconos del mapa.
	if seccion_actual == "FELICIDAD":
		if is_instance_valid(datos.get("nodo_icono")):
			datos.nodo_icono.visible = false
		if is_instance_valid(datos.get("nodo_recurso")):
			datos.nodo_recurso.visible = false
		if is_instance_valid(datos.get("nodo_terreno")):
			datos.nodo_terreno.visible = false
		return
	if is_instance_valid(datos.get("nodo_icono")):
		datos.nodo_icono.visible = true
	if is_instance_valid(datos.get("nodo_recurso")):
		datos.nodo_recurso.visible = true
	if is_instance_valid(datos.get("nodo_terreno")):
		datos.nodo_terreno.visible = true
	
	# Crea el nodo visual de un icono y lo devuelve para poder decorarlo después
	# (por ejemplo, superponiendo el aviso de obsolescencia sobre el sello).
	var anadir_elemento_visual = func(container: Control, asset_name: String, nombre_fallback: String, tam_minimo: float, texto_visible: bool = true, tam_fuente: float = 12.0) -> Control:
		var path = ""
		if asset_name != "": path = resolver_ruta_asset(asset_name)
		if path != "" and ResourceLoader.exists(path):
			var texture_rect = TextureRect.new()
			texture_rect.texture = load(path)
			texture_rect.custom_minimum_size = Vector2(tam_minimo, tam_minimo)
			texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			container.add_child(texture_rect)
			return texture_rect
		elif texto_visible:
			var lbl = Label.new()
			lbl.text = nombre_fallback
			lbl.add_theme_font_size_override("font_size", int(tam_fuente))
			lbl.add_theme_color_override("font_color", Color.WHITE)
			container.add_child(lbl)
			return lbl
		return null

	if datos.get("recurso", "") != "" and datos.mejora_tipo == "":
		anadir_elemento_visual.call(datos.nodo_recurso, datos.recurso, datos.recurso, 24.0, true)
	elif datos.get("recurso", "") != "" and datos.mejora_tipo != "":
		anadir_elemento_visual.call(datos.nodo_recurso, datos.recurso, datos.recurso, 24.0, true)
		
	if datos.terreno != "FLAT" or datos.caracteristica in ["WET", "VEGETATED", "FLOODPLAIN"]:
		var txt_icono = Constantes.ICONOS_TERRENO.get(datos.terreno, "")
		if datos.caracteristica == "WET": txt_icono = "💧"
		elif datos.caracteristica == "VEGETATED": txt_icono = "🌲"
		elif datos.caracteristica == "FLOODPLAIN": txt_icono = "🛤️"
		# El río navegable no lleva icono (antes 🚢): lo representa la franja
		# azul ancha que dibuja _draw() en la celda, como el minor river.
		if datos.terreno == "NAVIGABLE_RIVER": txt_icono = ""
		if txt_icono != "" and is_instance_valid(datos.nodo_terreno):
			# Tamaño reducido respecto a la primera versión y caja centrada en
			# la celda; las maravillas naturales conservan su arte (textura a
			# sangre) y solo llevan el icono pequeño encima.
			var es_icono_grande = (datos.terreno in ["ROUGH", "MOUNTAINOUS", "OCEAN", "LAKE"] or datos.caracteristica in ["WET", "VEGETATED"]) and datos.caracteristica != "NATURAL_WONDER"
			var tam_terreno = clampf(radio_hex, 32.0, 54.0) if es_icono_grande else 12.0
			var caja_terreno = Vector2(tam_terreno * 1.5, tam_terreno * 1.5) if es_icono_grande else Vector2(20, 20)
			datos.nodo_terreno.add_theme_font_size_override("font_size", int(tam_terreno))
			datos.nodo_terreno.text = txt_icono
			datos.nodo_terreno.size = caja_terreno
			datos.nodo_terreno.position = centro_px - caja_terreno * 0.5
		
	var edificios_visibles = []
	for edif in datos.edificios:
		if ReglasJuego.es_edificio_muralla(edif): continue
		# Con el visor de pincel activo no se pintan sellos de edificios ni
		# de maravillas construibles en el mapa; las maravillas naturales sí
		# se quedan (se pintan con el pincel, no se construyen).
		if seccion_actual == "PINCEL" and not Constantes.MARAVILLAS_NATURALES.has(edif): continue
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
			# Un edificio obsoleto NO se sustituye por el aviso: conserva su arte
			# original y el ⚠️ se superpone como nodo hijo (OverlayObsoleto)
			# anclado al borde inferior del sello.
			var es_obsoleto = ReglasJuego.es_edificio_obsoleto(edif, coord, era_actual, city_grid)
			var asset_name = edif
			var es_maravilla = Constantes.DATOS_EDIFICIOS.get(edif, {}).get("is_wonder", false)
			var es_maravilla_natural = Constantes.MARAVILLAS_NATURALES.has(edif)

			if edif == "Palace" or edif == "Town Hall": asset_name = "palace" if edif == "Palace" else "city_hall"
			elif es_maravilla and not ResourceLoader.exists(resolver_ruta_asset(asset_name)): asset_name = "wonder"

			if es_obsoleto:
				# Contenedor del sello: arte original a pantalla completa + overlay ⚠️.
				var sello_obsoleto = Control.new()
				sello_obsoleto.custom_minimum_size = Vector2(size_edif, size_edif)
				sello_obsoleto.mouse_filter = Control.MOUSE_FILTER_IGNORE
				var icono_obsoleto = anadir_elemento_visual.call(sello_obsoleto, asset_name, edif, size_edif, true)
				if is_instance_valid(icono_obsoleto):
					icono_obsoleto.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
					if icono_obsoleto is Label:
						icono_obsoleto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
						icono_obsoleto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
					icono_obsoleto.tooltip_text = edif + " (obsolete)"
				_anadir_overlay_obsoleto(sello_obsoleto, size_edif)
				datos.nodo_icono.add_child(sello_obsoleto)
			elif es_maravilla_natural:
				# Las maravillas naturales conservan su arte a sangre sobre la celda.
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
	# Las mejoras no se pintan en el mapa con el visor de pincel activo.
	elif datos.mejora_tipo != "" and seccion_actual != "PINCEL":
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
		# Aconsejador de rendimientos: la caché llega ordenada de mayor a menor
		# adyacencia, así que solo hay que traducir cada entrada a su icono de
		# rendimiento (uno por rendimiento y celda, sin duplicados). Los iconos
		# se agrupan en un HBoxContainer centrado en la ZONA SUPERIOR de la
		# celda (alineación Top), con tamaño reducido para que quepan 4-5 en
		# una sola fila sin tapar el centro de la casilla.
		if sugerencias_cache.has(coord):
			var iconos_agregados = {}
			var iconos_sug = []
			for sug in sugerencias_cache[coord]:
				var rend_sug = str(sug.get("rendimiento", ""))
				var asset_sug = obtener_nombre_asset_rendimiento(rend_sug)
				if asset_sug == "" or iconos_agregados.has(asset_sug): continue
				iconos_agregados[asset_sug] = true
				iconos_sug.append(asset_sug)

			if iconos_sug.size() > 0:
				var num = iconos_sug.size()
				# Fila única en la banda superior: ancho útil del hexágono
				# (pointy-top) donde la celda conserva su ancho pleno.
				var ancho_util = radio_hex * 1.7
				var sep = 2.0
				var tam_icono = clampf((ancho_util - (num - 1) * sep) / num, 8.0, 14.0)
				var ancho_total = num * tam_icono + (num - 1) * sep

				var hbox_sug = HBoxContainer.new()
				hbox_sug.alignment = BoxContainer.ALIGNMENT_CENTER
				hbox_sug.add_theme_constant_override("separation", int(sep))
				hbox_sug.custom_minimum_size = Vector2(ancho_total, tam_icono)
				hbox_sug.mouse_filter = Control.MOUSE_FILTER_IGNORE

				for asset_sug in iconos_sug:
					var icono_sug = anadir_elemento_visual.call(hbox_sug, asset_sug, "", tam_icono, false)
					if is_instance_valid(icono_sug): icono_sug.mouse_filter = Control.MOUSE_FILTER_IGNORE

				# Contenedor de una sola columna anclado arriba (Top) y centrado.
				datos.nodo_icono.columns = 1
				datos.nodo_icono.add_theme_constant_override("h_separation", 0)
				datos.nodo_icono.add_theme_constant_override("v_separation", 0)
				datos.nodo_icono.custom_minimum_size = Vector2(ancho_total, tam_icono)
				datos.nodo_icono.position = Vector2(centro_px.x - ancho_total * 0.5, centro_px.y - radio_hex * 0.5)
				datos.nodo_icono.size = Vector2(ancho_total, tam_icono)
				datos.nodo_icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
				datos.nodo_icono.add_child(hbox_sug)

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
			if seccion_actual == "FELICIDAD":
				ciclar_felicidad_celda(hex)
				return
			actualizar_botones_recursos_ui()
			actualizar_panel_pincel()
			actualizar_panel_construccion()
			actualizar_panel_externos()
			_actualizar_botones_navegacion()
			actualizar_panel_ui()
			queue_redraw()
			
# Detecta si una celda contiene una Maravilla Natural (por característica o por terreno).
func celda_tiene_maravilla_natural(d: Dictionary) -> bool:
	if d.get("caracteristica", "") == "NATURAL_WONDER": return true
	return str(d.get("terreno", "")).strip_edges().to_upper() == "NATURAL_WONDER"


func ciclar_felicidad_celda(coord: Vector2i) -> void:
	if not city_grid.has(coord): return
	var d = city_grid[coord]
	# Bloqueo de edición: la felicidad de una Maravilla Natural no se puede ciclar.
	if celda_tiene_maravilla_natural(d):
		_actualizar_etiqueta_felicidad()
		queue_redraw()
		return
	d.favorita = (int(d.get("favorita", 0)) + 1) % 3
	_actualizar_etiqueta_felicidad()
	actualizar_iconos_todos()
	actualizar_panel_ui()
	guardar_partida_actual()
	queue_redraw()


func _actualizar_etiqueta_felicidad() -> void:
	if not panel_felicidad or not panel_felicidad.visible: return
	var lbl_fel = panel_felicidad.get_node_or_null("LblFelicidadInfo")
	if not lbl_fel: return
	var f = int(city_grid[celda_seleccionada].get("favorita", 0)) if city_grid.has(celda_seleccionada) else 0
	var nombre = ["Normal", "Atractivo", "Encantador"][clampi(f, 0, 2)]
	if city_grid.has(celda_seleccionada) and celda_tiene_maravilla_natural(city_grid[celda_seleccionada]):
		lbl_fel.text = "Celda: %s (Maravilla Natural).\nEdición de felicidad bloqueada: el clic no cambia su estado.\nColor azul oscuro fijo en el visor." % str(celda_seleccionada)
	else:
		lbl_fel.text = "Celda: %s (%s).\nClica para ciclar: Normal → Atractivo → Encantador.\nGris = Normal, verde claro = Atractivo, verde oscuro = Encantador." % [str(celda_seleccionada), nombre]


func actualizar_visibilidad_boton_construccion():
	if not btn_modo_construccion: return
	if asentamientos.size() == 0 or asentamiento_activo_idx >= asentamientos.size(): return
	var asent_centro = asentamientos[asentamiento_activo_idx].centro
	var dist = HexMath.dist_hex(celda_seleccionada, asent_centro)
	var es_ring_4 = (dist == 4)

	# La sección activa siempre oculta su propio botón.
	if seccion_actual == "CONSTRUCCION":
		btn_modo_construccion.visible = false
		if es_ring_4:
			cambiar_seccion("EXTERNOS" if es_celda_externos_valida() else "ASENTAMIENTOS")
		return

	btn_modo_construccion.visible = not es_ring_4

# ==============================================================================
# PANTALLAS (partidas guardadas y estadísticas)
# ==============================================================================

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
	if mostrar:
		# Al reactivar la navegación se aplica la regla general: cada botón
		# conserva su lógica de aparición y el de la sección activa se oculta.
		_actualizar_botones_navegacion()
		return
	if btn_menu_pincel: btn_menu_pincel.visible = false
	if btn_menu_asentamientos: btn_menu_asentamientos.visible = false
	if btn_menu_maravillas: btn_menu_maravillas.visible = false
	if btn_modo_construccion: btn_modo_construccion.visible = false
	if btn_modo_externos: btn_modo_externos.visible = false
	if btn_menu_felicidad: btn_menu_felicidad.visible = false


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

# ==============================================================================
# MÓDULOS INTERNOS (antes scripts sueltos cargados como autoloads)
# ------------------------------------------------------------------------------
# Se mantienen como clases anidadas con métodos estáticos para no depender de
# autoloads y para que cada regla exista UNA sola vez. Todos los métodos reciben
# la instancia principal como primer parámetro ("main"), por lo que conservan
# exactamente la misma firma y comportamiento que cuando eran archivos aparte.
#   MaravillasNaturales : motor puro de reglas de maravillas naturales.
#   HexMath             : conversiones y distancias hexagonales.
#   ReglasJuego         : reglas puras (rendimientos, obsolescencia, validaciones).
#   GestorPincel        : edición de celdas (bioma, terreno, recurso, río, maravillas).
#   GestorConstruccion  : edificios, mejoras, contenido externo y sugerencias.
#   GestorAsentamientos : asentamientos, capital y cambio de era.
#   GestorArchivos      : persistencia JSON y diálogos de guardado/carga.
#   GestorDialogos      : diálogos modales (líder, nueva partida, era, sincretismo).
#   GestorInterfaz      : construcción del árbol de interfaz.
# ==============================================================================

class MaravillasNaturales:
	# ==============================================================================
	# MARAVILLAS NATURALES - MOTOR DE REGLAS PURO
	# ------------------------------------------------------------------------------
	# Todas las funciones reciben EXCLUSIVAMENTE el grid de un asentamiento.
	# Nunca se mezclan los grids de dos asentamientos: así dos ciudades cuyos
	# radios se solapan pueden reclamar celdas distintas de la misma maravilla sin
	# interferir en límites, activación ni cálculos de bonificación.
	#
	#  - El límite "casillas" es por asentamiento y por tipo de maravilla.
	#  - Los rendimientos base proceden intactos de "yields".
	#  - El bono especial requiere mejora_tipo == "Expedition Base".
	#  - El efecto especial se aplica una vez por cada celda activada.
	#  - No existe exclusividad global entre maravillas distintas.
	# ==============================================================================

	const MEJORA_ACTIVACION := "Expedition Base"
	const AGUA_DULCE := ["Gullfoss", "Iguazú Falls"]
	const SOLO_RENDIMIENTOS_BASE := [
		"Mount Everest",
		"Mount Fuji",
		"Mount Kilimanjaro",
		"Nachi Falls",
		"Thera",
		"Valley of Flowers",
		"Vihren"
	]
	const VECINOS_HEX := [
		Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1),
		Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1)
	]

	static func es_maravilla(datos: Dictionary) -> bool:
		return datos.get("caracteristica", "") == "NATURAL_WONDER" \
			or datos.get("terreno", "") == "NATURAL_WONDER"

	static func nombre_maravilla(datos: Dictionary) -> String:
		if not es_maravilla(datos):
			return ""
		var nombre := str(datos.get("recurso", ""))
		return nombre if Constantes.MARAVILLAS_NATURALES.has(nombre) else ""

	static func celda_activada(datos: Dictionary) -> bool:
		return nombre_maravilla(datos) != "" and datos.get("mejora_tipo", "") == MEJORA_ACTIVACION

	static func limite(nombre: String) -> int:
		return int(Constantes.MARAVILLAS_NATURALES.get(nombre, {}).get("casillas", 1))

	static func contar_celdas(grid: Dictionary, nombre: String) -> int:
		var total := 0
		for datos in grid.values():
			if nombre_maravilla(datos) == nombre:
				total += 1
		return total

	static func puede_colocar(grid: Dictionary, nombre: String) -> bool:
		return contar_celdas(grid, nombre) < limite(nombre)

	static func celdas_activadas(grid: Dictionary) -> Array:
		var resultado := []
		for coord in grid.keys():
			if celda_activada(grid[coord]):
				resultado.append(coord)
		return resultado

	static func conteo_activaciones(grid: Dictionary) -> Dictionary:
		var conteo := {}
		for coord in celdas_activadas(grid):
			var nombre := nombre_maravilla(grid[coord])
			conteo[nombre] = int(conteo.get(nombre, 0)) + 1
		return conteo

	static func rendimientos_base_celda(datos: Dictionary) -> Dictionary:
		var nombre := nombre_maravilla(datos)
		if nombre == "":
			return {}
		return _copiar_rendimiento(Constantes.MARAVILLAS_NATURALES[nombre].get("yields", {}))

	static func otorga_agua_dulce(grid: Dictionary) -> bool:
		for nombre in conteo_activaciones(grid).keys():
			if nombre in AGUA_DULCE:
				return true
		return false

	static func multiplicador_produccion_caballeria(grid: Dictionary) -> float:
		return 1.0 + (0.2 * int(conteo_activaciones(grid).get("Seongsan Ilchulbong", 0)))

	# Bono especial atribuido a UNA celda concreta del asentamiento.
	static func rendimientos_especiales_para_celda(grid: Dictionary, coord: Vector2i) -> Dictionary:
		var total := _rendimientos_vacios()
		if not grid.has(coord):
			return total

		var destino: Dictionary = grid[coord]
		for origen_coord in celdas_activadas(grid):
			var origen: Dictionary = grid[origen_coord]
			var aplicacion := _aplicaciones_para(
				nombre_maravilla(origen),
				destino,
				origen_coord,
				coord,
				grid
			)
			for clave in aplicacion.keys():
				total[clave] = int(total.get(clave, 0)) + int(aplicacion[clave])
		return total

	# Base + especiales de todo el asentamiento, usando únicamente su propio grid.
	static func rendimientos_totales(grid: Dictionary) -> Dictionary:
		var total := _rendimientos_vacios()
		for coord in grid.keys():
			_merge(total, rendimientos_base_celda(grid[coord]))
			_merge(total, rendimientos_especiales_para_celda(grid, coord))
		return total

	static func _aplicaciones_para(
		nombre: String,
		destino: Dictionary,
		origen_coord: Vector2i,
		destino_coord: Vector2i,
		grid: Dictionary
	) -> Dictionary:
		var aplicacion := _rendimientos_vacios()
		if nombre == "":
			return aplicacion

		# --- BONOS QUE AMPLIAN TODO EL ASENTAMIENTO ---
		match nombre:
			"Bermuda Triangle":
				if _es_costero(destino):
					aplicacion.Science = 1
			"Grand Canyon":
				if _es_llano(destino):
					aplicacion.Science = 1
			"Machapuchare":
				if _es_rough(destino) or _es_montana(destino):
					aplicacion.Happiness = 1
			"Mapu 'a Vaea Blowholes":
				if _es_costero(destino):
					aplicacion.Culture = 2
			"Redwood Forest":
				if _es_vegetado(destino):
					aplicacion.Science = 1
					aplicacion.Culture = 1
			"Torres del Paine":
				if _es_tundra(destino):
					aplicacion.Food = 1
					aplicacion.Production = 1
			"Uluru":
				if _es_desierto(destino):
					aplicacion.Culture = 2
			"Zhangjiajie":
				if _es_rough(destino):
					aplicacion.Culture = 2

		# Vinicunca acumula +2 Culture en su propia celda por cada rural vecina.
		if nombre == "Vinicunca":
			if origen_coord == destino_coord:
				var rurales := 0
				for vec in VECINOS_HEX:
					var n: Vector2i = origen_coord + vec
					if grid.has(n) and _es_rural(grid[n]):
						rurales += 1
				aplicacion.Culture = 2 * rurales
			return aplicacion

		# --- BONOS POR ADYACENCIA ---
		if origen_coord == destino_coord or not _es_adyacente(origen_coord, destino_coord):
			return aplicacion

		match nombre:
			"Great Barrier Reef":
				if _es_agua_aplicable(destino):
					aplicacion.Science = 2
			"Great Blue Hole":
				if _es_rural(destino) and _es_marino(destino):
					aplicacion.Culture = 2
			"Gullfoss":
				if _es_rural(destino):
					aplicacion.Culture = 1
					aplicacion.Production = 1
			"Hoerikwaggo":
				if _es_distrito(destino):
					aplicacion.Happiness = 2
			"Iguazú Falls":
				if _es_distrito(destino):
					aplicacion.Production = 2

		return aplicacion

	static func _es_adyacente(a: Vector2i, b: Vector2i) -> bool:
		for vec in VECINOS_HEX:
			if a + vec == b:
				return true
		return false

	static func _es_costero(d: Dictionary) -> bool:
		return str(d.get("terreno", "")).to_upper() in ["COASTAL", "COSTA"]

	static func _es_llano(d: Dictionary) -> bool:
		return str(d.get("terreno", "")).to_upper() in ["FLAT", "PLANO"]

	static func _es_rough(d: Dictionary) -> bool:
		return str(d.get("terreno", "")).to_upper() in ["ROUGH", "ABRUPTO"]

	static func _es_montana(d: Dictionary) -> bool:
		return str(d.get("terreno", "")).to_upper() in ["MOUNTAINOUS", "MONTAÑA"]

	static func _es_vegetado(d: Dictionary) -> bool:
		return str(d.get("caracteristica", "")).to_upper() in ["VEGETATED", "VEGETACION"]

	static func _es_tundra(d: Dictionary) -> bool:
		return str(d.get("bioma", "")).to_upper() == "TUNDRA"

	static func _es_desierto(d: Dictionary) -> bool:
		return str(d.get("bioma", "")).to_upper() == "DESERT"

	static func _es_agua_aplicable(d: Dictionary) -> bool:
		return str(d.get("terreno", "")).to_upper() in [
			"LAKE", "LAGO", "COASTAL", "COSTA", "OCEAN", "OCEANO"
		]

	static func _es_marino(d: Dictionary) -> bool:
		return str(d.get("bioma", "")).to_upper() == "MARINE" \
			or str(d.get("terreno", "")).to_upper() in ["COASTAL", "COSTA", "OCEAN", "OCEANO"]

	static func _es_rural(d: Dictionary) -> bool:
		return d.get("edificios", []).is_empty()

	static func _es_distrito(d: Dictionary) -> bool:
		var edificios: Array = d.get("edificios", [])
		var estandar := 0
		for edificio in edificios:
			if edificio in ["Ancient Walls", "Medieval Walls", "Modern Walls"]:
				continue
			var datos_edif: Dictionary = Constantes.DATOS_EDIFICIOS.get(edificio, {})
			if datos_edif.get("full_tile", false):
				return true
			estandar += 1
		return estandar >= 2

	static func _rendimientos_vacios() -> Dictionary:
		return {
			"Food": 0,
			"Production": 0,
			"Gold": 0,
			"Culture": 0,
			"Science": 0,
			"Happiness": 0,
			"Influence": 0
		}

	static func _copiar_rendimiento(origen: Dictionary) -> Dictionary:
		var resultado := _rendimientos_vacios()
		for clave in resultado.keys():
			resultado[clave] = int(origen.get(clave, 0))
		return resultado

	static func _merge(destino: Dictionary, origen: Dictionary) -> void:
		for clave in origen.keys():
			destino[clave] = int(destino.get(clave, 0)) + int(origen[clave])


class HexMath:

	const VECINOS_HEX = [
		Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1), 
		Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1)
	]

	static func dist_hex(coord1: Vector2i, coord2: Vector2i) -> int:
		var diff = coord1 - coord2
		return max(abs(diff.x), abs(diff.y), abs(-diff.x - diff.y))

	static func cubo_a_pixel(radio_hex: float, q: int, r: int, _s: int) -> Vector2:
		var x = radio_hex * (sqrt(3.0) * q + sqrt(3.0)/2.0 * r)
		var y = radio_hex * (3.0/2.0 * r)
		return Vector2(x, y)

	static func pixel_a_cubo(radio_hex: float, punto_pantalla: Vector2) -> Vector2i:
		var q = (sqrt(3.0)/3.0 * punto_pantalla.x - 1.0/3.0 * punto_pantalla.y) / radio_hex
		var r = (2.0/3.0 * punto_pantalla.y) / radio_hex
		var s = -q - r
		var rq = round(q)
		var rr = round(r)
		var rs = round(s)
		var q_diff = abs(rq - q)
		var r_diff = abs(rr - r)
		var s_diff = abs(rs - s)
		if q_diff > r_diff and q_diff > s_diff: rq = -rr - rs
		elif r_diff > s_diff: rr = -rq - rs
		else: rs = -rq - rr
		return Vector2i(int(rq), int(rr))

	static func obtener_puntos_hex(centro: Vector2, radio_hex: float, escala: float = 1.0) -> PackedVector2Array:
		var puntos = PackedVector2Array()
		for i in range(6):
			var angulo_deg = 60 * i - 30
			var angulo_rad = deg_to_rad(angulo_deg)
			puntos.push_back(centro + Vector2(radio_hex * escala * cos(angulo_rad), radio_hex * escala * sin(angulo_rad)))
		return puntos


class ReglasJuego:

	static func obtener_denominacion_celda(bioma: String, terreno: String, caracteristica: String) -> String:
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

	# ---------------------------------------------------------------------------
	# RECURSOS (DATOS_RECURSOS)
	# ---------------------------------------------------------------------------
	# Devuelve true si el recurso admite esa mejora en la era indicada.
	static func recurso_compatible_con_mejora(recurso: String, mejora: String, era: String) -> bool:
		var d_rec = Constantes.DATOS_RECURSOS.get(recurso, {})
		if d_rec.is_empty(): return false
		if d_rec.get("mejora", "") != mejora: return false
		return era in d_rec.get("eras", [])

	# Regla crítica: un floodplain solo puede existir sobre una celda con río
	# menor (llanura + rio) o sobre una celda de río navegable.
	static func es_floodplain_permitida(terreno: String, rio: bool) -> bool:
		return terreno == "NAVIGABLE_RIVER" or (terreno == "FLAT" and rio)

	# Validez de un recurso para una celda según DATOS_RECURSOS: era (si se
	# indica), features_validas (denominación canónica de la celda) y
	# terrenos_validos. ICE y NATURAL_WONDER nunca admiten recursos.
	static func es_recurso_valido_en_celda(recurso: String, datos: Dictionary, era_actual: String = "") -> bool:
		var d_rec = Constantes.DATOS_RECURSOS.get(recurso, {})
		if d_rec.is_empty(): return false
		if era_actual != "" and not (era_actual in d_rec.get("eras", [])): return false

		var carac = str(datos.get("caracteristica", "NONE"))
		if carac in ["ICE", "NATURAL_WONDER"]: return false

		var bioma = str(datos.get("bioma", ""))
		var terreno = str(datos.get("terreno", ""))
		# Una celda de maravilla natural (por terreno) tampoco admite recursos.
		if terreno == "NATURAL_WONDER": return false
		var nom_celda = obtener_denominacion_celda(bioma, terreno, carac)

		for f in d_rec.get("features_validas", []):
			if str(f) == "Floodplains":
				if carac == "FLOODPLAIN": return true
			elif str(f) == nom_celda:
				return true

		for t_entry in d_rec.get("terrenos_validos", []):
			var e = str(t_entry).to_upper()
			if e == "COASTAL" or e == "LAKE" or e == "OCEAN":
				if terreno == e: return true
			elif e == "NAVIGABLE RIVER":
				if terreno == "NAVIGABLE_RIVER": return true
			elif e == "FLAT":
				if terreno == "FLAT" and carac == "NONE": return true
			elif e == "ROUGH":
				if terreno == "ROUGH" and carac == "NONE": return true
			elif e.begins_with("FLAT "):
				if terreno == "FLAT" and carac == "NONE" and bioma == e.substr(5): return true
			elif e.begins_with("ROUGH "):
				if terreno == "ROUGH" and carac == "NONE" and bioma == e.substr(6): return true
			elif terreno in ["FLAT", "ROUGH"] and carac == "NONE" and bioma == e:
				return true
		return false

	static func calcular_rendimiento_celda(bioma: String, terreno: String, caracteristica: String, recurso: String, _rio: bool, _era_actual: String) -> Dictionary:
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
			var d_recurso = Constantes.DATOS_RECURSOS.get(recurso)
			if d_recurso == null:
				# Solo valores legados: una maravilla natural no es un recurso,
				# sus rendimientos proceden de MARAVILLAS_NATURALES.
				if not Constantes.MARAVILLAS_NATURALES.has(recurso):
					rendimiento.Gold += 1
			else:
				var r = d_recurso.get("rendimiento", {})
				var lista_r = r if r is Array else [r]
				for parte in lista_r:
					var tipo_r = str(parte["tipo"])
					rendimiento[tipo_r] = rendimiento.get(tipo_r, 0) + int(parte["cantidad"])

		return rendimiento

	# Se eliminan los edificios de Fortificación estándar, limitando Murallas a las estructurales.
	static func es_edificio_muralla(nombre: String) -> bool:
		return nombre in ["Ancient Walls", "Medieval Walls", "Modern Walls"]

	# Puentes (Ancient/Medieval/Modern Bridge): ocupan toda la celda
	# (ocupación exclusiva) y no tienen límite de cantidad por asentamiento.
	static func es_edificio_puente(nombre: String) -> bool:
		return nombre in ["Ancient Bridge", "Medieval Bridge", "Modern Bridge"]

	# --------------------------------------------------------------------------
	# ¿Es un elemento CONSTRUIBLE? Solo lo son los que tienen datos de edificio o
	# de mejora en Constantes. Los pseudo-elementos de CELDA (la fila de
	# ESPECIALISTAS y compañía: Constantes.ELEMENTOS_NO_CONSTRUIBLES) NO se
	# construyen: se asignan con [+] / [-] en el panel de información de la celda.
	# Es el filtro único que aplican el panel de construcción, el panel de
	# externos y el aconsejador de rendimientos antes de listar o recomendar algo.
	# --------------------------------------------------------------------------
	static func es_construible(nombre: String) -> bool:
		var limpio := str(nombre).strip_edges()
		if limpio == "":
			return false
		if limpio.to_lower() in Constantes.ELEMENTOS_NO_CONSTRUIBLES:
			return false
		return Constantes.DATOS_EDIFICIOS.has(limpio) or Constantes.DATOS_MEJORAS.has(limpio)

	# Un edificio ya construido se oculta del menú de construcción, salvo:
	#  * Maravillas: irrepetibles (se ocultan por eso, no por límite).
	#  * Murallas: upgrade por era, se reemplazan entre sí.
	#  * Puentes: sin límite; caben tantos como celdas de río navegable.
	static func se_oculta_por_ya_construido(nombre: String, ya_construidos: Dictionary) -> bool:
		if not ya_construidos.has(nombre): return false
		if Constantes.DATOS_EDIFICIOS.get(nombre, {}).get("is_wonder", false): return false
		if es_edificio_muralla(nombre): return false
		if es_edificio_puente(nombre): return false
		return true

	# Una Maravilla Construible solo puede borrarse con el [X] mientras dura la
	# era a la que corresponden (dato "era" == era actual). Pasada esa era
	# queda como hito permanente del mapa: no se elimina ni se sobreconstruye.
	# Devuelve false si no es una maravilla: esta regla solo aplica a ellas.
	static func es_maravilla_borrable_en_era(nombre: String, era_actual: String) -> bool:
		if not Constantes.DATOS_EDIFICIOS.has(nombre): return false
		var d = Constantes.DATOS_EDIFICIOS[nombre]
		if not d.get("is_wonder", false): return false
		var era_maravilla = str(d.get("era", "All"))
		return era_maravilla == "All" or era_maravilla == era_actual

	# Excepciones de la transición de era (mantienen rendimientos y adyacencias):
	#   * Maravillas construibles: nunca caducan mientras existan sobre el mapa.
	#   * Murallas (Ancient/Medieval/Modern Walls): solo desaparecen si el jugador
	#     las sobreconstruye con la muralla de la era siguiente (upgrade).
	#   * Almacenes (tipo "Warehouse"): rendimientos permanentes.
	#   * Academy y Amphitheater marcados como Edad de Oro (edificios_dorados).
	static func es_edificio_obsoleto(nombre: String, coord: Vector2i, era_actual: String, city_grid: Dictionary) -> bool:
		if not Constantes.DATOS_EDIFICIOS.has(nombre): return false
		var d = Constantes.DATOS_EDIFICIOS[nombre]

		if d.get("is_wonder", false): return false
		if es_edificio_muralla(nombre): return false
		if nombre in ["Academy", "Amphitheater"] and city_grid.has(coord) and city_grid[coord].get("edificios_dorados", []).has(nombre): return false
		if d.get("tipo", "") == "Warehouse": return false
	
		var era_edif = d.get("era", "All")
		if era_edif == "All": return false
		if Constantes.ORDEN_ERAS.get(era_edif, 0) >= Constantes.ORDEN_ERAS.get(era_actual, 0): return false
	
		return true

	static func es_mejora_valida(coord: Vector2i, mejora_nombre: String, asent_centro: Vector2i, city_grid: Dictionary, era_actual: String = "Antiquity", civ_actual: String = "None", tipo_asentamiento: String = "Town", civ_sincretismo: String = "None") -> bool:
		if not city_grid.has(coord): return false
		if city_grid[coord].get("ajeno", false): return false

		var datos = city_grid[coord]
		# Maravillas naturales: solo admiten la base de expedición, y este caso
		# se resuelve antes de las restricciones generales de anillo/era para
		# garantizar que toda celda de maravilla reclamada pueda activarse.
		var es_maravilla_natural = (datos.get("caracteristica", "") == "NATURAL_WONDER" or datos.get("terreno", "") == "NATURAL_WONDER")
		if es_maravilla_natural:
			var mejora_actual = str(datos.get("mejora_tipo", ""))
			return mejora_nombre == MaravillasNaturales.MEJORA_ACTIVACION \
				and mejora_actual in ["", MaravillasNaturales.MEJORA_ACTIVACION]

		if HexMath.dist_hex(coord, asent_centro) > 3: return false


		var t = datos.get("terreno", "").strip_edges().to_upper()
	
		# Restricción de montaña: solo Terrace Farm (Incan) y Highland Power
		# Station (Nepalese) pueden levantarse sobre terreno montañoso, y solo
		# con esa civilización activa o mediante su sincretismo.
		if t in ["MOUNTAINOUS", "MONTAÑA"]:
			var es_montana_permitida := false
			if mejora_nombre == "Terrace Farm" and (civ_actual == "Incan" or civ_sincretismo == "Incan"):
				es_montana_permitida = true
			elif mejora_nombre == "Highland Power Station" and (civ_actual in ["Nepal", "Nepalese"] or civ_sincretismo in ["Nepal", "Nepalese"]):
				es_montana_permitida = true
			if not es_montana_permitida: return false
		
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
				return recurso_compatible_con_mejora(res, "Quarry", era_actual)
			"Clay Pit":
				if era_actual == "Modern Age": return f == "WET" or t in ["HUMEDO", "WET"]
				else: return f == "WET" or t in ["HUMEDO", "WET"] or recurso_compatible_con_mejora(res, "Clay Pit", era_actual)
			"Expedition Base":
				if era_actual == "Exploration" and civ_actual == "Incan": return f == "NATURAL_WONDER" or t in ["MOUNTAINOUS", "MONTAÑA"]
				elif era_actual == "Modern Age": return f == "NATURAL_WONDER" or t in ["MOUNTAINOUS", "MONTAÑA"]
				else: return f == "NATURAL_WONDER"
			"Farm": return t in ["FLAT", "PLANO"]
			"Woodcutter":
				return f == "VEGETATED" or t in ["VEGETACION", "VEGETATED"] or recurso_compatible_con_mejora(res, "Woodcutter", era_actual)
			"Fishing Boat":
				var val_water = (t in ["COASTAL", "COSTA", "NAVIGABLE_RIVER", "RIO_NAVEGABLE"]) and not rio
				return val_water or recurso_compatible_con_mejora(res, "Fishing Boat", era_actual)
			"Mine":
				return t in ["ROUGH", "ABRUPTO"] or recurso_compatible_con_mejora(res, "Mine", era_actual)
			"Camp":
				return recurso_compatible_con_mejora(res, "Camp", era_actual)
			"Pasture": return recurso_compatible_con_mejora(res, "Pasture", era_actual)
			"Plantation":
				return recurso_compatible_con_mejora(res, "Plantation", era_actual)
			"Oil Rig": return recurso_compatible_con_mejora(res, "Oil Rig", era_actual)
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
			"Highland Power Station": return f == "NONE" or (t in ["MOUNTAINOUS", "MONTAÑA"] and (civ_actual in ["Nepal", "Nepalese"] or civ_sincretismo in ["Nepal", "Nepalese"]))
			"Kabakas Lake", "Open-Air Museum": return t in ["FLAT", "PLANO"]
			"Obshchina": return adyacentes_misma_mejora == 0
			"Staatseisenbahn": return true
			"Shore Battery": return b != "MARINE" and celdas_coastal_adyacentes > 0
		return true

	# Adyacencia que aportaría un edificio en una celda. Con
	# "ignorar_adyacencia_maravillas" se descarta el +1 por maravilla ya construida:
	# es lo que exige el aconsejador de rendimientos para no recomendar celdas cuyo
	# único bonus provenga de una maravilla levantada.
	# --------------------------------------------------------------------------
	# Tipo del asentamiento dueño de una celda: "Capital", "City" o "Town".
	# Se coincide porque la celda está en el grid del asentamiento o porque es su
	# centro. Si ningún asentamiento la tiene se devuelve "Town": sin
	# asentamiento claro la celda no es urbana y, por regla, no admite
	# especialistas (opción conservadora).
	# idx_activo (opcional): si la celda pertenece al asentamiento ACTIVO, manda
	# su tipo. Los grids PUEDEN solaparse (los asentamientos se crean sobre el
	# mismo territorio), así que sin este orden la primera fundación (la Capital)
	# "secuestraría" el tipo de todas las celdas: la UI de especialistas de un
	# Pueblo se pintaría como si fuera de la Capital y permitiría editarla.
	# --------------------------------------------------------------------------
	static func tipo_asentamiento_de_celda(coord: Vector2i, asentamientos: Array, idx_activo: int = -1) -> String:
		if idx_activo >= 0 and idx_activo < asentamientos.size():
			var asent_activo: Dictionary = asentamientos[idx_activo]
			if asent_activo.get("grid", {}).has(coord) or asent_activo.get("centro", Vector2i(0, 0)) == coord:
				return str(asent_activo.get("tipo", "Town"))
		for asent in asentamientos:
			if asent.get("grid", {}).has(coord) or asent.get("centro", Vector2i(0, 0)) == coord:
				return str(asent.get("tipo", "Town"))
		return "Town"

	# --------------------------------------------------------------------------
	# ESPECIALISTAS: cupo de especialistas que admite una celda.
	# --------------------------------------------------------------------------
	# Reglas (Civ VII), en este orden:
	#   1) Celda urbana PROPIA: un edificio externo (ajeno) no aloja especialistas.
	#   2) El desbloqueo NO depende de ningún edificio concreto: basta con que la
	#      celda tenga UNO O DOS edificios construidos (>= 1) y cada edificio real
	#      aporta 1 cupo. Ni las murallas ni las maravillas (construibles o
	#      naturales) tienen especialistas asociados: no suman cupo y una celda
	#      que solo las contiene no admite especialistas. El Palace y el Town
	#      Hall (City Hall) cuentan como edificios y aportan su cupo.
	#   3) Solo en Ciudades y Capitales (Constantes.ESPECIALISTAS_TIPOS_ASENTAMIENTO):
	#      en los pueblos ("Town") no puede haber especialistas.
	# Encima de eso, un distrito (2+ edificios normales o 1 de celda completa)
	# añade +1. Palace y Town Hall no cuentan como edificio "normal" a efectos
	# del +1 de distrito.
	# --------------------------------------------------------------------------
	static func limite_especialistas_celda(datos: Dictionary, tipo_asentamiento: String) -> int:
		if bool(datos.get("ajeno", false)):
			return 0
		if not Constantes.ESPECIALISTAS_TIPOS_ASENTAMIENTO.has(tipo_asentamiento):
			return 0
		var edificios: Array = datos.get("edificios", [])
		if edificios.is_empty():
			return 0
		var reales := 0
		var normales := 0
		var celda_completa := false
		for edificio in edificios:
			var info: Dictionary = Constantes.DATOS_EDIFICIOS.get(edificio, {})
			# Murallas y maravillas (construibles o naturales): SIN especialistas
			# asociados: no suman cupo y por sí solas no desbloquean la celda.
			if es_edificio_muralla(edificio) or bool(info.get("is_wonder", false)) or Constantes.MARAVILLAS_NATURALES.has(edificio):
				continue
			reales += 1
			if str(edificio) in ["Palace", "Town Hall"]:
				continue
			normales += 1
			if bool(info.get("full_tile", false)) or str(edificio) in ["Aerodrome", "Rail Station"]:
				celda_completa = true
		# DESBLOQUEO POR CONTEO (>= 1 edificio real): ningún edificio concreto
		# desbloquea especialistas; con UNO o DOS edificios en la celda basta.
		# Cada edificio real aporta 1 cupo y el distrito suma +1 extra.
		if reales == 0:
			return 0
		var limite := reales
		if normales >= 2 or celda_completa:
			limite += 1
		return limite

	# --------------------------------------------------------------------------
	# Sincronizar el límite de especialistas de una celda con sus edificios y con
	# el tipo de su asentamiento (`tipo_asentamiento`: "Capital", "City" o
	# "Town"; en pueblos el cupo queda en 0).
	# Única puerta de entrada tras CUALQUIER cambio en datos.edificios (colocar,
	# borrar, sobreconstruir, edificio externo, reset, cambio de Era o carga de
	# partida): recalcula limite_especialistas y deja los asignados dentro del
	# cupo activo [0, limite].
	# LETARGO (excepción): en un PUEBLO los especialistas NO se borran. El cupo es
	# 0 (no se pueden asignar ni quitar con la UI) pero los que ya hubiera quedan
	# DORMIDOS y despiertan solos al promocionar el Pueblo a Ciudad: ver
	# especialistas_en_letargo_celda(). Las celdas externas (ajeno) sí se vacían:
	# dejan de ser celdas propias del jugador.
	# --------------------------------------------------------------------------
	static func sincronizar_especialistas_celda(datos: Dictionary, tipo_asentamiento: String) -> void:
		var limite := limite_especialistas_celda(datos, tipo_asentamiento)
		datos["limite_especialistas"] = limite
		var asignados := maxi(0, int(datos.get("especialistas_asignados", 0)))
		if bool(datos.get("ajeno", false)):
			asignados = 0
		elif Constantes.ESPECIALISTAS_TIPOS_ASENTAMIENTO.has(tipo_asentamiento):
			asignados = mini(asignados, limite)
		datos["especialistas_asignados"] = asignados

	# --------------------------------------------------------------------------
	# LETARGO DE ESPECIALISTAS (mecánica Civ VII).
	# --------------------------------------------------------------------------
	# Un especialista duerme cuando la celda donde está ya no tiene
	# infraestructura activa. CONDICIONES (basta con que se cumpla una):
	#   1) El asentamiento es un Pueblo: la Ciudad fue degradada, la interacción
	#      con especialistas queda cerrada y duermen hasta la próxima promoción.
	#   2) La celda tiene AL MENOS UN edificio obsoleto (de una Era pasada).
	#   3) La celda tiene un almacén (edificio con tipo "Warehouse").
	# REACTIVACIÓN: automática y sin estado guardado. En cuanto dejan de cumplirse
	# las condiciones (el Pueblo vuelve a ser Ciudad, o se sobreconstruye el
	# edificio obsoleto/almacén con uno de la Era actual) los especialistas
	# despiertan y recuperan sus bonos y sus costes de mantenimiento normales.
	# Efecto en rendimientos: un especialista en letargo NO aporta adyacencia ni
	# recibe bonos de políticas; solo consume -1 Alimento y -1 Felicidad
	# (Constantes.ESPECIALISTAS_LETARGO_*). Lo aplican el panel de la celda y el
	# recuento del asentamiento.
	# --------------------------------------------------------------------------
	static func especialistas_en_letargo_celda(datos: Dictionary, tipo_asentamiento: String, coord: Vector2i, era_actual: String, city_grid: Dictionary) -> bool:
		if int(datos.get("especialistas_asignados", 0)) <= 0:
			return false
		# 1) Pueblo: la Ciudad fue degradada y la interacción está cerrada.
		if not Constantes.ESPECIALISTAS_TIPOS_ASENTAMIENTO.has(tipo_asentamiento):
			return true
		for edificio in datos.get("edificios", []):
			var info: Dictionary = Constantes.DATOS_EDIFICIOS.get(edificio, {})
			# 3) Almacenes: el almacenamiento no sostiene trabajo especializado.
			if str(info.get("tipo", "")) == "Warehouse":
				return true
			# 2) Edificios obsoletos (Palace/Town Hall y maravillas nunca lo son).
			if es_edificio_obsoleto(str(edificio), coord, era_actual, city_grid):
				return true
		return false

	# --------------------------------------------------------------------------
	# JERARQUÍA DE ASENTAMIENTOS AL CAMBIAR DE ERA (regla estricta):
	#   1) El asentamiento elegido por el jugador pasa a ser la nueva Capital.
	#   2) La Capital de la Era anterior, si NO es la elegida, pasa a Ciudad: la
	#      antigua Capital NUNCA se degrada a Pueblo.
	#   3) El resto de asentamientos (incluidas las demás Ciudades) se degradan a
	#      Pueblo.
	# --------------------------------------------------------------------------
	static func tipo_tras_cambio_de_era(idx: int, idx_nueva_capital: int, idx_capital_anterior: int) -> String:
		if idx == idx_nueva_capital:
			return "Capital"
		if idx == idx_capital_anterior:
			return "City"
		return "Town"

	# Índice del asentamiento que ostenta la Capitalidad (-1 si no hay ninguno).
	static func indice_capital(asentamientos: Array) -> int:
		for i in range(asentamientos.size()):
			if str(asentamientos[i].get("tipo", "")) == "Capital":
				return i
		return -1

	# --------------------------------------------------------------------------
	# POLÍTICAS Y TRADICIONES ACTIVAS: modificadores matemáticos de rendimientos.
	# --------------------------------------------------------------------------
	# Punto único de consulta: devuelve true si la política/tradición está
	# activa en la Era indicada (esté en politicas_activas o tradiciones_activas).
	static func politica_activa(nombre: String, era: String, politicas: Dictionary, tradiciones: Dictionary) -> bool:
		return politicas.get(era, []).has(nombre) or tradiciones.get(era, []).has(nombre)

	# Especialistas activos en todo el grid de un asentamiento.
	static func especialistas_activos_grid(grid: Dictionary) -> int:
		var total := 0
		for datos in grid.values():
			total += int(datos.get("especialistas_asignados", 0))
		return total

	# --------------------------------------------------------------------------
	# aplicar_bonos_politicas(): FUNCIÓN CENTRALIZADA de efectos de políticas.
	# --------------------------------------------------------------------------
	# Recorre TODAS las políticas/tradiciones activas de la Era y añade al
	# diccionario `total` los bonos de la lista del Paso 2. Se invoca sobre el
	# total de rendimientos del ASENTAMIENTO (actualizar_panel_recuento_mejoras,
	# donde se suman los total_yields de cada ciudad/pueblo) ANTES de pintarlo y
	# UNA sola vez por asentamiento: aplicarlo dentro del bucle de celdas
	# multiplicaría los bonos por el número de celdas del territorio.
	# Los efectos que dependen de los especialistas viven en
	# aplicar_bonos_politicas_especialistas(), que además se llama desde la caja
	# de rendimientos de la celda (actualizar_panel_ui) con sus propios
	# especialistas.
	# Parámetros:
	#   total        : diccionario de rendimientos a modificar (Food, Production,
	#                  Gold, Science, Culture, Happiness, Influence).
	#   politicas    : políticas y tradiciones activas de la Era (nombres).
	#   tipo_asent   : "Capital", "City" o "Town".
	#   especialistas: nº de especialistas activos en el asentamiento.
	#   edificios    : nombres de edificios del asentamiento (para Palace,
	#                  edificios de cultura y de ciencia).
	static func aplicar_bonos_politicas(total: Dictionary, politicas: Array, tipo_asent: String, especialistas: int, edificios: Array) -> void:
		var es_ciudad: bool = tipo_asent == "City" or tipo_asent == "Capital"
		var es_pueblo: bool = tipo_asent == "Town"
		if politicas.has("Castes"):
			total["Food"] = int(total.get("Food", 0)) + 2
		if politicas.has("Priesthood"):
			total["Gold"] = int(total.get("Gold", 0)) + 2
		if politicas.has("Rites and Rituals"):
			total["Happiness"] = int(total.get("Happiness", 0)) + 2
		if politicas.has("Ancestor Worship"):
			total["Happiness"] = int(total.get("Happiness", 0)) + 2
		if politicas.has("Charismatic Leader") and edificios.has("Palace"):
			total["Culture"] = int(total.get("Culture", 0)) + 2
		if politicas.has("Tool Making") and edificios.has("Palace"):
			total["Production"] = int(total.get("Production", 0)) + 1
			total["Science"] = int(total.get("Science", 0)) + 1
		if politicas.has("Sacred Kingship") and edificios.has("Palace"):
			total["Production"] = int(total.get("Production", 0)) + 1
		if politicas.has("Drama and Poetry"):
			for edificio in edificios:
				if _es_edificio_cultura(edificio):
					total["Culture"] = int(total.get("Culture", 0)) + 2
		if politicas.has("Literature"):
			for edificio in edificios:
				if _es_edificio_ciencia(edificio):
					total["Science"] = int(total.get("Science", 0)) + 2
		if politicas.has("Oral Tradition") and es_ciudad:
			total["Culture"] = int(total.get("Culture", 0)) + 1
		if politicas.has("Clan Feuds") and es_pueblo:
			total["Gold"] = int(total.get("Gold", 0)) + 1
		if politicas.has("Ethics") or politicas.has("Scholars"):
			aplicar_bonos_politicas_especialistas(total, politicas, especialistas)

	# --------------------------------------------------------------------------
	# BONOS DE POLÍTICAS QUE DEPENDEN DE LOS ESPECIALISTAS (Ética / Eruditos).
	# --------------------------------------------------------------------------
	# +1 Cultura (Ethics) o +1 Ciencia (Scholars) por especialista activo, con
	# -1 Felicidad por especialista en ambos casos: es el coste civismo de la
	# mecanización del trabajo. Se aplica UNA vez por conjunto de especialistas:
	#   * desde aplicar_bonos_politicas() con los del asentamiento completo,
	#   * y desde la caja de rendimientos de la celda con los de ESA celda.
	static func aplicar_bonos_politicas_especialistas(total: Dictionary, politicas: Array, especialistas: int) -> void:
		if especialistas <= 0:
			return
		if politicas.has("Ethics"):
			total["Culture"] = int(total.get("Culture", 0)) + especialistas
			total["Happiness"] = int(total.get("Happiness", 0)) - especialistas
		if politicas.has("Scholars"):
			total["Science"] = int(total.get("Science", 0)) + especialistas
			total["Happiness"] = int(total.get("Happiness", 0)) - especialistas

	# ¿Es un edificio de cultura? (Drama and Poetry): por rendimiento "Culture"
	# o por la lista de respaldo de Constantes.EDIFICIOS_CULTURA.
	static func _es_edificio_cultura(nombre: String) -> bool:
		var info: Dictionary = Constantes.DATOS_EDIFICIOS.get(nombre, {})
		if str(info.get("rendimiento", "")) == "Culture":
			return true
		if str(info.get("rendimiento_secundario", "")) == "Culture":
			return true
		return str(nombre) in Constantes.EDIFICIOS_CULTURA

	# ¿Es un edificio de ciencia? (Literature): por rendimiento "Science" o por
	# la lista de respaldo de Constantes.EDIFICIOS_CIENCIA.
	static func _es_edificio_ciencia(nombre: String) -> bool:
		var info: Dictionary = Constantes.DATOS_EDIFICIOS.get(nombre, {})
		if str(info.get("rendimiento", "")) == "Science":
			return true
		if str(info.get("rendimiento_secundario", "")) == "Science":
			return true
		return str(nombre) in Constantes.EDIFICIOS_CIENCIA


	static func calcular_bono_edificio(coord: Vector2i, nombre_edificio: String, _era_actual: String, city_grid: Dictionary, ignorar_adyacencia_maravillas: bool = false) -> int:
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
			
				# Adyacencia por maravilla construida: el aconsejador de rendimientos
				# la ignora (ignorar_adyacencia_maravillas) para no recomendar celdas
				# cuyo único bonus provenga de una maravilla ya levantada.
				if not ignorar_adyacencia_maravillas:
					for e in vd.edificios:
						if Constantes.DATOS_EDIFICIOS.get(e, {}).get("is_wonder", false):
							bonus += 1
							break
			
				if rend == "Culture" or rend == "Happiness":
					if t in ["MOUNTAINOUS", "MONTAÑA"] or t == "NATURAL_WONDER" or c == "NATURAL_WONDER": bonus += 1
				elif rend == "Gold" or rend == "Food":
					if t in ["COASTAL", "COSTA", "NAVIGABLE_RIVER", "RIO_NAVEGABLE"]: bonus += 1
				elif rend == "Science" or rend == "Production":
					# Las maravillas naturales no son recursos: no cuentan aquí.
					if vd.get("recurso", "") != "" and not MaravillasNaturales.es_maravilla(vd): bonus += 1

		var mi_celda = city_grid[coord]
		var mt = mi_celda.get("terreno", "").strip_edges().to_upper()
		var mc = mi_celda.get("caracteristica", "NONE").strip_edges().to_upper()
	
		if nombre_edificio == "K'uh Nah" and mc in ["VEGETATED", "VEGETACION"]: bonus += 2
		if nombre_edificio == "Parthenon" and mt in ["ROUGH", "ABRUPTO"]: bonus += 2
		if nombre_edificio == "Lecture Hall" and mt in ["ROUGH", "ABRUPTO"]: bonus += 1
		if nombre_edificio == "Motte" and mt in ["ROUGH", "ABRUPTO"]: bonus += 4
	
		return bonus

	static func es_ubicacion_valida_para_edificio(coord: Vector2i, edificio_nombre: String, asent_centro: Vector2i, era_actual: String, civ_actual: String, city_grid: Dictionary, tipo_asentamiento: String = "Town", asentamientos: Array = []) -> bool:
		if not city_grid.has(coord) or city_grid[coord].get("ajeno", false): return false
		if not Constantes.DATOS_EDIFICIOS.has(edificio_nombre): return false
		if HexMath.dist_hex(coord, asent_centro) > 3: return false
	
		var d = Constantes.DATOS_EDIFICIOS[edificio_nombre]
		var es_nueva_wonder = d.get("is_wonder", false)
		var es_nueva_muralla = es_edificio_muralla(edificio_nombre)
		var es_puente_nuevo = es_edificio_puente(edificio_nombre)
	
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
		# Las maravillas naturales son features del terreno: no admiten
		# edificios (su nombre en "recurso" no es un recurso).
		if MaravillasNaturales.es_maravilla(datos_celda): return false
		var es_recurso = (datos_celda.get("recurso", "") != "")
	
		if c == "ICE" or t in ["OCEAN", "OCEANO"]: return false
	
		if d.get("tipo", "") == "Unique" and tipo_asentamiento == "Town": return false
		if d.has("civ") and d.civ != civ_actual: return false
	
		var is_full_tile = d.get("full_tile", false) or edificio_nombre in ["Aerodrome", "Rail Station"]
		if is_full_tile:
			var tiene_no_obsoleto = false
			for e in datos_celda.edificios:
				if not es_edificio_obsoleto(e, coord, era_actual, city_grid): tiene_no_obsoleto = true
			if tiene_no_obsoleto: return false
	
		var edificios_actuales = datos_celda.get("edificios", [])
		var es_centro = edificios_actuales.has("Palace") or edificios_actuales.has("Town Hall")

		var normales = 0
		var normales_vivos = 0
		var tiene_wonder = false
		var tiene_muralla = false

		for e in edificios_actuales:
			if es_edificio_muralla(e):
				tiene_muralla = true
			elif Constantes.DATOS_EDIFICIOS.get(e, {}).get("is_wonder", false):
				tiene_wonder = true
			elif e not in ["Palace", "Town Hall"]:
				normales += 1
				if not es_edificio_obsoleto(e, coord, era_actual, city_grid): normales_vivos += 1

		# Excepción absoluta: sobre una celda que contiene una Maravilla
		# Construible no se construye nada (ni murallas ni edificios).
		if tiene_wonder and not es_nueva_wonder: return false

		# Puentes: ocupación exclusiva. Un puente nuevo solo entra en una
		# celda vacía o con otro puente (upgrade de era); nunca convive con
		# otros edificios. A la inversa, cualquier edificio nuevo sustituye
		# al puente: aplicar_edificio retira exactamente ese puente.
		if es_puente_nuevo:
			for e in edificios_actuales:
				if not es_edificio_puente(e):
					return false

		if es_nueva_muralla:
			# Sobreconstrucción (upgrade): la muralla de una era superior puede
			# levantarse sobre la muralla de una era anterior y la sustituye. Nunca
			# se duplica la misma muralla ni se "degrada" a una era ya superada.
			var era_nueva_muralla = Constantes.ORDEN_ERAS.get(str(d.get("era", "All")), 0)
			for e in edificios_actuales:
				if es_edificio_muralla(e):
					var era_muralla_existente = Constantes.ORDEN_ERAS.get(str(Constantes.DATOS_EDIFICIOS.get(e, {}).get("era", "All")), 0)
					if era_muralla_existente >= era_nueva_muralla: return false

			if not tiene_muralla:
				# Muralla nueva desde cero: exige anillo urbano y trazar desde otra muralla.
				var is_urban = normales > 0 or tiene_wonder or es_centro
				if not is_urban: return false

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
				if tiene_wonder or normales_vivos > 0 or es_centro: return false
			else:
				var max_normales = 1 if es_centro else 2
				# Cap sobre edificios VIGENTES: los obsoletos no cuentan
				# porque la sobreconstrucción los retira de uno en uno.
				if normales_vivos >= max_normales: return false
			
		if not es_nueva_muralla and es_recurso:
			return false
		
		if not es_nueva_muralla:
			if d.get("no_pair", false) and (normales > 0 or tiene_wonder): return false
			if d.has("max_one") and d.max_one:
				for c_datos in city_grid.values():
					if c_datos.edificios.has(edificio_nombre): return false
			if d.has("no_adj_same") and d.no_adj_same:
				for vec in HexMath.VECINOS_HEX:
					var n = coord + vec
					if city_grid.has(n) and city_grid[n].edificios.has(edificio_nombre): return false
			
		# Regla general: los edificios no se colocan sobre montañas. La única
		# excepción son las maravillas con requisito de montaña (Machu Pikchu).
		if t in ["MONTAÑA", "MOUNTAINOUS"] and not es_nueva_wonder: return false
	
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

		# Machu Pikchu: sobre montaña exige además bioma/terreno Tropical o Plains.
		if edificio_nombre == "Machu Pikchu":
			var b_machu = str(datos_celda.get("bioma", "")).strip_edges().to_upper()
			if b_machu not in ["TROPICAL", "PLAINS"] and t not in ["TROPICAL", "PLAINS"]:
				return false
			
		if d.get("req_rio", false) and not datos_celda.get("rio", false) and t not in ["RIO_NAVEGABLE", "NAVIGABLE_RIVER"]: return false
		
		return true


class GestorPincel:

	static func celda_tiene_desarrollo(datos: Dictionary) -> bool:
		if datos.get("mejora_tipo", "") != "":
			return true
		for e in datos.get("edificios", []):
			if e not in ["Palace", "Town Hall"]:
				return true
			if Constantes.DATOS_EDIFICIOS.get(e, {}).get("is_wonder", false):
				return true
		return false

	static func aplicar_bioma_y_terreno(main: Node2D, bioma: String, terreno: String):
		if not main.city_grid.has(main.celda_seleccionada): return
		var datos = main.city_grid[main.celda_seleccionada]
		# Las maravillas naturales se editan desde el panel de Features: no se
		# bloquean por tener la base de expedición u otra mejora encima.
		if not MaravillasNaturales.es_maravilla(datos) and celda_tiene_desarrollo(datos): return
	
		datos.bioma = bioma
		datos.terreno = terreno
	
		if terreno != "FLAT" and datos.caracteristica in ["WET", "VEGETATED"]:
			datos.caracteristica = "NONE"
		# Regla crítica de floodplains: exigen río menor (en llanura) o río navegable.
		if datos.caracteristica == "FLOODPLAIN" and not ReglasJuego.es_floodplain_permitida(terreno, datos.get("rio", false)):
			datos.caracteristica = "NONE"
		
		# La limpieza de recursos inválidos la resuelve validar_y_refrescar_pincel
		# con la información centralizada en DATOS_RECURSOS.
		
		validar_y_refrescar_pincel(main)

	static func aplicar_caracteristica(main: Node2D, c: String):
		if not main.city_grid.has(main.celda_seleccionada): return
		var datos = main.city_grid[main.celda_seleccionada]
		var es_maravilla_celda = MaravillasNaturales.es_maravilla(datos)
		# Las maravillas naturales se gestionan desde Features (p. ej. None):
		# se permite cambiar la feature aunque tengan la base de expedición.
		if not es_maravilla_celda and celda_tiene_desarrollo(datos): return
	
		if c == "FLOODPLAIN":
			# Regla crítica: floodplain solo con río menor o río navegable.
			if not ReglasJuego.es_floodplain_permitida(datos.terreno, datos.get("rio", false)):
				return
		elif c in ["WET", "VEGETATED"] and datos.terreno != "FLAT":
			return
		# Cambiar la feature de una maravilla natural la retira: su nombre no
		# es un recurso, así que se limpia "recurso" y la mejora de activación.
		if es_maravilla_celda and c != "NATURAL_WONDER" and str(datos.get("caracteristica", "")) == "NATURAL_WONDER":
			if Constantes.MARAVILLAS_NATURALES.has(str(datos.get("recurso", ""))):
				datos.recurso = ""
			if datos.get("mejora_tipo", "") == MaravillasNaturales.MEJORA_ACTIVACION:
				datos.mejora_tipo = ""
		datos.caracteristica = c
		validar_y_refrescar_pincel(main)

	static func validar_y_refrescar_pincel(main: Node2D):
		var datos = main.city_grid[main.celda_seleccionada]
	
		# Regla crítica: si la celda deja de tener río (menor o navegable) el
		# floodplain se retira; después se valida el recurso contra la celda ya
		# consistente usando DATOS_RECURSOS.
		if datos.get("caracteristica", "") == "FLOODPLAIN" and not ReglasJuego.es_floodplain_permitida(datos.get("terreno", ""), datos.get("rio", false)):
			datos.caracteristica = "NONE"

		var nom_rec = datos.get("recurso", "")
		# Un nombre de maravilla natural en "recurso" solo es válido mientras la
		# celda siga siendo una maravilla (feature); si la feature se limpia, el
		# nombre desaparece con ella: no es un recurso.
		if nom_rec != "" and Constantes.MARAVILLAS_NATURALES.has(nom_rec) and not MaravillasNaturales.es_maravilla(datos):
			datos.recurso = ""
			nom_rec = ""
		if nom_rec != "" and Constantes.DATOS_RECURSOS.has(nom_rec):
			if not ReglasJuego.es_recurso_valido_en_celda(nom_rec, datos, main.era_actual):
				datos.recurso = ""

		main.actualizar_panel_pincel()
		main.actualizar_botones_recursos_ui()
		main.actualizar_sugerencias_cache()
		main.actualizar_iconos_todos()
		main.actualizar_panel_ui()
		main.guardar_partida_actual()
		main.queue_redraw()

	static func aplicar_recurso(main: Node2D, recurso_nombre: String):
		if not main.city_grid.has(main.celda_seleccionada): return
		var datos = main.city_grid[main.celda_seleccionada]
		if celda_tiene_desarrollo(datos): return
	
		if datos.edificios.has("Palace") or datos.edificios.has("Town Hall") or datos.ajeno: return
	
		# Las maravillas naturales son features: su nombre vive en "recurso"
		# pero no se gestionan con los botones de recursos.
		if MaravillasNaturales.es_maravilla(datos): return
		# Validez centralizada en DATOS_RECURSOS: terreno, feature y era.
		# "" es la operación de quitar recurso: no hay validez que comprobar.
		if recurso_nombre != "" and not ReglasJuego.es_recurso_valido_en_celda(recurso_nombre, datos, main.era_actual):
			return
	
		datos.recurso = recurso_nombre
		main.actualizar_botones_recursos_ui()
		main.actualizar_sugerencias_cache()
		main.actualizar_iconos_todos()
		main.actualizar_panel_ui()
		main.guardar_partida_actual()
		main.queue_redraw()

	static func aplicar_maravilla_natural(main: Node2D, maravilla_nombre: String):
		if not main.city_grid.has(main.celda_seleccionada): return
		var datos = main.city_grid[main.celda_seleccionada]
		# Permitido también sobre una maravilla existente (cambio de maravilla
		# desde Features); para el resto sigue exigiendo celda sin desarrollo.
		if not MaravillasNaturales.es_maravilla(datos) and celda_tiene_desarrollo(datos): return
		# Validación: bioma/terreno, límite de casillas por asentamiento y
		# exclusión de adyacencia frente a maravillas naturales distintas
		# (la lista de disponibles ya filtra las que infringen la regla).
		if not (maravilla_nombre in main.listar_maravillas_disponibles_celda(main.celda_seleccionada)): return

		datos.caracteristica = "NATURAL_WONDER"
		datos.recurso = maravilla_nombre
		main.actualizar_botones_recursos_ui()
		main.actualizar_sugerencias_cache()
		main.actualizar_iconos_todos()
		main.actualizar_panel_ui()
		main.guardar_partida_actual()
		main.queue_redraw()

	static func borrar_maravilla_natural(main: Node2D):
		if not main.city_grid.has(main.celda_seleccionada): return
		var datos = main.city_grid[main.celda_seleccionada]
		datos.caracteristica = "NONE"
		datos.recurso = ""
		# La mejora de activación solo tiene sentido sobre la maravilla.
		if datos.get("mejora_tipo", "") == MaravillasNaturales.MEJORA_ACTIVACION:
			datos.mejora_tipo = ""
		main.actualizar_icono_celda(main.celda_seleccionada)
		main.actualizar_panel_ui()
		main.guardar_partida_actual()
		main.queue_redraw()


	static func toggle_rio_celda(main: Node2D):
		if not main.city_grid.has(main.celda_seleccionada): return
		var datos = main.city_grid[main.celda_seleccionada]
		# Las maravillas naturales no se bloquean por tener desarrollo.
		if not MaravillasNaturales.es_maravilla(datos) and celda_tiene_desarrollo(datos): return
	
		datos.rio = not datos.rio
		# Regla crítica: sin río no puede subsistir un floodplain.
		if datos.get("caracteristica", "") == "FLOODPLAIN" and not ReglasJuego.es_floodplain_permitida(datos.terreno, datos.rio):
			datos.caracteristica = "NONE"
		main.actualizar_panel_pincel()
		main.actualizar_sugerencias_cache()
		main.actualizar_iconos_todos()
		main.actualizar_panel_ui()
		main.guardar_partida_actual()
		main.queue_redraw()


class GestorConstruccion:

	static func verificar_expansion_territorio(main: Node2D, coord: Vector2i):
		if main.asentamientos.size() == 0 or main.asentamiento_activo_idx >= main.asentamientos.size(): return
		var centro = main.asentamientos[main.asentamiento_activo_idx].centro
		var dist = HexMath.dist_hex(coord, centro)
	
		var datos = main.city_grid.get(coord, {})
		if not datos.get("reclamada", false): return
	
		if dist == 1 or dist == 2:
			for vec in HexMath.VECINOS_HEX:
				var n = coord + vec
				if main.city_grid.has(n):
					var d_n = main.city_grid[n]
					if not d_n.get("reclamada", false):
						d_n.reclamada = true
		elif dist == 3:
			for vec in HexMath.VECINOS_HEX:
				var n = coord + vec
				if main.city_grid.has(n):
					var dist_n = HexMath.dist_hex(n, centro)
					if dist_n == 3:
						var d_n = main.city_grid[n]
						if not d_n.get("reclamada", false):
							d_n.reclamada = true

	static func calcular_sugerencias_edificios(main: Node) -> Dictionary:
		# ---------------------------------------------------------------------
		# ACONSEJADOR DE RENDIMIENTOS (YIELD ADVISOR)
		# ---------------------------------------------------------------------
		# 1) Se recorren TODAS las celdas del mapa buscando celdas libres que
		#    pertenezcan al anillo de construcción (dist <= 3) de algún
		#    asentamiento propio.
		# 2) Solo se aconseja un rendimiento si queda algún edificio de ese
		#    rendimiento pendiente de colocar (era y civilización válidas, y sin
		#    construir todavía en ningún asentamiento).
		# 3) La adyacencia es predictiva y ESTRICTAMENTE mayor que 0, y se calcula
		#    con "ignorar_adyacencia_maravillas = true": las maravillas ya
		#    construidas NO justifican por sí solas una sugerencia.
		# 4) Si una celda es apta para varios rendimientos, sus iconos se ordenan
		#    de mayor a menor adyacencia (los consume el HUD en ese orden).
		# 5) El mismo icono de rendimiento puede repetirse como máximo tantas veces
		#    como edificios pendientes haya de ese rendimiento (cupo), eligiendo
		#    siempre las celdas con mayor adyacencia.
		var sugerencias = {}
		if main.asentamientos.size() == 0 or main.asentamiento_activo_idx >= main.asentamientos.size():
			return sugerencias

		var era = main.era_actual
		var civ = main.civ_actual
		var civ_sinc = main.civ_sincretismo
		var rendimientos_icono = ["Food", "Production", "Gold", "Science", "Culture", "Happiness", "Influence"]

		# --- 1) Edificios construidos que siguen vigentes (no obsoletos). -----
		var edificios_construidos = {}
		for coord_c in main.city_grid.keys():
			for e in main.city_grid[coord_c].edificios:
				if not ReglasJuego.es_edificio_obsoleto(e, coord_c, era, main.city_grid):
					edificios_construidos[e] = true

		# --- 2) Edificios pendientes de colocar, agrupados por rendimiento. ---
		var pendientes = []
		var cupo_por_rend = {}
		for edif_nombre in Constantes.DATOS_EDIFICIOS.keys():
			# El aconsejador solo recomienda elementos construibles: nunca la UI
			# de especialistas, que se asigna en el panel de la celda.
			if not ReglasJuego.es_construible(edif_nombre): continue
			var d_edif = Constantes.DATOS_EDIFICIOS[edif_nombre]
			if edif_nombre in ["Palace", "Town Hall"]: continue
			if d_edif.get("is_wonder", false): continue
			if ReglasJuego.es_edificio_muralla(edif_nombre): continue
			# Los puentes no se ocultan al construirse: no tienen límite de
			# cantidad (el jugador puede levantar todos los del río).
			if ReglasJuego.se_oculta_por_ya_construido(edif_nombre, edificios_construidos): continue
			var rend = str(d_edif.get("rendimiento", ""))
			if not rendimientos_icono.has(rend): continue
			var era_edif = d_edif.get("era", "All")
			# Misma regla que el panel de construcción: solo la era actual, más
			# los almacenes de eras anteriores pendientes de construir.
			if era_edif != "All":
				var orden_edif = Constantes.ORDEN_ERAS.get(era_edif, 0)
				var orden_era_consejero = Constantes.ORDEN_ERAS.get(era, 0)
				if orden_edif != orden_era_consejero and not (orden_edif < orden_era_consejero and str(d_edif.get("tipo", "")) == "Warehouse"): continue
			if d_edif.has("civ") and d_edif.civ != civ and d_edif.civ != civ_sinc: continue
			pendientes.append({"nombre": edif_nombre, "rendimiento": rend})
			cupo_por_rend[rend] = int(cupo_por_rend.get(rend, 0)) + 1

		if pendientes.size() == 0: return sugerencias

		# --- 3) Evaluación de celdas: candidatos por rendimiento. -------------
		var candidatos = {}
		for rend in cupo_por_rend.keys(): candidatos[rend] = []

		for coord in main.city_grid.keys():
			var datos = main.city_grid[coord]
			if datos.get("ajeno", false): continue
			# Restricción de montaña: los edificios no se colocan sobre
			# montañas, así que estas celdas quedan fuera del aconsejador.
			if str(datos.get("terreno", "")).strip_edges().to_upper() in ["MOUNTAINOUS", "MONTAÑA"]: continue
			# Excepción absoluta: sobre una celda con una Maravilla Construible
			# no se aconseja nada (allí no se construye ningún edificio).
			var tiene_wonder_adv = false
			for e_adv in datos.edificios:
				if Constantes.DATOS_EDIFICIOS.get(e_adv, {}).get("is_wonder", false):
					tiene_wonder_adv = true
					break
			if tiene_wonder_adv: continue
			# Un recurso ocupa la celda: no admite edificios encima, por lo que
			# las mejoras sobre recursos tampoco se aconsejan.
			if str(datos.get("recurso", "")) != "": continue
			# Se evalúan celdas vacías, con edificios vigentes u obsoletos y con
			# mejoras sin recurso: todas admiten sobreconstrucción.
			if datos.get("caracteristica", "") == "NATURAL_WONDER" or datos.get("terreno", "") == "NATURAL_WONDER": continue

			# Asentamiento propietario de la celda (anillo de construcción).
			var centro_celda = Vector2i(-999, -999)
			var tipo_celda = "Town"
			for asent in main.asentamientos:
				if HexMath.dist_hex(coord, asent.centro) <= 3:
					centro_celda = asent.centro
					tipo_celda = asent.tipo
					break
			if centro_celda == Vector2i(-999, -999): continue

			for p in pendientes:
				var rend_p = str(p["rendimiento"])
				if not candidatos.has(rend_p): continue
				if not ReglasJuego.es_ubicacion_valida_para_edificio(coord, str(p["nombre"]), centro_celda, era, civ, main.city_grid, tipo_celda, main.asentamientos): continue
				var ady_p = ReglasJuego.calcular_bono_edificio(coord, str(p["nombre"]), era, main.city_grid, true)
				if ady_p <= 0: continue
				candidatos[rend_p].append({"coord": coord, "ady": ady_p, "edificio": str(p["nombre"])})

		# --- 4) Selección: mejores celdas por rendimiento (cupo = pendientes). -
		for rend in candidatos.keys():
			var lista = candidatos[rend]
			if lista.size() == 0: continue

			# Una entrada por celda y rendimiento, con la mejor adyacencia.
			var mejor_por_celda = {}
			var orden_celdas = []
			for cand in lista:
				var c_celda = cand["coord"]
				if not mejor_por_celda.has(c_celda):
					mejor_por_celda[c_celda] = cand
					orden_celdas.append(c_celda)
				elif int(cand["ady"]) > int(mejor_por_celda[c_celda]["ady"]):
					mejor_por_celda[c_celda] = cand

			var entradas = []
			for c_celda in orden_celdas: entradas.append(mejor_por_celda[c_celda])
			entradas.sort_custom(func(a, b): return int(a["ady"]) > int(b["ady"]))

			var cupo = min(int(cupo_por_rend.get(rend, 0)), entradas.size())
			for i in range(cupo):
				var e_sel = entradas[i]
				if not sugerencias.has(e_sel["coord"]): sugerencias[e_sel["coord"]] = []
				sugerencias[e_sel["coord"]].append({"rendimiento": rend, "adyacencia": int(e_sel["ady"]), "edificio": e_sel["edificio"]})

		# --- 5) Orden final por celda: mayor adyacencia primero. --------------
		for coord in sugerencias.keys().duplicate():
			sugerencias[coord].sort_custom(func(a, b): return int(a["adyacencia"]) > int(b["adyacencia"]))

		return sugerencias

	static func aplicar_edificio(main: Node2D, edificio: String):
		if not main.city_grid.has(main.celda_seleccionada): return
		var datos = main.city_grid[main.celda_seleccionada]
	
		if datos.get("mejora_tipo", "") != "":
			datos.mejora_tipo = ""
	
		# Sobreconstrucción estrictamente UNO A UNO: el nuevo edificio retira
		# COMO MÁXIMO UN (1) edificio de la celda; nunca se limpia la celda
		# entera de golpe aunque haya varios obsoletos.
		var retirado = false

		# 1) El puente ocupa toda la celda: cualquier edificio nuevo lo retira
		#    (y un puente nuevo sustituye al puente anterior, upgrade de era).
		for e in datos.edificios.duplicate():
			if ReglasJuego.es_edificio_puente(e) and e != edificio:
				datos.edificios.erase(e)
				retirado = true
				break

		# Sobreconstrucción de murallas (upgrade explícito del jugador): la muralla
		# de la era actual sustituye a la levantada en la celda. Una muralla nunca
		# se elimina por cambio de era, solo por esta vía.
		if ReglasJuego.es_edificio_muralla(edificio):
			for e in datos.edificios.duplicate():
				if ReglasJuego.es_edificio_muralla(e) and e != edificio:
					datos.edificios.erase(e)

		# 2) Sobreconstrucción de obsoletos: se retira SOLO el primero del array
		#    (un único borrado y break). Los demás obsoletos permanecen hasta que
		#    el jugador vuelva a sobreconstruir sobre la celda. Se itera sobre
		#    datos.edificios.duplicate() para poder borrar mientras se recorre,
		#    y Array.erase() elimina únicamente la primera ocurrencia.

		if not retirado and not ReglasJuego.es_edificio_muralla(edificio):
			for e in datos.edificios.duplicate():
				if ReglasJuego.es_edificio_obsoleto(e, main.celda_seleccionada, main.era_actual, main.city_grid):
					datos.edificios.erase(e)
					break

		if not datos.edificios.has(edificio):
			datos.edificios.append(edificio)
		
		# Los edificios pueden ampliar el límite de especialistas de la celda
		# (solo en Ciudades y Capitales): se recalcula y se recortan los asignados
		# si exceden el nuevo límite.
		ReglasJuego.sincronizar_especialistas_celda(datos, ReglasJuego.tipo_asentamiento_de_celda(main.celda_seleccionada, main.asentamientos, main.asentamiento_activo_idx))

		verificar_expansion_territorio(main, main.celda_seleccionada)
	
		main.actualizar_sugerencias_cache()
		main.actualizar_panel_construccion()
		main.actualizar_icono_celda(main.celda_seleccionada)
		main.actualizar_panel_ui()
		main.guardar_partida_actual()
		main.queue_redraw()

	static func aplicar_mejora(main: Node2D, tipo: String):
		if not main.city_grid.has(main.celda_seleccionada): return
		var datos = main.city_grid[main.celda_seleccionada]

		if main.asentamientos.size() == 0 or main.asentamiento_activo_idx >= main.asentamientos.size(): return
		var asent_centro = main.asentamientos[main.asentamiento_activo_idx].centro
		var asent_tipo = main.asentamientos[main.asentamiento_activo_idx].tipo
		if not ReglasJuego.es_mejora_valida(main.celda_seleccionada, tipo, asent_centro, main.city_grid, main.era_actual, main.civ_actual, asent_tipo, main.civ_sincretismo):
			return

		datos.mejora_tipo = tipo
		verificar_expansion_territorio(main, main.celda_seleccionada)

		main.actualizar_sugerencias_cache()
		main.actualizar_panel_construccion()
		main.actualizar_icono_celda(main.celda_seleccionada)
		main.actualizar_panel_ui()
		main.guardar_partida_actual()
		main.queue_redraw()


	static func borrar_edificio_especifico(main: Node2D, edificio_nombre: String):
		if not main.city_grid.has(main.celda_seleccionada): return
		# Las murallas no se eliminan: solo se sustituyen por la versión de la
		# era siguiente mediante upgrade. Las maravillas construibles SÍ se
		# pueden borrar mientras dura la era a la que corresponden; pasada esa
		# era quedan como hito permanente (tampoco se sobreconstruyen).
		if edificio_nombre in ["Palace", "Town Hall"]: return
		if ReglasJuego.es_edificio_muralla(edificio_nombre): return
		if Constantes.DATOS_EDIFICIOS.get(edificio_nombre, {}).get("is_wonder", false) \
				and not ReglasJuego.es_maravilla_borrable_en_era(edificio_nombre, main.era_actual): return
		# Los obsoletos también están protegidos: solo la sobreconstrucción
		# (edificio nuevo por encima) puede retirarlos del mapa.
		if ReglasJuego.es_edificio_obsoleto(edificio_nombre, main.celda_seleccionada, main.era_actual, main.city_grid): return
		var datos = main.city_grid[main.celda_seleccionada]
		if datos.edificios.has(edificio_nombre):
			datos.edificios.erase(edificio_nombre)
			# Al borrar un edificio el límite de especialistas puede bajar: se
			# recalcula y se recortan los asignados si exceden el nuevo límite.
			ReglasJuego.sincronizar_especialistas_celda(datos, ReglasJuego.tipo_asentamiento_de_celda(main.celda_seleccionada, main.asentamientos, main.asentamiento_activo_idx))

			main.actualizar_sugerencias_cache()
			main.actualizar_panel_construccion()
			main.actualizar_icono_celda(main.celda_seleccionada)
			main.actualizar_panel_ui()
			main.guardar_partida_actual()
			main.queue_redraw()

	static func borrar_mejora(main: Node2D):
		if not main.city_grid.has(main.celda_seleccionada): return
		var datos = main.city_grid[main.celda_seleccionada]
		datos.mejora_tipo = ""
		main.actualizar_sugerencias_cache()
		main.actualizar_panel_construccion()
		main.actualizar_icono_celda(main.celda_seleccionada)
		main.actualizar_panel_ui()
		main.guardar_partida_actual()
		main.queue_redraw()

	static func aplicar_edificio_externo(main: Node2D, edificio: String):
		if not main.city_grid.has(main.celda_seleccionada): return
		var datos = main.city_grid[main.celda_seleccionada]
		datos.ajeno = true
	
		if datos.get("mejora_tipo", "") != "":
			datos.mejora_tipo = ""
		
		if not datos.edificios.has(edificio): datos.edificios.append(edificio)
		# Un edificio externo tampoco aloja especialistas (no es celda urbana
		# propia): el cupo de la celda queda en 0 y los asignados se recortan.
		ReglasJuego.sincronizar_especialistas_celda(datos, ReglasJuego.tipo_asentamiento_de_celda(main.celda_seleccionada, main.asentamientos, main.asentamiento_activo_idx))
	
		verificar_expansion_territorio(main, main.celda_seleccionada)
	
		main.actualizar_panel_externos()
		main.actualizar_visibilidad_boton_externos()
		main.actualizar_icono_celda(main.celda_seleccionada)
		main.actualizar_panel_ui()
		main.guardar_partida_actual()
		main.queue_redraw()

	static func aplicar_mejora_externo(main: Node2D, mejora: String):
		if not main.city_grid.has(main.celda_seleccionada): return
		var datos = main.city_grid[main.celda_seleccionada]
		datos.ajeno = true
		datos.mejora_tipo = mejora
	
		verificar_expansion_territorio(main, main.celda_seleccionada)
	
		main.actualizar_panel_externos()
		main.actualizar_visibilidad_boton_externos()
		main.actualizar_icono_celda(main.celda_seleccionada)
		main.actualizar_panel_ui()
		main.guardar_partida_actual()
		main.queue_redraw()

	static func borrar_externo(main: Node2D):
		if not main.city_grid.has(main.celda_seleccionada): return
		var datos = main.city_grid[main.celda_seleccionada]
		datos.ajeno = false
		datos.edificios.clear()
		datos.mejora_tipo = ""
		# Sin edificios el cupo de especialistas vuelve a 0: se recortan los
		# asignados para no dejar especialistas huérfanos.
		ReglasJuego.sincronizar_especialistas_celda(datos, ReglasJuego.tipo_asentamiento_de_celda(main.celda_seleccionada, main.asentamientos, main.asentamiento_activo_idx))
		main.actualizar_panel_externos()
		main.actualizar_visibilidad_boton_externos()
		main.actualizar_icono_celda(main.celda_seleccionada)
		main.actualizar_panel_ui()
		main.guardar_partida_actual()
		main.queue_redraw()


class GestorAsentamientos:

	static func iniciar_nueva_partida(main: Node2D, era: String, civ: String):
		main.era_actual = era
		main.civ_actual = civ
		main.civ_sincretismo = "None"
		main.partida_actual_nombre = "Autosave"
		main.era_transicionada = (era != "Antiquity")
	
		for child in main.get_children():
			if child is Control and child != main.camera and child != main.lbl_info and child != main.lbl_nombre_partida:
				if not child is CanvasLayer: child.queue_free()
	
		main.asentamientos.clear()
		crear_asentamiento_inicial(main, civ, "Capital", Vector2i(0, 0), true)
	
		main.cambiar_seccion("ASENTAMIENTOS")
		main.actualizar_visibilidad_boton_externos()
		main.actualizar_panel_gestion_ui()
		main.actualizar_botones_recursos_ui()
		main.guardar_partida_actual()

	static func crear_asentamiento_inicial(main: Node2D, nombre: String, tipo: String, centro: Vector2i, es_capital: bool):
		var grid = {}
		var radio_inicial = 4
		for q in range(-radio_inicial, radio_inicial + 1):
			var r1 = max(-radio_inicial, -q - radio_inicial)
			var r2 = min(radio_inicial, -q + radio_inicial)
			for r in range(r1, r2 + 1):
				var coord = centro + Vector2i(q, r)
				var s = -coord.x - coord.y
				var centro_px = HexMath.cubo_a_pixel(main.radio_hex, coord.x, coord.y, s)
				var dist = HexMath.dist_hex(coord, centro)
			
				var hbox_icono = GridContainer.new()
				hbox_icono.columns = 2
				hbox_icono.add_theme_constant_override("h_separation", 2)
				hbox_icono.add_theme_constant_override("v_separation", 2)
				hbox_icono.custom_minimum_size = Vector2(40, 40)
				hbox_icono.position = centro_px - Vector2(20, 20)
				hbox_icono.visible = false
				main.add_child(hbox_icono)
			
				var hbox_recurso = HBoxContainer.new()
				hbox_recurso.custom_minimum_size = Vector2(24, 24)
				hbox_recurso.alignment = BoxContainer.ALIGNMENT_CENTER
				hbox_recurso.position = centro_px - Vector2(12, main.radio_hex * 0.75)
				hbox_recurso.visible = false
				main.add_child(hbox_recurso)
			
				var hbox_terreno = Label.new()
				hbox_terreno.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				hbox_terreno.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				hbox_terreno.mouse_filter = Control.MOUSE_FILTER_IGNORE
				hbox_terreno.visible = false
				main.add_child(hbox_terreno)
			
				var edificios_iniciales: Array[String] = []
				if es_capital and coord == centro:
					edificios_iniciales.append("Palace")
				elif not es_capital and coord == centro:
					edificios_iniciales.append("Town Hall")
			
				var es_centro_o_anillo_1 = (dist <= 1)
			
				grid[coord] = {
					"q": coord.x, "r": coord.y, "s": s,
					"bioma": "DESERT",
					"terreno": "FLAT",
					"caracteristica": "NONE",
					"rio": false,
					"edificios": edificios_iniciales,
					"edificios_dorados": [],
					"mejora_tipo": "",
					"recurso": "",
					"especialistas_asignados": 0,
					# Cupo inicial conforme a la regla: 0 en los pueblos y en las
					# celdas sin edificios; 1 en el centro con Palace/Town Hall de
					# una Capital o Ciudad.
					"limite_especialistas": ReglasJuego.limite_especialistas_celda({"edificios": edificios_iniciales, "ajeno": false}, tipo),
					"favorita": 0,
					"reclamada": es_centro_o_anillo_1,
					"ajeno": false,
					"nodo_icono": hbox_icono,
					"nodo_recurso": hbox_recurso,
					"nodo_terreno": hbox_terreno
				}
			
		main.asentamientos.append({
			"nombre": nombre,
			"tipo": tipo,
			"centro": centro,
			"grid": grid
		})
	
		cambiar_asentamiento_activo(main, main.asentamientos.size() - 1)
		main.guardar_partida_actual()

	static func cambiar_asentamiento_activo(main: Node2D, idx: int):
		if main.asentamientos.size() > 0 and main.asentamiento_activo_idx < main.asentamientos.size():
			for c in main.asentamientos[main.asentamiento_activo_idx].grid.values():
				if is_instance_valid(c.nodo_icono): c.nodo_icono.visible = false
				if is_instance_valid(c.nodo_recurso): c.nodo_recurso.visible = false
				if is_instance_valid(c.nodo_terreno): c.nodo_terreno.visible = false
			
		main.asentamiento_activo_idx = idx
		main.city_grid = main.asentamientos[idx].grid
		main.celda_seleccionada = main.asentamientos[idx].centro
	
		for coord in main.city_grid.keys():
			var datos = main.city_grid[coord]
			if is_instance_valid(datos.nodo_icono): datos.nodo_icono.visible = true
			if is_instance_valid(datos.nodo_recurso): datos.nodo_recurso.visible = true
			if is_instance_valid(datos.nodo_terreno): datos.nodo_terreno.visible = true
		
		main.actualizar_sugerencias_cache()
		main.actualizar_iconos_todos()
		main.actualizar_botones_recursos_ui()
		main.actualizar_panel_pincel()
		main.actualizar_panel_construccion()
		main.actualizar_panel_externos()
		main.actualizar_visibilidad_boton_externos()
		main.actualizar_panel_ui()
		main.actualizar_lista_asentamientos_ui()
		main.centrar_camara_en_activo()
		main.queue_redraw()

	static func crear_nuevo_asentamiento(main: Node2D, tipo: String):
		var nombre = "Town " + str(main.asentamientos.size()) if tipo == "Town" else "City " + str(main.asentamientos.size())
		crear_asentamiento_inicial(main, nombre, tipo, Vector2i(0, 0), false)

	static func resetear_asentamiento(main: Node2D, idx: int):
		var asent = main.asentamientos[idx]
		var es_capital = (asent.tipo == "Capital")
	
		for coord in asent.grid.keys():
			var datos = asent.grid[coord]
			datos.recurso = ""
			datos.rio = false
			datos.mejora_tipo = ""
			datos.favorita = 0
			datos.ajeno = false
			var dist = HexMath.dist_hex(coord, asent.centro)
			datos.reclamada = (dist <= 1)
			datos.edificios.clear()
			datos.edificios_dorados.clear()
		
			if coord == asent.centro:
				if es_capital: datos.edificios.append("Palace")
				else: datos.edificios.append("Town Hall")
			# Cambian los edificios de la celda: el cupo de especialistas vuelve
			# a su mínimo (0 en los pueblos, el del Palace/Town Hall en Ciudad o
			# Capital) y los asignados se recortan.
			ReglasJuego.sincronizar_especialistas_celda(datos, str(asent.tipo))
				
		if idx == main.asentamiento_activo_idx:
			main.actualizar_sugerencias_cache()
			main.actualizar_botones_recursos_ui()
			main.actualizar_panel_pincel()
			main.actualizar_panel_construccion()
			main.actualizar_panel_externos()
			main.actualizar_visibilidad_boton_externos()
			main.actualizar_panel_ui()
			main.actualizar_iconos_todos()
			main.queue_redraw()
		main.guardar_partida_actual()

	static func ejecutar_borrado_asentamiento(main: Node2D, idx: int):
		if idx >= 0 and idx < main.asentamientos.size():
			main.asentamientos.remove_at(idx)
			if main.asentamiento_activo_idx >= main.asentamientos.size():
				main.asentamiento_activo_idx = max(0, main.asentamientos.size() - 1)
			cambiar_asentamiento_activo(main, main.asentamiento_activo_idx)
			main.guardar_partida_actual()

	# --------------------------------------------------------------------------
	# Resincronizar el cupo de especialistas de TODAS las celdas de un
	# asentamiento cuando cambia su tipo (pueblo <-> Ciudad o Capital): el cupo
	# depende del tipo, así que una promoción abre los cupos de sus celdas y una
	# degradación los cierra y retira los especialistas que ya no tienen sitio.
	# --------------------------------------------------------------------------
	static func sincronizar_especialistas_asentamiento(main: Node2D, idx: int) -> void:
		if idx < 0 or idx >= main.asentamientos.size():
			return
		var asent = main.asentamientos[idx]
		var tipo: String = str(asent.tipo)
		for coord in asent.grid.keys():
			ReglasJuego.sincronizar_especialistas_celda(asent.grid[coord], tipo)

	static func cambiar_era(main: Node2D, nueva_era: String, nueva_civ: String, idx_nueva_capital: int, dorados_seleccionados: Array = []):
		main.era_actual = nueva_era
		main.civ_actual = nueva_civ
		main.civ_sincretismo = "None"
		main.era_transicionada = true
		# Jerarquía de asentamientos: se resuelve con ReglasJuego.tipo_tras_cambio_de_era()
		# (el elegido es la nueva Capital; la Capital de la era anterior nunca baja
		# de Ciudad; el resto pasa a Pueblo). El índice de la Capital actual se
		# captura ANTES de tocar ningún tipo.
		var idx_capital_anterior: int = ReglasJuego.indice_capital(main.asentamientos)
	
		for i in range(main.asentamientos.size()):
			var asent = main.asentamientos[i]
			for coord in asent.grid.keys():
				var c = asent.grid[coord]
				# Transición de era: se limpian los recursos del mapa y, con ellos,
				# todas las mejoras colocadas en las celdas (misma rutina para ambas).
				c.recurso = ""
				c.mejora_tipo = ""
				c.edificios_dorados.clear()
				for edif_oro in dorados_seleccionados:
					if c.edificios.has(edif_oro): c.edificios_dorados.append(edif_oro)
		
			var c_datos = asent.grid[asent.centro]
			# Jerarquía estricta al cambiar de Era: el elegido pasa a Capital, la
			# Capital anterior (si no es el elegido) pasa a Ciudad y NUNCA a
			# Pueblo, y el resto (incluidas las demás Ciudades) se degrada a Pueblo.
			asent.tipo = ReglasJuego.tipo_tras_cambio_de_era(i, idx_nueva_capital, idx_capital_anterior)
			if asent.tipo == "Capital":
				if c_datos.edificios.has("Town Hall"): c_datos.edificios.erase("Town Hall")
				if not c_datos.edificios.has("Palace"): c_datos.edificios.append("Palace")
			else:
				# Solo la Capital conserva el Palace (Seat of Government): Ciudad y
				# Pueblo llevan Town Hall (City Hall).
				if c_datos.edificios.has("Palace"): c_datos.edificios.erase("Palace")
				if not c_datos.edificios.has("Town Hall"): c_datos.edificios.append("Town Hall")
			# Cambio de tipo y de edificios: el cupo de especialistas depende del
			# tipo del asentamiento, así que se resincronizan TODAS sus celdas. Los
			# especialistas de una Ciudad degradada a Pueblo NO se borran: quedan en
			# LETARGO (mantenimiento reducido) y despiertan si vuelve a ser Ciudad.
			sincronizar_especialistas_asentamiento(main, i)
			
		main.actualizar_botones_recursos_ui()
		main.actualizar_sugerencias_cache()
		main.actualizar_panel_pincel()
		main.actualizar_panel_construccion()
		main.actualizar_panel_externos()
		main.actualizar_visibilidad_boton_externos()
		main.actualizar_panel_ui()
		main.actualizar_lista_asentamientos_ui()
		main.actualizar_iconos_todos()
		main.actualizar_panel_gestion_ui()
		main.guardar_partida_actual()
		main.queue_redraw()


class GestorArchivos:

	static func parsear_vector2i(valor) -> Vector2i:
		if typeof(valor) == TYPE_VECTOR2I:
			return valor
		if typeof(valor) == TYPE_ARRAY and valor.size() >= 2:
			return Vector2i(int(valor[0]), int(valor[1]))
		
		var limpia = str(valor).replace("Vector2i", "").replace("(", "").replace(")", "").replace(" ", "")
		var partes = limpia.split(",")
		if partes.size() >= 2:
			return Vector2i(partes[0].to_int(), partes[1].to_int())
		return Vector2i.ZERO

	static func cargar_local() -> Dictionary:
		var dict = {}
		if FileAccess.file_exists("user://saves_civ7.json"):
			var archivo = FileAccess.open("user://saves_civ7.json", FileAccess.READ)
			if archivo:
				var texto = archivo.get_as_text()
				var json = JSON.new()
				if json.parse(texto) == OK:
					if typeof(json.data) == TYPE_DICTIONARY:
						dict = json.data
		return dict

	static func guardar_partida_actual(main: Node2D):
		var asentamientos_limpios = []
		for asent in main.asentamientos:
			var grid_limpio = {}
			for coord_key in asent.grid.keys():
				var c = asent.grid[coord_key]
				var coord_str = "%d,%d" % [c.q, c.r]
			
				grid_limpio[coord_str] = {
					"q": c.q, "r": c.r, "s": c.s,
					"bioma": c.bioma,
					"terreno": c.terreno,
					"caracteristica": c.get("caracteristica", "NONE"),
					"rio": c.rio,
					"edificios": Array(c.edificios),
					"edificios_dorados": Array(c.edificios_dorados),
					"mejora_tipo": c.mejora_tipo,
					"recurso": c.get("recurso", ""),
					"favorita": c.get("favorita", 0),
					"reclamada": c.get("reclamada", true), # ¡IMPORTANTE! Guardar reclamada
					"especialistas_asignados": int(c.get("especialistas_asignados", 0)),
					"limite_especialistas": int(c.get("limite_especialistas", 0)),
					"ajeno": c.get("ajeno", false)
				}
			
			asentamientos_limpios.append({
				"nombre": asent.nombre,
				"tipo": asent.tipo,
				"centro": [asent.centro.x, asent.centro.y],
				"grid": grid_limpio
			})

		var extra_data = {
			"era_actual": main.era_actual,
			"civ_actual": main.civ_actual,
			"civ_sincretismo": main.civ_sincretismo,
			"lider_actual": main.lider_actual, # ¡AQUÍ SE GUARDA EL LÍDER!
			"era_transicionada": main.era_transicionada,
			"mementos_activos": main.mementos_activos,
			"politicas_activas": main.politicas_activas,
			"tradiciones_activas": main.tradiciones_activas,
			"tradiciones_historicas": main.tradiciones_historicas,
			"tope_politicas": main.tope_politicas,
			"tope_tradiciones": main.tope_tradiciones,
			"rivales_config": main.rivales_config,
			"asentamientos": asentamientos_limpios
		}
	
		main.partidas_guardadas[main.partida_actual_nombre] = extra_data
		var archivo = FileAccess.open("user://saves_civ7.json", FileAccess.WRITE)
		if archivo: 
			archivo.store_string(JSON.stringify(main.partidas_guardadas))
	
		if main.lbl_nombre_partida:
			main.lbl_nombre_partida.text = "💾 Game: " + main.partida_actual_nombre

	static func cargar_partida_especifica(main: Node2D, nombre: String) -> bool:
		if not main.partidas_guardadas.has(nombre): return false
		var datos_partida = main.partidas_guardadas[nombre]
	
		main.partida_actual_nombre = nombre
		main.era_actual = datos_partida.get("era_actual", "Antiquity")
		main.civ_actual = datos_partida.get("civ_actual", "None")
		main.civ_sincretismo = datos_partida.get("civ_sincretismo", "None")
		main.lider_actual = datos_partida.get("lider_actual", "Augustus") # ¡AQUÍ SE CARGA EL LÍDER!
		main.era_transicionada = datos_partida.get("era_transicionada", main.era_actual != "Antiquity")

		# Sistemas de Era: mementos, políticas, tradiciones y rivales. Se rellena
		# por clave para tolerar guardados anteriores a estos campos.
		var meme_cargados: Dictionary = datos_partida.get("mementos_activos", {})
		var pol_cargadas: Dictionary = datos_partida.get("politicas_activas", {})
		var trad_cargadas: Dictionary = datos_partida.get("tradiciones_activas", {})
		for era_clave in ["Antiquity", "Exploration", "Modern Age"]:
			if meme_cargados.has(era_clave): main.mementos_activos[era_clave] = meme_cargados[era_clave]
			if pol_cargadas.has(era_clave): main.politicas_activas[era_clave] = pol_cargadas[era_clave]
			if trad_cargadas.has(era_clave): main.tradiciones_activas[era_clave] = trad_cargadas[era_clave]
		main.tradiciones_historicas = datos_partida.get("tradiciones_historicas", [])
		main.rivales_config = datos_partida.get("rivales_config", [])
		# Topes ampliados con los botones "+" (guardados antiguos: por defecto).
		main.tope_politicas = int(datos_partida.get("tope_politicas", main.tope_politicas))
		main.tope_tradiciones = int(datos_partida.get("tope_tradiciones", main.tope_tradiciones))
		if main.tope_tradiciones > main.tope_politicas:
			main.tope_politicas = main.tope_tradiciones

		var datos_asentamientos = datos_partida.get("asentamientos", [])
	
		main.asentamientos.clear()
		for child in main.get_children():
			if child is Control and child != main.camera and child != main.lbl_info and child != main.lbl_nombre_partida:
				if not child is CanvasLayer:
					child.queue_free()
			
		for asent_data in datos_asentamientos:
			var grid = {}
			var centro = parsear_vector2i(asent_data.centro)
			var grid_data = asent_data.grid
			var tipo_asentamiento = asent_data.get("tipo", "Town")
		
			for key in grid_data.keys():
				var coord = parsear_vector2i(key)
				var c = grid_data[key]
				var s = -coord.x - coord.y
				var centro_px = HexMath.cubo_a_pixel(main.radio_hex, coord.x, coord.y, s)
			
				var hbox_icono = GridContainer.new()
				hbox_icono.columns = 2
				hbox_icono.add_theme_constant_override("h_separation", 2)
				hbox_icono.add_theme_constant_override("v_separation", 2)
				hbox_icono.custom_minimum_size = Vector2(40, 40)
				hbox_icono.position = centro_px - Vector2(20, 20)
				hbox_icono.visible = false
				main.add_child(hbox_icono)
			
				var hbox_recurso = HBoxContainer.new()
				hbox_recurso.custom_minimum_size = Vector2(24, 24)
				hbox_recurso.alignment = BoxContainer.ALIGNMENT_CENTER
				hbox_recurso.position = centro_px - Vector2(12, main.radio_hex * 0.75)
				hbox_recurso.visible = false
				main.add_child(hbox_recurso)
			
				var hbox_terreno = Label.new()
				hbox_terreno.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				hbox_terreno.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				hbox_terreno.mouse_filter = Control.MOUSE_FILTER_IGNORE
				hbox_terreno.visible = false
				main.add_child(hbox_terreno)
			
				var edif_array: Array[String] = []
				if c.has("edificios"):
					for e in c.edificios: edif_array.append(str(e))
			
				if coord == centro:
					var tiene_gobierno = edif_array.has("Palace") or edif_array.has("Town Hall")
					if not tiene_gobierno:
						if tipo_asentamiento == "Capital":
							edif_array.append("Palace")
						else:
							edif_array.append("Town Hall")
			
				var edif_dorados_array: Array[String] = []
				if c.has("edificios_dorados"):
					for e in c.edificios_dorados: edif_dorados_array.append(str(e))
			
				var loaded_rec = c.get("recurso", "")
				var rec_str = ""
				if typeof(loaded_rec) == TYPE_BOOL: rec_str = "Resource" if loaded_rec else ""
				else: rec_str = str(loaded_rec)
				# Un nombre de maravilla natural en "recurso" solo es válido si
				# la celda sigue siendo una maravilla (feature); en caso contrario
				# no es un recurso y se retira al cargar.
				if rec_str != "" and Constantes.MARAVILLAS_NATURALES.has(rec_str) \
						and str(c.get("caracteristica", "NONE")) != "NATURAL_WONDER" \
						and str(c.get("terreno", "FLAT")) != "NATURAL_WONDER":
					rec_str = ""
			
				var dist = HexMath.dist_hex(coord, centro)
				var reclamada_val = c.get("reclamada", dist <= 1)
			
				grid[coord] = {
					"q": coord.x, "r": coord.y, "s": s,
					"bioma": c.get("bioma", "DESERT"),
					"terreno": c.get("terreno", "FLAT"),
					"caracteristica": c.get("caracteristica", "NONE"),
					"rio": c.get("rio", false),
					"edificios": edif_array,
					"edificios_dorados": edif_dorados_array,
					"mejora_tipo": c.get("mejora_tipo", ""),
					"recurso": rec_str,
					"favorita": int(c.get("favorita", 0)),
					"reclamada": reclamada_val, # ¡IMPORTANTE! Cargar celda reclamada
					"ajeno": bool(c.get("ajeno", false)),
					"nodo_icono": hbox_icono,
					"nodo_recurso": hbox_recurso,
					"nodo_terreno": hbox_terreno
				}
				# Especialistas (mecánica Civ VII): se cargan con .get() para
				# tolerar guardados antiguos y se recortan al límite real, que
				# depende de los edificios de la celda y del tipo del asentamiento
				# (en los pueblos no puede haber ninguno).
				grid[coord]["especialistas_asignados"] = maxi(0, int(c.get("especialistas_asignados", 0)))
				ReglasJuego.sincronizar_especialistas_celda(grid[coord], tipo_asentamiento)
			
			main.asentamientos.append({
				"nombre": asent_data.get("nombre", "Settlement"),
				"tipo": tipo_asentamiento,
				"centro": centro,
				"grid": grid
			})
		
		main.actualizar_panel_gestion_ui()
		if main.asentamientos.size() > 0:
			main.cambiar_asentamiento_activo(0)
		
		return true

	# reemplazar: si se indica, ese diálogo (normalmente una lista anterior) se
	# cierra y libera antes de abrir este, para no dejar dos modales a la vez.
	static func mostrar_dialogo_cargar(main: Node2D, reemplazar: Window = null):
		var dialog = AcceptDialog.new()
		dialog.title = "Load or Delete Game"
	
		var scroll = ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(350, 240)
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(vbox)
	
		for nombre in main.partidas_guardadas.keys():
			var hbox = HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 6)
		
			var btn = Button.new()
			btn.text = "📁 " + nombre
			btn.custom_minimum_size = Vector2(230, 40)
			var btn_nom = nombre
			btn.pressed.connect(func(): 
				cargar_partida_especifica(main, btn_nom)
				dialog.queue_free()
			)
			hbox.add_child(btn)
		
			var btn_del = Button.new()
			btn_del.text = "🗑️"
			btn_del.custom_minimum_size = Vector2(40, 40)
			btn_del.pressed.connect(func():
				mostrar_dialogo_confirmar_borrado(main, btn_nom, dialog)
			)
			hbox.add_child(btn_del)
			vbox.add_child(hbox)
		
		dialog.add_child(scroll)
		dialog.close_requested.connect(func(): dialog.queue_free())
		GestorInterfaz.abrir_modal(main, dialog, reemplazar, true, Vector2(380, 320))

	static func mostrar_dialogo_confirmar_borrado(main: Node2D, nombre_partida: String, parent_dialog: Window):
		var confirm = ConfirmationDialog.new()
		confirm.title = "Confirm Deletion"
		confirm.dialog_text = "Are you sure you want to delete the save '" + nombre_partida + "'?"
	
		confirm.confirmed.connect(func():
			main.partidas_guardadas.erase(nombre_partida)
			var archivo = FileAccess.open("user://saves_civ7.json", FileAccess.WRITE)
			if archivo: archivo.store_string(JSON.stringify(main.partidas_guardadas))
			# La lista se reconstruye con el guardado ya borrado: el diálogo anterior
			# se libera dentro de mostrar_dialogo_cargar() mediante "reemplazar".
			confirm.hide()
			confirm.queue_free()
			mostrar_dialogo_cargar(main, parent_dialog)
		)
	
		confirm.close_requested.connect(func(): confirm.queue_free())
		# Se anida DENTRO del diálogo de la lista (no cuelga de la raíz): así cada
		# ventana tiene su propio hueco exclusivo y no chocan entre ellas.
		GestorInterfaz.abrir_modal(main, confirm, parent_dialog, false, Vector2(340, 150))


# ==============================================================================
# MEMENTOS: REGLAS DE SELECCIÓN
# ------------------------------------------------------------------------------
# Los DATOS (diccionario + límites) viven en Constantes.gd (Constantes.
# DATOS_MEMENTOS / MEMENTOS_MAXIMO_POR_ERA); aquí solo están las reglas puras.
# ==============================================================================
class GestorMementos:

	# Devuelve la nueva lista de mementos activos al alternar un memento:
	#   * si ya estaba activo -> se deselecciona;
	#   * si hay hueco (< MEMENTOS_MAXIMO_POR_ERA) -> se activa;
	#   * si está llena -> la lista queda intacta (hay que deseleccionar uno
	#     antes de poder activar otro: los mementos son sustituibles).
	static func alternar_memento(activos: Array, nombre: String) -> Array:
		var nuevos := activos.duplicate()
		if nuevos.has(nombre):
			nuevos.erase(nombre)
		elif nuevos.size() < Constantes.MEMENTOS_MAXIMO_POR_ERA:
			nuevos.append(nombre)
		return nuevos

	# true si aún queda hueco en la selección de la Era.
	static func cabe_memento(activos: Array) -> bool:
		return activos.size() < Constantes.MEMENTOS_MAXIMO_POR_ERA

	# Muestra de texto de los activos (para etiquetas de UI).
	static func texto_activos(activos: Array) -> String:
		if activos.is_empty():
			return "(ninguno)"
		var partes := PackedStringArray()
		for n in activos:
			partes.append(str(n))
		return "; ".join(partes)

	# Nombres de los mementos de una Era concreta: lo que debe listarse en el
	# modal para que SOLO se muestren los de la Era actual del jugador (los de
	# otras Eras no aparecen; "Todas" aparecería en todas).
	static func mementos_de_era(era: String) -> Array:
		var res: Array = []
		for nombre in Constantes.DATOS_MEMENTOS:
			var e := str(Constantes.DATOS_MEMENTOS[nombre].get("era", "Todas"))
			if e == "Todas" or e == era:
				res.append(nombre)
		return res

	# Título con la primera letra de cada palabra en mayúscula (solo visual: las
	# claves de Constantes.DATOS_MEMENTOS no cambian para no romper selecciones
	# ni partidas ya guardadas).
	static func titulo_bonito(nombre: String) -> String:
		var partes: PackedStringArray = nombre.replace("_", " ").split(" ", false)
		var res := PackedStringArray()
		for p in partes:
			res.append(p.substr(0, 1).to_upper() + p.substr(1).to_lower())
		return " ".join(res)


# ==============================================================================
# POLÍTICAS Y TRADICIONES: REGLAS DE SELECCIÓN Y HERENCIA
# ------------------------------------------------------------------------------
# Los DATOS (diccionario por Era -> Tipo y los topes por defecto) viven en
# Constantes.gd (Constantes.DATOS_POLITICAS / MAXIMO_POLITICAS_POR_ERA /
# MAXIMO_TRADICIONES_POR_ERA); aquí solo están las reglas puras.
# ==============================================================================
class GestorPoliticas:

	# Nombres de las políticas de una Era (Social + Crisis + Ideology), sin tradiciones.
	static func politicas_de_era(era: String) -> Array:
		var res: Array = []
		for tipo in ["Social", "Crisis", "Ideology"]:
			for p in Constantes.DATOS_POLITICAS.get(era, {}).get(tipo, []):
				res.append(str(p.get("nombre", "")))
		return res

	# Todas las políticas y tradiciones activas en la Era indicada. Acepta el
	# esquema actual (politicas_activas + tradiciones_activas) o cualquier
	# diccionario extra con el formato {era: [nombres]}.
	static func politicas_y_tradiciones_activas(era: String, politicas: Dictionary, tradiciones: Dictionary, extras: Array = []) -> Array:
		var res: Array = []
		for fuente in [politicas, tradiciones]:
			for nombre in fuente.get(era, []):
				var texto := str(nombre)
				if texto != "" and not res.has(texto):
					res.append(texto)
		for extra in extras:
			if extra is Dictionary:
				for nombre in extra.get(era, []):
					var texto_extra := str(nombre)
					if texto_extra != "" and not res.has(texto_extra):
						res.append(texto_extra)
			elif extra is Array:
				for nombre in extra:
					var texto_lista := str(nombre)
					if texto_lista != "" and not res.has(texto_lista):
						res.append(texto_lista)
		return res

	# Tradiciones disponibles en una Era: las propias de la Era (dato) más las que
	# estuvieron activas en algún momento (históricas), que se acoplan así a las
	# listas de las Eras siguientes.
	static func tradiciones_disponibles(era: String, historicas: Array) -> Array:
		var res: Array = []
		var vistas := {}
		for p in Constantes.DATOS_POLITICAS.get(era, {}).get("Tradiciones", []):
			var nombre_era := str(p.get("nombre", ""))
			if not vistas.has(nombre_era):
				vistas[nombre_era] = true
				res.append(p)
		for historia in historicas:
			var nombre_hist := str(historia)
			if vistas.has(nombre_hist):
				continue
			var dato: Dictionary = buscar_tradicion(nombre_hist)
			if not dato.is_empty():
				vistas[nombre_hist] = true
				res.append(dato)
		return res

	# Busca la definición de una tradición por nombre en todas las Eras.
	static func buscar_tradicion(nombre: String) -> Dictionary:
		for era_actual in Constantes.DATOS_POLITICAS:
			for p in Constantes.DATOS_POLITICAS[era_actual].get("Tradiciones", []):
				if str(p.get("nombre", "")) == nombre:
					return p
		return {}

	# Alternar política (mismo patrón que los mementos: sustituibles, con tope).
	# `tope` opcional: los botones "+" del modal amplían el tope por partida.
	static func alternar_politica(activos: Array, nombre: String, tope: int = Constantes.MAXIMO_POLITICAS_POR_ERA) -> Array:
		var nuevos := activos.duplicate()
		if nuevos.has(nombre):
			nuevos.erase(nombre)
		elif nuevos.size() < tope:
			nuevos.append(nombre)
		return nuevos

	# Alternar tradición con su tope exclusivo (el tope global lo controla la UI).
	# `tope` opcional: los botones "+" del modal amplían el tope por partida.
	static func alternar_tradicion(activos: Array, nombre: String, tope: int = Constantes.MAXIMO_TRADICIONES_POR_ERA) -> Array:
		var nuevos := activos.duplicate()
		if nuevos.has(nombre):
			nuevos.erase(nombre)
		elif nuevos.size() < tope:
			nuevos.append(nombre)
		return nuevos

	# Total de políticas de la Era: INCLUYE las tradiciones activas.
	static func total_politicas(politicas: Array, tradiciones: Array) -> int:
		return politicas.size() + tradiciones.size()


class GestorDialogos:

	static func mostrar_dialogo_renombrar(main: Node2D, idx: int):
		var dialog = AcceptDialog.new()
		dialog.title = "Rename Settlement"
		var vbox = VBoxContainer.new()
		var line_edit = LineEdit.new()
		line_edit.text = main.asentamientos[idx].nombre
		line_edit.custom_minimum_size = Vector2(250, 40)
		vbox.add_child(line_edit)
		dialog.add_child(vbox)
	
		dialog.confirmed.connect(func():
			if line_edit.text.strip_edges() != "":
				main.asentamientos[idx].nombre = line_edit.text.strip_edges()
				main.actualizar_lista_asentamientos_ui()
				main.guardar_partida_actual()
			main.centrar_camara_en_activo()
			dialog.queue_free()
		)
		dialog.close_requested.connect(func():
			main.centrar_camara_en_activo()
			dialog.queue_free()
		)
		GestorInterfaz.abrir_modal(main, dialog, null, false, Vector2(300, 150))

	static func mostrar_dialogo_borrar_asentamiento(main: Node2D, idx: int):
		var dialog = ConfirmationDialog.new()
		dialog.title = "Delete Settlement"
		dialog.dialog_text = "¿Are you sure you want to delete '" + main.asentamientos[idx].nombre + "' and all its terrain?"
		dialog.confirmed.connect(func():
			GestorAsentamientos.ejecutar_borrado_asentamiento(main, idx)
			dialog.queue_free()
		)
		dialog.canceled.connect(func(): dialog.queue_free())
		dialog.close_requested.connect(func(): dialog.queue_free())
		GestorInterfaz.abrir_modal(main, dialog, null, false, Vector2(320, 150))

	static func mostrar_dialogo_lideres_inicio(main: Node2D, iniciar_nueva_partida_despues: bool = true):
		var dialog = AcceptDialog.new()
		dialog.title = "Select Leader"
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 12)
		var lbl = Label.new()
		lbl.text = "Choose your leader:"
		lbl.add_theme_font_size_override("font_size", 14)
		vbox.add_child(lbl)
	
		var scroll = ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(580, 260)
		var grid = GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		scroll.add_child(grid)
	
		var btn_group_lideres = ButtonGroup.new()
		var lista_lideres = Constantes.DATOS_LIDERES.keys() if Constantes.DATOS_LIDERES else []
		
		for lider in lista_lideres:
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(130, 80)
			btn.toggle_mode = true
			btn.button_group = btn_group_lideres
			btn.button_pressed = (lider == main.lider_actual)
			btn.set_meta("lider_name", lider)
		
			var sb = StyleBoxFlat.new()
			sb.bg_color = Color(0.12, 0.12, 0.16)
			sb.border_color = Color(0.3, 0.3, 0.3)
			sb.set_border_width_all(2)
			sb.set_corner_radius_all(6)
		
			var sb_press = sb.duplicate()
			sb_press.bg_color = Color(0.2, 0.3, 0.5)
			sb_press.border_color = Color(0.4, 0.8, 1.0)
			sb_press.set_border_width_all(3)
		
			btn.add_theme_stylebox_override("normal", sb)
			btn.add_theme_stylebox_override("pressed", sb_press)
			btn.add_theme_stylebox_override("hover", sb_press)
		
			var vb_btn = VBoxContainer.new()
			vb_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
			vb_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vb_btn.alignment = BoxContainer.ALIGNMENT_CENTER
			vb_btn.add_theme_constant_override("separation", 4)
		
			var path = main.resolver_ruta_asset(lider)
			if ResourceLoader.exists(path):
				var tex = TextureRect.new()
				tex.texture = load(path)
				tex.custom_minimum_size = Vector2(40, 40)
				tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
				vb_btn.add_child(tex)
		
			var lbl_name = Label.new()
			lbl_name.text = lider
			lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl_name.add_theme_font_size_override("font_size", 11)
			lbl_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl_name.custom_minimum_size = Vector2(120, 0)
			vb_btn.add_child(lbl_name)
		
			btn.add_child(vb_btn)
			grid.add_child(btn)
		
		vbox.add_child(scroll)
		dialog.add_child(vbox)
	
		dialog.confirmed.connect(func():
			var btn_presionado = btn_group_lideres.get_pressed_button()
			if btn_presionado:
				main.lider_actual = btn_presionado.get_meta("lider_name")
				main.actualizar_panel_ui()
			
			if iniciar_nueva_partida_despues:
				# El diálogo de nueva partida REEMPLAZA a este: abrir_modal libera el modal
				# anterior antes de mostrar el siguiente (si no, Godot rechaza el 2º modal).
				mostrar_dialogo_nueva_partida(main, dialog)
			else:
				dialog.hide()
				dialog.queue_free()
		)
		dialog.close_requested.connect(func(): dialog.queue_free())
		GestorInterfaz.abrir_modal(main, dialog, null, false, Vector2(620, 380))

	# reemplazar: diálogo anterior que este debe sustituir (cadena Líder -> Nueva
	# partida). Se libera antes de abrir este para no dejar dos modales abiertos.
	static func mostrar_dialogo_nueva_partida(main: Node2D, reemplazar: Window = null):
		var dialog = AcceptDialog.new()
		dialog.title = "Start New Game"
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 10)
	
		var lbl_e = Label.new()
		lbl_e.text = "Select Starting Era:"
		vbox.add_child(lbl_e)
	
		var era_group = ButtonGroup.new()
		var era_hbox = HBoxContainer.new()
		era_hbox.add_theme_constant_override("separation", 8)
		vbox.add_child(era_hbox)
	
		var eras = ["Antiquity", "Exploration", "Modern Age"]
		var era_buttons = {}
		for i in range(eras.size()):
			var era_name = eras[i]
			var btn_era = Button.new()
			btn_era.toggle_mode = true
			btn_era.button_group = era_group
			btn_era.custom_minimum_size = Vector2(110, 36)
			btn_era.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if i == 0: btn_era.button_pressed = true
		
			var sb_era = StyleBoxFlat.new()
			sb_era.bg_color = Color(0.15, 0.15, 0.2)
			sb_era.set_corner_radius_all(6)
			var sb_era_press = sb_era.duplicate()
			sb_era_press.bg_color = Color(0.25, 0.45, 0.75)
			btn_era.add_theme_stylebox_override("normal", sb_era)
			btn_era.add_theme_stylebox_override("pressed", sb_era_press)
			btn_era.add_theme_stylebox_override("hover", sb_era_press)
		
			var hb = HBoxContainer.new()
			hb.set_anchors_preset(Control.PRESET_FULL_RECT)
			hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hb.alignment = BoxContainer.ALIGNMENT_CENTER
			hb.add_theme_constant_override("separation", 6)
		
			var tex = TextureRect.new()
			tex.custom_minimum_size = Vector2(24, 24)
			tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			var path = main.resolver_ruta_asset(era_name)
			if ResourceLoader.exists(path): tex.texture = load(path)
			hb.add_child(tex)
		
			var lbl = Label.new()
			lbl.text = era_name
			hb.add_child(lbl)
			btn_era.add_child(hb)
		
			era_hbox.add_child(btn_era)
			era_buttons[era_name] = btn_era
	
		var lbl_c = Label.new()
		lbl_c.text = "Select Starting Civilization:"
		vbox.add_child(lbl_c)
	
		var btn_group_civ = ButtonGroup.new()
		var grid_civs = main._crear_selector_civs(Constantes.TODAS_LAS_CIVS[0], btn_group_civ)
		vbox.add_child(grid_civs)
		dialog.add_child(vbox)
	
		dialog.confirmed.connect(func():
			var era_seleccionada = "Antiquity"
			for era_name in era_buttons.keys():
				if era_buttons[era_name].button_pressed:
					era_seleccionada = era_name
					break
				
			var civ_seleccionada = Constantes.TODAS_LAS_CIVS[0]
			if btn_group_civ.get_pressed_button():
				civ_seleccionada = btn_group_civ.get_pressed_button().get_meta("civ_name")
			
			GestorAsentamientos.iniciar_nueva_partida(main, era_seleccionada, civ_seleccionada)
			dialog.queue_free()
		)
		GestorInterfaz.abrir_modal(main, dialog, reemplazar, true, Vector2(620, 460))

	static func mostrar_dialogo_sincretismo(main: Node2D):
		var dialog = AcceptDialog.new()
		dialog.title = "Select Syncretism"
		var vbox = VBoxContainer.new()
		var btn_group_civs = ButtonGroup.new()
		var grid_civs = main._crear_selector_civs(main.civ_sincretismo, btn_group_civs, true)
		vbox.add_child(grid_civs)
		dialog.add_child(vbox)
	
		dialog.confirmed.connect(func():
			var civ_seleccionada = "None"
			if btn_group_civs.get_pressed_button():
				civ_seleccionada = btn_group_civs.get_pressed_button().get_meta("civ_name")
			
			if civ_seleccionada != main.civ_actual:
				main.civ_sincretismo = civ_seleccionada
				main.actualizar_panel_gestion_ui()
				main.actualizar_sugerencias_cache()
				main.actualizar_panel_construccion()
				main.guardar_partida_actual()
			dialog.queue_free()
		)
		dialog.close_requested.connect(func(): dialog.queue_free())
		GestorInterfaz.abrir_modal(main, dialog, null, false, Vector2(700, 480))

	static func mostrar_dialogo_confirmar_siguiente_era(main: Node2D):
		var siguiente = ""
		if main.era_actual == "Antiquity": siguiente = "Exploration"
		elif main.era_actual == "Exploration": siguiente = "Modern Age"
		if siguiente == "": return
	
		var dialog = ConfirmationDialog.new()
		dialog.title = "New Era: " + siguiente + "!"
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 10)
	
		var lbl_adv = Label.new()
		lbl_adv.text = "All resources and improvements will be cleared from the map."
		vbox.add_child(lbl_adv)
	
		var elegibles = []
		for i in range(main.asentamientos.size()):
			if main.asentamientos[i].tipo in ["Capital", "City"]:
				elegibles.append(i)
	
		var btn_group_cap = ButtonGroup.new()
		var btn_dict_cap = {}
	
		if elegibles.size() > 1:
			vbox.add_child(HSeparator.new())
			var lbl_cap = Label.new()
			lbl_cap.text = "Select your new Global Capital:"
			vbox.add_child(lbl_cap)
		
			var pre_selected = elegibles[0]
			if main.asentamiento_activo_idx in elegibles: pre_selected = main.asentamiento_activo_idx
		
			for idx in elegibles:
				var rb = CheckBox.new()
				rb.text = main.asentamientos[idx].nombre + (" (Previous Capital)" if main.asentamientos[idx].tipo == "Capital" else " (City)")
				rb.button_group = btn_group_cap
				if idx == pre_selected: rb.button_pressed = true
				vbox.add_child(rb)
				btn_dict_cap[rb] = idx
			
		vbox.add_child(HSeparator.new())
		var lbl_civ = Label.new()
		lbl_civ.text = "Select your Civilization:"
		vbox.add_child(lbl_civ)
	
		var btn_group_civs = ButtonGroup.new()
		var grid_civs = main._crear_selector_civs(main.civ_actual, btn_group_civs, false, siguiente, main.civ_actual)
		vbox.add_child(grid_civs)
	
		var dorados_disponibles = {}
		for asen in main.asentamientos:
			for coord in asen.grid.keys():
				var d_celda = asen.grid[coord]
				if d_celda.edificios.has("Academy"): dorados_disponibles["Academy"] = true
				if d_celda.edificios.has("Amphitheater"): dorados_disponibles["Amphitheater"] = true
			
		var checkboxes_oro = {}
		if dorados_disponibles.size() > 0:
			vbox.add_child(HSeparator.new())
			var lbl_oro = Label.new()
			lbl_oro.text = "🌟 Select for Golden Age:"
			lbl_oro.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
			vbox.add_child(lbl_oro)
		
			for edif_oro in dorados_disponibles.keys():
				var cb = CheckBox.new()
				cb.text = edif_oro
				vbox.add_child(cb)
				checkboxes_oro[edif_oro] = cb

		dialog.add_child(vbox)
	
		dialog.confirmed.connect(func():
			var idx_cap = elegibles[0] if elegibles.size() > 0 else 0
			if elegibles.size() > 1:
				for rb in btn_dict_cap.keys():
					if rb.button_pressed:
						idx_cap = btn_dict_cap[rb]
						break
		
			var seleccionados_oro = []
			for edif_oro in checkboxes_oro.keys():
				if checkboxes_oro[edif_oro].button_pressed:
					seleccionados_oro.append(edif_oro)
		
			var civ_seleccionada = main.civ_actual
			if btn_group_civs.get_pressed_button():
				civ_seleccionada = btn_group_civs.get_pressed_button().get_meta("civ_name")
			
			GestorAsentamientos.cambiar_era(main, siguiente, civ_seleccionada, idx_cap, seleccionados_oro)
			dialog.queue_free()
		)
		dialog.canceled.connect(func(): dialog.queue_free())
		dialog.close_requested.connect(func(): dialog.queue_free())
		GestorInterfaz.abrir_modal(main, dialog, null, false, Vector2(700, 600))


	# ------------------------------------------------------------------------------
	# MEMENTOS (modal de la Era actual)
	# ------------------------------------------------------------------------------
	# Solo aparecen los mementos de la Era en la que está el jugador (los de
	# otras Eras no se muestran). Se activan como máximo
	# Constantes.MEMENTOS_MAXIMO_POR_ERA mementos: si la selección está llena y pulsa
	# un tercero, se muestra un aviso y hay que deseleccionar uno previo. Los
	# títulos se muestran con la primera letra de cada palabra en mayúscula.
	static func mostrar_dialogo_mementos(main: Node2D):
		var era: String = main.era_actual
		if not main.mementos_activos.has(era):
			main.mementos_activos[era] = []
		var dialog = AcceptDialog.new()
		dialog.title = "Mementos · " + era
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 8)
		var lbl_info = Label.new()
		lbl_info.text = "Era actual: %s · Máximo %d mementos activos. Solo se listan los de esta Era; pulsa uno seleccionado para deseleccionarlo (son sustituibles)." % [era, Constantes.MEMENTOS_MAXIMO_POR_ERA]
		lbl_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lbl_info)

		var scroll = ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(730, 430)
		vbox.add_child(scroll)

		var hbox_cab = HBoxContainer.new()
		var lbl_contador = Label.new()
		var lbl_aviso = Label.new()
		lbl_aviso.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_aviso.add_theme_color_override("font_color", Color(1.0, 0.6, 0.45))
		hbox_cab.add_child(lbl_contador)
		hbox_cab.add_child(lbl_aviso)
		vbox.add_child(hbox_cab)

		var grid = GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(grid)

		var tarjetas: Dictionary = {}
		var era_ref: String = era
		for nombre in GestorMementos.mementos_de_era(era):
			var datos: Dictionary = Constantes.DATOS_MEMENTOS[nombre]
			var card = PanelContainer.new()
			card.custom_minimum_size = Vector2(165, 105)
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var margen = MarginContainer.new()
			for lado in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
				margen.add_theme_constant_override(lado, 8)
			var card_vbox = VBoxContainer.new()
			card_vbox.add_theme_constant_override("separation", 4)
			var lbl_nom = Label.new()
			lbl_nom.text = GestorMementos.titulo_bonito(nombre)
			lbl_nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl_nom.add_theme_font_size_override("font_size", 12)
			var lbl_desc = Label.new()
			lbl_desc.text = str(datos.get("descripcion", ""))
			lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl_desc.add_theme_font_size_override("font_size", 10)
			lbl_desc.add_theme_color_override("font_color", Color(0.72, 0.72, 0.8))
			card_vbox.add_child(lbl_nom)
			card_vbox.add_child(lbl_desc)
			margen.add_child(card_vbox)
			card.add_child(margen)
			grid.add_child(card)
			tarjetas[nombre] = card
			card.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					var activos: Array = main.mementos_activos[era_ref]
					var tenia: bool = activos.has(nombre)
					var nuevo: Array = GestorMementos.alternar_memento(activos, nombre)
					main.mementos_activos[era_ref] = nuevo
					if nuevo.size() == activos.size() and not tenia:
						lbl_aviso.text = "Selección llena: deselecciona un memento para elegir otro."
					else:
						lbl_aviso.text = ""
					lbl_contador.text = "%d/%d" % [nuevo.size(), Constantes.MEMENTOS_MAXIMO_POR_ERA]
					_pintar_tarjetas_mementos(tarjetas, nuevo)
			)
		_pintar_tarjetas_mementos(tarjetas, main.mementos_activos[era])
		lbl_contador.text = "%d/%d" % [main.mementos_activos[era].size(), Constantes.MEMENTOS_MAXIMO_POR_ERA]

		dialog.add_child(vbox)
		dialog.confirmed.connect(func(): dialog.queue_free())
		dialog.canceled.connect(func(): dialog.queue_free())
		dialog.close_requested.connect(func(): dialog.queue_free())
		GestorInterfaz.abrir_modal(main, dialog, null, false, Vector2(760, 560))

	# Borde dorado + fondo resaltado para las tarjetas activas.
	static func _pintar_tarjetas_mementos(tarjetas: Dictionary, activos: Array) -> void:
		for nombre in tarjetas.keys():
			var card: PanelContainer = tarjetas[nombre]
			var activa: bool = activos.has(nombre)
			var sb = StyleBoxFlat.new()
			sb.bg_color = Color(0.26, 0.22, 0.08) if activa else Color(0.12, 0.12, 0.16)
			sb.border_color = Color(1.0, 0.85, 0.3) if activa else Color(0.3, 0.3, 0.3)
			sb.set_border_width_all(3 if activa else 2)
			sb.set_corner_radius_all(8)
			card.add_theme_stylebox_override("panel", sb)

	# ------------------------------------------------------------------------------
	# CONFIGURACIÓN DE RIVALES
	# ------------------------------------------------------------------------------
	# Filas editables en vivo: cada fila muta su diccionario dentro de
	# main.rivales_config. Reglas:
	#   1) Las listas excluyen siempre al líder y la civ del jugador humano.
	#   2) No pueden coexistir dos rivales con el mismo líder ni con la misma
	#      civ: cada fila solo ve los valores libres y, al cambiar uno, se
	#      refrescan las opciones de las demás filas.
	#   3) La relación se colorea para identificarla de un vistazo
	#      (Constantes.COLORES_RELACION).
	static func lideres_para_rivales(main: Node2D) -> Array:
		return Constantes.LIDERES.filter(func(l): return l != main.lider_actual)

	static func civs_para_rivales(main: Node2D) -> Array:
		return Constantes.TODAS_LAS_CIVS.filter(func(c): return c != main.civ_actual)

	static func _rival_por_defecto(main: Node2D) -> Dictionary:
		# El líder y la civ por defecto descartan los ya usados por otros rivales
		# (los del jugador humano ya los excluyen *_para_rivales).
		var usados_lideres := {}
		var usados_civs := {}
		for r in main.rivales_config:
			usados_lideres[str(r.get("lider", ""))] = true
			usados_civs[str(r.get("civ", ""))] = true
		var lider_elegido := "None"
		for l in lideres_para_rivales(main):
			if not usados_lideres.has(l):
				lider_elegido = l
				break
		var civ_elegida := "None"
		for c in civs_para_rivales(main):
			if not usados_civs.has(c):
				civ_elegida = c
				break
		return {
			"lider": lider_elegido,
			"civ": civ_elegida,
			"relacion": "Neutro",
			"rutas": 0
		}

	static func _seleccionar_opcion(opt: OptionButton, valor: String) -> void:
		for i in range(opt.item_count):
			if opt.get_item_text(i) == valor:
				opt.select(i)
				return
		if opt.item_count > 0:
			opt.select(0)

	# Sanea rivales ya guardados: si hubiera líderes o civs repetidos entre
	# rivales (o del jugador humano), se reasigna el primer valor libre.
	static func _sanear_rivales(main: Node2D) -> void:
		var vistos_l := {}
		var vistos_c := {}
		for r in main.rivales_config:
			var l := str(r.get("lider", ""))
			if l == "" or l == main.lider_actual or vistos_l.has(l):
				for cand_l in lideres_para_rivales(main):
					if not vistos_l.has(cand_l):
						l = cand_l
						break
			vistos_l[l] = true
			r["lider"] = l
			var c := str(r.get("civ", ""))
			if c == "" or c == main.civ_actual or vistos_c.has(c):
				for cand_c in civs_para_rivales(main):
					if not vistos_c.has(cand_c):
						c = cand_c
						break
			vistos_c[c] = true
			r["civ"] = c

	# Repuebla líder/civ de cada fila descartando los que ya usa otro rival
	# (los de la propia fila se conservan siempre).
	static func _refrescar_opciones_rivales(main: Node2D, filas: Array) -> void:
		for f in filas:
			var otros_lideres := {}
			var otros_civs := {}
			for g in filas:
				if g == f:
					continue
				otros_lideres[str(g.datos.get("lider", ""))] = true
				otros_civs[str(g.datos.get("civ", ""))] = true
			var liders: Array = []
			for l in lideres_para_rivales(main):
				if not otros_lideres.has(l):
					liders.append(l)
			var civs: Array = []
			for c in civs_para_rivales(main):
				if not otros_civs.has(c):
					civs.append(c)
			_rellenar_opcion(f.opt_lider, liders, f.datos, "lider")
			_rellenar_opcion(f.opt_civ, civs, f.datos, "civ")

	static func _rellenar_opcion(opt: OptionButton, valores: Array, datos: Dictionary, clave: String) -> void:
		opt.clear()
		for v in valores:
			opt.add_item(v)
		var actual := str(datos.get(clave, ""))
		var idx := -1
		for i in range(opt.item_count):
			if opt.get_item_text(i) == actual:
				idx = i
				break
		if idx == -1 and opt.item_count > 0:
			idx = 0
			datos[clave] = opt.get_item_text(0)
		if idx >= 0:
			opt.select(idx)

	# Texto legible encima del color de relación (negro sobre colores claros,
	# blanco sobre los oscuros: Guerra es negro, Furioso marrón...).
	static func _texto_sobre(color: Color) -> Color:
		var lum := 0.299 * color.r + 0.587 * color.g + 0.114 * color.b
		return Color(0, 0, 0) if lum > 0.5 else Color(1, 1, 1)

	# Colorea el selector de relación y tiñe la fila para identificarla de un vistazo.
	static func _pintar_relacion(opt: OptionButton, sb_fila: StyleBoxFlat, nombre: String) -> void:
		var color: Color = Constantes.COLORES_RELACION.get(nombre, Color(0.25, 0.5, 0.95))
		var texto := _texto_sobre(color)
		for estado in ["normal", "hover", "pressed"]:
			var sb = StyleBoxFlat.new()
			sb.bg_color = color
			sb.set_corner_radius_all(6)
			sb.content_margin_left = 10.0
			sb.content_margin_right = 10.0
			sb.content_margin_top = 4.0
			sb.content_margin_bottom = 4.0
			opt.add_theme_stylebox_override(estado, sb)
		opt.add_theme_color_override("font_color", texto)
		opt.add_theme_color_override("font_hover_color", texto)
		opt.add_theme_color_override("font_pressed_color", texto)
		sb_fila.bg_color = Color(color.r, color.g, color.b, 0.16)

	static func _crear_fila_rival(main: Node2D, datos: Dictionary, lbl_vacio: Label, filas: Array) -> Control:
		var fila = PanelContainer.new()
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.15, 0.15, 0.2)
		sb.set_corner_radius_all(6)
		fila.add_theme_stylebox_override("panel", sb)
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		fila.add_child(hbox)

		# Opciones iniciales: se descartan los líderes/civs de otros rivales.
		var otros_lideres := {}
		var otros_civs := {}
		for f in filas:
			otros_lideres[str(f.datos.get("lider", ""))] = true
			otros_civs[str(f.datos.get("civ", ""))] = true

		var opt_lider = OptionButton.new()
		opt_lider.custom_minimum_size = Vector2(170, 0)
		opt_lider.tooltip_text = "Líder del rival (tu líder y los de otros rivales quedan excluidos)"
		for l in lideres_para_rivales(main):
			if not otros_lideres.has(l):
				opt_lider.add_item(l)
		_seleccionar_opcion(opt_lider, str(datos.get("lider", "")))
		opt_lider.item_selected.connect(func(idx: int):
			datos["lider"] = opt_lider.get_item_text(idx)
			_refrescar_opciones_rivales(main, filas)
		)
		hbox.add_child(opt_lider)

		var opt_civ = OptionButton.new()
		opt_civ.custom_minimum_size = Vector2(155, 0)
		opt_civ.tooltip_text = "Civilización del rival (la tuya y las de otros rivales quedan excluidas)"
		for c in civs_para_rivales(main):
			if not otros_civs.has(c):
				opt_civ.add_item(c)
		_seleccionar_opcion(opt_civ, str(datos.get("civ", "")))
		opt_civ.item_selected.connect(func(idx: int):
			datos["civ"] = opt_civ.get_item_text(idx)
			_refrescar_opciones_rivales(main, filas)
		)
		hbox.add_child(opt_civ)

		var opt_rel = OptionButton.new()
		opt_rel.custom_minimum_size = Vector2(150, 0)
		opt_rel.tooltip_text = "Estado de relación (coloreado: Alianza verde, Guerra negro...)"
		for e in Constantes.ESTADOS_RELACION:
			opt_rel.add_item(e)
		_seleccionar_opcion(opt_rel, str(datos.get("relacion", "Neutro")))
		opt_rel.item_selected.connect(func(idx: int):
			datos["relacion"] = opt_rel.get_item_text(idx)
			_pintar_relacion(opt_rel, sb, str(datos["relacion"]))
		)
		_pintar_relacion(opt_rel, sb, str(datos.get("relacion", "Neutro")))
		hbox.add_child(opt_rel)

		var spin_rutas = SpinBox.new()
		spin_rutas.prefix = "Rutas"
		spin_rutas.min_value = 0
		spin_rutas.max_value = 999
		spin_rutas.step = 1
		spin_rutas.value = float(datos.get("rutas", 0))
		spin_rutas.value_changed.connect(func(v: float): datos["rutas"] = int(v))
		hbox.add_child(spin_rutas)

		var btn_quitar = Button.new()
		btn_quitar.text = "✕"
		btn_quitar.tooltip_text = "Quitar rival"
		btn_quitar.pressed.connect(func():
			main.rivales_config.erase(datos)
			for i in range(filas.size()):
				if filas[i].datos == datos:
					filas.remove_at(i)
					break
			lbl_vacio.visible = main.rivales_config.is_empty()
			_refrescar_opciones_rivales(main, filas)
			fila.queue_free()
		)
		hbox.add_child(btn_quitar)
		filas.append({"datos": datos, "opt_lider": opt_lider, "opt_civ": opt_civ, "opt_rel": opt_rel})
		return fila

	static func mostrar_dialogo_rivales(main: Node2D):
		# Si hubiera duplicados de partidas previas, se sanean antes de pintar.
		_sanear_rivales(main)
		var dialog = AcceptDialog.new()
		dialog.title = "Configuración de Rivales"
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 8)
		var lbl_info = Label.new()
		lbl_info.text = "Tu líder (%s) y tu civilización (%s) quedan fuera de las listas; tampoco se repiten líderes ni civs entre rivales." % [main.lider_actual, main.civ_actual]
		lbl_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lbl_info)

		var scroll = ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(790, 340)
		vbox.add_child(scroll)
		var vbox_filas = VBoxContainer.new()
		vbox_filas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox_filas.add_theme_constant_override("separation", 6)
		scroll.add_child(vbox_filas)

		var lbl_vacio = Label.new()
		lbl_vacio.text = "Sin rivales todavía. Pulsa «Añadir rival»."
		lbl_vacio.visible = main.rivales_config.is_empty()
		vbox_filas.add_child(lbl_vacio)

		var filas: Array = []
		for datos in main.rivales_config:
			vbox_filas.add_child(_crear_fila_rival(main, datos, lbl_vacio, filas))
		_refrescar_opciones_rivales(main, filas)

		var btn_anadir = Button.new()
		btn_anadir.text = "➕ Añadir rival"
		btn_anadir.pressed.connect(func():
			# El rival nuevo nace con líder/civ distintos a los ya existentes.
			var nuevo: Dictionary = _rival_por_defecto(main)
			main.rivales_config.append(nuevo)
			lbl_vacio.visible = false
			vbox_filas.add_child(_crear_fila_rival(main, nuevo, lbl_vacio, filas))
			_refrescar_opciones_rivales(main, filas)
		)
		vbox.add_child(btn_anadir)

		dialog.add_child(vbox)
		dialog.confirmed.connect(func(): dialog.queue_free())
		dialog.canceled.connect(func(): dialog.queue_free())
		dialog.close_requested.connect(func(): dialog.queue_free())
		GestorInterfaz.abrir_modal(main, dialog, null, false, Vector2(850, 520))

	# ------------------------------------------------------------------------------
	# POLÍTICAS Y TRADICIONES (modal de la Era actual)
	# ------------------------------------------------------------------------------
	# Solo se muestran las políticas y tradiciones de la Era actual. Las tarjetas
	# se marcan igual que los mementos (clic para activar/desactivar, borde
	# dorado cuando están activas) con dos contadores:
	#   * Políticas  : total de la Era, INCLUYENDO las tradiciones activas.
	#   * Tradiciones: contador exclusivo de tradiciones.
	# Las tradiciones activas quedan en tradiciones_historicas (se guardan) y se
	# acoplan a las listas de las Eras siguientes. Si es_cambio_era, el diálogo
	# incluye el botón para continuar con el cambio de Era.
	# Junto a cada contador hay un botón "+" que amplía el tope de disponibilidad
	# (main.tope_politicas / main.tope_tradiciones) al instante y se guarda.
	static func mostrar_dialogo_politicas(main: Node2D, es_cambio_era: bool = false):
		var era: String = main.era_actual
		if not main.politicas_activas.has(era):
			main.politicas_activas[era] = []
		if not main.tradiciones_activas.has(era):
			main.tradiciones_activas[era] = []
		var siguiente := ""
		if era == "Antiquity":
			siguiente = "Exploration"
		elif era == "Exploration":
			siguiente = "Modern Age"

		var dialog = AcceptDialog.new()
		dialog.title = "Políticas y Tradiciones · " + era
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 8)

		if es_cambio_era:
			var lbl_trans = Label.new()
			if siguiente != "":
				lbl_trans.text = "Cambio de Era: marca las Tradiciones que quieras que estén disponibles en %s." % siguiente
			else:
				lbl_trans.text = "Estás en la Era final: no hay una Era siguiente disponible."
			lbl_trans.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl_trans.add_theme_color_override("font_color", Color(1.0, 0.87, 0.5))
			vbox.add_child(lbl_trans)

		var hbox_cont = HBoxContainer.new()
		hbox_cont.add_theme_constant_override("separation", 16)
		var lbl_pol = Label.new()
		var lbl_trad = Label.new()
		var lbl_aviso = Label.new()
		lbl_aviso.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_aviso.add_theme_color_override("font_color", Color(1.0, 0.6, 0.45))
		# Botones "+": amplían el tope de disponibilidad de cada contador.
		var btn_pol_mas = Button.new()
		btn_pol_mas.text = "+"
		btn_pol_mas.tooltip_text = "Ampliar el tope de políticas disponibles en esta partida"
		btn_pol_mas.custom_minimum_size = Vector2(34, 0)
		var btn_trad_mas = Button.new()
		btn_trad_mas.text = "+"
		btn_trad_mas.tooltip_text = "Ampliar el tope de tradiciones disponibles en esta partida"
		btn_trad_mas.custom_minimum_size = Vector2(34, 0)
		# Expuestos como meta para poder localizarlos desde los tests.
		dialog.set_meta("btn_pol_mas", btn_pol_mas)
		dialog.set_meta("btn_trad_mas", btn_trad_mas)
		dialog.set_meta("lbl_pol", lbl_pol)
		dialog.set_meta("lbl_trad", lbl_trad)
		hbox_cont.add_child(lbl_pol)
		hbox_cont.add_child(btn_pol_mas)
		hbox_cont.add_child(lbl_trad)
		hbox_cont.add_child(btn_trad_mas)
		hbox_cont.add_child(lbl_aviso)
		vbox.add_child(hbox_cont)

		var iconos := {"Social": "📜", "Crisis": "⚔️", "Ideology": "🚩", "Tradiciones": "🏛️"}
		var scroll = ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(770, 400)
		vbox.add_child(scroll)
		var cont_scroll = VBoxContainer.new()
		cont_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cont_scroll.add_theme_constant_override("separation", 8)
		scroll.add_child(cont_scroll)

		var tarjetas_pol: Dictionary = {}
		var tarjetas_trad: Dictionary = {}

		# Refresca contadores (el total INCLUYE las tradiciones) y bordes dorados.
		var refrescar: Callable = func() -> void:
			var total: int = main.politicas_activas[era].size() + main.tradiciones_activas[era].size()
			lbl_pol.text = "📜 Políticas: %d/%d (incluye tradiciones)" % [total, main.tope_politicas]
			lbl_trad.text = "🏛️ Tradiciones: %d/%d" % [main.tradiciones_activas[era].size(), main.tope_tradiciones]
			for np in tarjetas_pol:
				_pintar_tarjeta_politica(tarjetas_pol[np], main.politicas_activas[era].has(np))
			for nt in tarjetas_trad:
				_pintar_tarjeta_politica(tarjetas_trad[nt], main.tradiciones_activas[era].has(nt))
		# Clic en tarjeta: alterna como los mementos, respetando ambos topes.
		var alternar_tarjeta: Callable = func(nombre: String, es_tradicion: bool) -> void:
			var activas: Array = main.tradiciones_activas[era] if es_tradicion else main.politicas_activas[era]
			if activas.has(nombre):
				if es_tradicion:
					main.tradiciones_activas[era] = GestorPoliticas.alternar_tradicion(activas, nombre, main.tope_tradiciones)
				else:
					main.politicas_activas[era] = GestorPoliticas.alternar_politica(activas, nombre, main.tope_politicas)
				lbl_aviso.text = ""
			else:
				var total: int = main.politicas_activas[era].size() + main.tradiciones_activas[era].size()
				if es_tradicion and main.tradiciones_activas[era].size() >= main.tope_tradiciones:
					lbl_aviso.text = "Tradiciones llenas: deselecciona una para elegir otra."
				elif total >= main.tope_politicas:
					lbl_aviso.text = "Políticas llenas: deselecciona una para elegir otra."
				else:
					if es_tradicion:
						main.tradiciones_activas[era] = GestorPoliticas.alternar_tradicion(activas, nombre, main.tope_tradiciones)
						# Una tradición activa en algún momento queda histórica:
						# se guarda y se acopla a las Eras siguientes.
						if not main.tradiciones_historicas.has(nombre):
							main.tradiciones_historicas.append(nombre)
					else:
						main.politicas_activas[era] = GestorPoliticas.alternar_politica(activas, nombre, main.tope_politicas)
					lbl_aviso.text = ""
			refrescar.call()
		# Enlace con los rendimientos: las políticas modifican los totales, así que
		# al activar o desactivar una se recalculan la caja de rendimientos de la
		# celda (actualizar_panel_ui) y el panel de totales del asentamiento, y se
		# persiste la partida como en cualquier otra acción del jugador.
		main.actualizar_panel_ui()
		main.actualizar_panel_recuento_mejoras()
		main.guardar_partida_actual()


		# Botones "+": amplían el tope de disponibilidad (se guardan con la partida).
		btn_pol_mas.pressed.connect(func():
			main.tope_politicas += 1
			lbl_aviso.text = ""
			refrescar.call()
		)
		btn_trad_mas.pressed.connect(func():
			main.tope_tradiciones += 1
			# Mantener el invariante: las tradiciones deben caber en el total.
			if main.tope_politicas < main.tope_tradiciones:
				main.tope_politicas = main.tope_tradiciones
			lbl_aviso.text = ""
			refrescar.call()
		)

		for tipo in ["Social", "Crisis", "Ideology", "Tradiciones"]:
			var lista: Array = []
			if tipo == "Tradiciones":
				# Tradiciones de esta Era más las heredadas de Eras anteriores.
				lista = GestorPoliticas.tradiciones_disponibles(era, main.tradiciones_historicas)
			else:
				lista = Constantes.DATOS_POLITICAS[era].get(tipo, [])
			if lista.is_empty():
				continue
			var lbl_seccion = Label.new()
			lbl_seccion.text = "%s %s (%d)" % [str(iconos.get(tipo, "")), tipo, lista.size()]
			lbl_seccion.add_theme_font_size_override("font_size", 15)
			lbl_seccion.add_theme_color_override("font_color", Color(1.0, 0.87, 0.5))
			cont_scroll.add_child(lbl_seccion)
			var grid = GridContainer.new()
			grid.columns = 2
			grid.add_theme_constant_override("h_separation", 10)
			grid.add_theme_constant_override("v_separation", 10)
			grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cont_scroll.add_child(grid)
			for p in lista:
				var nombre_pol: String = str(p.get("nombre", ""))
				var card = _crear_tarjeta_politica(p)
				grid.add_child(card)
				if tipo == "Tradiciones":
					tarjetas_trad[nombre_pol] = card
					card.gui_input.connect(func(event: InputEvent):
						if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
							alternar_tarjeta.call(nombre_pol, true)
					)
				else:
					tarjetas_pol[nombre_pol] = card
					card.gui_input.connect(func(event: InputEvent):
						if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
							alternar_tarjeta.call(nombre_pol, false)
					)
			cont_scroll.add_child(HSeparator.new())

		refrescar.call()

		if es_cambio_era:
			if siguiente != "":
				var btn_continuar = Button.new()
				btn_continuar.text = "▶ Continuar: cambiar de Era"
				btn_continuar.tooltip_text = "Abre la confirmación del cambio a la Era siguiente"
				btn_continuar.pressed.connect(func():
					GestorDialogos.mostrar_dialogo_confirmar_siguiente_era(main)
					dialog.queue_free()
				)
				vbox.add_child(btn_continuar)
			dialog.get_ok_button().text = "Cerrar"

		dialog.add_child(vbox)
		dialog.confirmed.connect(func(): dialog.queue_free())
		dialog.canceled.connect(func(): dialog.queue_free())
		dialog.close_requested.connect(func(): dialog.queue_free())
		GestorInterfaz.abrir_modal(main, dialog, null, false, Vector2(820, 620))

	# Tarjeta de política: nombre, requisito (y ideología si aplica) y efecto.
	static func _crear_tarjeta_politica(p: Dictionary) -> Control:
		var card = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.13, 0.13, 0.18)
		sb.border_color = Color(0.3, 0.3, 0.42)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(8)
		card.add_theme_stylebox_override("panel", sb)
		var margen = MarginContainer.new()
		for lado in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
			margen.add_theme_constant_override(lado, 8)
		var cvb = VBoxContainer.new()
		cvb.add_theme_constant_override("separation", 3)

		var lbl_nom = Label.new()
		lbl_nom.text = str(p.get("nombre", ""))
		lbl_nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_nom.add_theme_font_size_override("font_size", 13)
		lbl_nom.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
		cvb.add_child(lbl_nom)

		var req := str(p.get("requisito", ""))
		if p.has("ideologia"):
			var ideo := str(p.get("ideologia", ""))
			req = (req + "  ·  " + ideo) if req != "" else ideo
		if req != "":
			var lbl_req = Label.new()
			lbl_req.text = "Requisito: " + req
			lbl_req.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl_req.add_theme_font_size_override("font_size", 11)
			lbl_req.add_theme_color_override("font_color", Color(0.55, 0.75, 1.0))
			cvb.add_child(lbl_req)

		var lbl_ef = Label.new()
		lbl_ef.text = str(p.get("efecto", ""))
		lbl_ef.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_ef.add_theme_font_size_override("font_size", 11)
		lbl_ef.add_theme_color_override("font_color", Color(0.78, 0.78, 0.85))
		cvb.add_child(lbl_ef)

		margen.add_child(cvb)
		card.add_child(margen)
		return card

	# Borde dorado + fondo resaltado para las tarjetas activas (mismo estilo que
	# los mementos); las inactivas conservan su aspecto base.
	static func _pintar_tarjeta_politica(card: PanelContainer, activa: bool) -> void:
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.26, 0.22, 0.08) if activa else Color(0.13, 0.13, 0.18)
		sb.border_color = Color(1.0, 0.85, 0.3) if activa else Color(0.3, 0.3, 0.42)
		sb.set_border_width_all(3 if activa else 1)
		sb.set_corner_radius_all(8)
		card.add_theme_stylebox_override("panel", sb)

class GestorInterfaz:

	# --------------------------------------------------------------------------
	# APERTURA SEGURA DE VENTANAS MODALES
	# --------------------------------------------------------------------------
	# Godot admite un único "exclusive child" (ventana modal activa) por ventana
	# padre. Al abrir un segundo modal colgado de la misma ventana raíz el motor
	# reporta: "Attempting to make child window exclusive, but the parent window
	# already has another exclusive child".
	# Reglas que aplica este helper (evita el error en todos los flujos):
	#   * Modal abierto DESDE otro modal -> se anida dentro de él, de modo que cada
	#     ventana gestiona su propio hueco exclusivo.
	#   * Modal que REEMPLAZA a otro     -> se oculta y libera el anterior antes de
	#     abrir el nuevo (reemplaza_padre = true), liberando su exclusividad.
	#   * Modal suelto                   -> se cuelga de la ventana raíz.
	static func abrir_modal(main: Node2D, ventana: Window, padre: Window = null, reemplaza_padre: bool = false, tamano: Vector2 = Vector2.ZERO) -> void:
		var raiz: Window = main.get_tree().root
		var contenedor: Node = raiz
		if is_instance_valid(padre):
			if reemplaza_padre:
				# Ocultar + liberar suelta el "exclusive child" del padre.
				padre.exclusive = false
				padre.hide()
				padre.queue_free()
			elif padre.visible:
				contenedor = padre
		if contenedor == raiz:
			# La aplicación muestra un único modal a la vez. Si quedara otro abierto
			# (cadena de diálogos mal cerrada, cierre por código, etc.) se libera antes
			# de abrir este, para que Godot acepte el nuevo "exclusive child".
			for hijo in raiz.get_children():
				if hijo is Window and hijo != ventana and hijo.visible and hijo.exclusive:
					hijo.exclusive = false
					hijo.hide()
					hijo.queue_free()
		contenedor.add_child(ventana)
		if tamano == Vector2.ZERO:
			ventana.popup_centered()
		else:
			ventana.popup_centered(tamano)

	static func aplicar_estilo_moderno_panel(panel: Control):
		if panel is PanelContainer:
			var sb = StyleBoxFlat.new()
			sb.bg_color = Color("#181820")
			sb.border_color = Color("#2a2a38")
			sb.set_border_width_all(2)
			sb.set_corner_radius_all(10)
			sb.shadow_color = Color(0, 0, 0, 0.4)
			sb.shadow_size = 8
			panel.add_theme_stylebox_override("panel", sb)

	static func crear_boton_menu(icono: String, tooltip: String) -> Button:
		var b = Button.new()
		b.text = icono
		b.custom_minimum_size = Vector2(48, 48)
		b.tooltip_text = tooltip
		b.add_theme_font_size_override("font_size", 20)
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color("#20202c")
		sb.set_corner_radius_all(8)
		sb.border_color = Color("#323246")
		sb.set_border_width_all(1)
		b.add_theme_stylebox_override("normal", sb)
		return b

	static func construir_interfaz_principal(main: Node2D) -> Dictionary:
		var canvas = CanvasLayer.new()
		main.add_child(canvas)
	
		var vbox_maestro_izq = VBoxContainer.new()
		vbox_maestro_izq.set_anchors_preset(Control.PRESET_TOP_LEFT)
		vbox_maestro_izq.offset_left = 16
		vbox_maestro_izq.offset_top = 16
		vbox_maestro_izq.offset_right = 500
		vbox_maestro_izq.offset_bottom = 880
		vbox_maestro_izq.add_theme_constant_override("separation", 8)
		canvas.add_child(vbox_maestro_izq)
	
		var hbox_layout_principal = HBoxContainer.new()
		hbox_layout_principal.size_flags_vertical = Control.SIZE_EXPAND_FILL
		hbox_layout_principal.add_theme_constant_override("separation", 10)
		vbox_maestro_izq.add_child(hbox_layout_principal)
	
		var vbox_navegacion = VBoxContainer.new()
		vbox_navegacion.custom_minimum_size = Vector2(50, 0)
		vbox_navegacion.add_theme_constant_override("separation", 10)
		hbox_layout_principal.add_child(vbox_navegacion)
	
		var btn_menu_asentamientos = crear_boton_menu("🏛️", "Game & Settlements")
		var btn_menu_pincel = crear_boton_menu("🖌️", "Terrain Brush")
		var btn_modo_construccion = crear_boton_menu("🔨", "Build")
		var btn_modo_externos = crear_boton_menu("🌐", "External")
		var btn_menu_felicidad = crear_boton_menu("😊", "Happiness Viewer")
	
		var btn_mementos = crear_boton_menu("🏅", "Mementos")
		var btn_rivales = crear_boton_menu("🤝", "Rivales")
		var btn_politicas = crear_boton_menu("📜", "Políticas")

		vbox_navegacion.add_child(btn_menu_asentamientos)
		vbox_navegacion.add_child(btn_menu_pincel)
		vbox_navegacion.add_child(btn_modo_construccion)
		vbox_navegacion.add_child(btn_modo_externos)
		vbox_navegacion.add_child(btn_menu_felicidad)
		vbox_navegacion.add_child(btn_mementos)
		vbox_navegacion.add_child(btn_rivales)
		vbox_navegacion.add_child(btn_politicas)
	
		var panel_desplegable = PanelContainer.new()
		panel_desplegable.custom_minimum_size = Vector2(460, 750)
		panel_desplegable.size_flags_vertical = Control.SIZE_EXPAND_FILL
		aplicar_estilo_moderno_panel(panel_desplegable)
		hbox_layout_principal.add_child(panel_desplegable)
	
		var margin_desplegable = MarginContainer.new()
		margin_desplegable.add_theme_constant_override("margin_left", 12)
		margin_desplegable.add_theme_constant_override("margin_top", 12)
		margin_desplegable.add_theme_constant_override("margin_right", 12)
		margin_desplegable.add_theme_constant_override("margin_bottom", 12)
		panel_desplegable.add_child(margin_desplegable)
	
		var contenedor_contenido_desplegable = VBoxContainer.new()
		contenedor_contenido_desplegable.add_theme_constant_override("separation", 0)
		margin_desplegable.add_child(contenedor_contenido_desplegable)

		var panel_info = PanelContainer.new()
		panel_info.custom_minimum_size = Vector2(0, 110)
		contenedor_contenido_desplegable.add_child(panel_info)
	
		var margin_info = MarginContainer.new()
		margin_info.add_theme_constant_override("margin_left", 8)
		margin_info.add_theme_constant_override("margin_top", 8)
		margin_info.add_theme_constant_override("margin_right", 8)
		margin_info.add_theme_constant_override("margin_bottom", 8)
		panel_info.add_child(margin_info)
	
		var lbl_info = RichTextLabel.new()
		lbl_info.text = "Select a hexagon."
		lbl_info.bbcode_enabled = true
		lbl_info.fit_content = true
		lbl_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_info.add_theme_font_size_override("normal_font_size", 14)
		margin_info.add_child(lbl_info)
	
		var spacer_info = Control.new()
		spacer_info.custom_minimum_size = Vector2(0, 12)
		contenedor_contenido_desplegable.add_child(spacer_info)
	
		# 1. SECCIÓN: PINCEL
		var panel_biomas = VBoxContainer.new()
		panel_biomas.visible = false
		panel_biomas.size_flags_vertical = Control.SIZE_EXPAND_FILL
		panel_biomas.add_theme_constant_override("separation", 8)
		contenedor_contenido_desplegable.add_child(panel_biomas)

		var scroll_biomas = ScrollContainer.new()
		scroll_biomas.size_flags_vertical = Control.SIZE_EXPAND_FILL
		panel_biomas.add_child(scroll_biomas)
	
		var vbox_biomas = VBoxContainer.new()
		vbox_biomas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox_biomas.add_theme_constant_override("separation", 10)
		scroll_biomas.add_child(vbox_biomas)
	
		var crear_titulo = func(txt: String) -> Label:
			var lbl = Label.new(); lbl.text = txt
			lbl.add_theme_font_size_override("font_size", 14)
			lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			return lbl
		
		vbox_biomas.add_child(crear_titulo.call("🌍 Biomes"))
		var grid_biomas = GridContainer.new()
		grid_biomas.columns = 3; grid_biomas.add_theme_constant_override("h_separation", 6); grid_biomas.add_theme_constant_override("v_separation", 6)
		vbox_biomas.add_child(grid_biomas)

		vbox_biomas.add_child(crear_titulo.call("⛰️ Terrains"))
		var grid_terrenos = GridContainer.new()
		grid_terrenos.columns = 3; grid_terrenos.add_theme_constant_override("h_separation", 6); grid_terrenos.add_theme_constant_override("v_separation", 6)
		vbox_biomas.add_child(grid_terrenos)

		vbox_biomas.add_child(crear_titulo.call("✨ Features"))
		var grid_carac = GridContainer.new()
		grid_carac.columns = 3; grid_carac.add_theme_constant_override("h_separation", 6); grid_carac.add_theme_constant_override("v_separation", 6)
		vbox_biomas.add_child(grid_carac)
	
		vbox_biomas.add_child(HSeparator.new())
		var lbl_recursos = Label.new()
		lbl_recursos.text = "💎 Available Resources:"
		lbl_recursos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_recursos.add_theme_font_size_override("font_size", 13)
		vbox_biomas.add_child(lbl_recursos)
	
		var grid_recursos = GridContainer.new()
		grid_recursos.columns = 5
		grid_recursos.add_theme_constant_override("h_separation", 10)
		grid_recursos.add_theme_constant_override("v_separation", 10)
		grid_recursos.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox_biomas.add_child(grid_recursos)

		var hbox_quitar = HBoxContainer.new()
		hbox_quitar.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox_quitar.add_theme_constant_override("separation", 8)
		vbox_biomas.add_child(hbox_quitar)

		var btn_quitar_recurso = Button.new()
		btn_quitar_recurso.text = "❌ Remove Resource"
		btn_quitar_recurso.custom_minimum_size = Vector2(140, 46)
		hbox_quitar.add_child(btn_quitar_recurso)

		# --- PANTALLA DE CONSTRUCCIÓN ---
		var panel_construccion = VBoxContainer.new()
		panel_construccion.visible = false
		panel_construccion.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel_construccion.size_flags_vertical = Control.SIZE_EXPAND_FILL
		contenedor_contenido_desplegable.add_child(panel_construccion)

		var scroll_const = ScrollContainer.new()
		scroll_const.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll_const.size_flags_vertical = Control.SIZE_EXPAND_FILL
		panel_construccion.add_child(scroll_const)
	
		var vbox_const_scroll = VBoxContainer.new()
		vbox_const_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox_const_scroll.add_theme_constant_override("separation", 16)
		scroll_const.add_child(vbox_const_scroll)

	

		var lbl_header_mejoras = Label.new()
		lbl_header_mejoras.text = "⬘ IMPROVEMENTS ⬘"
		lbl_header_mejoras.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_header_mejoras.add_theme_font_size_override("font_size", 14)
		lbl_header_mejoras.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		vbox_const_scroll.add_child(lbl_header_mejoras)

		var grid_mejoras = GridContainer.new()
		grid_mejoras.columns = 5; grid_mejoras.add_theme_constant_override("h_separation", 14); grid_mejoras.add_theme_constant_override("v_separation", 10)
		grid_mejoras.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox_const_scroll.add_child(grid_mejoras)

		var lbl_header_edificios = Label.new()
		lbl_header_edificios.text = "⬘ BUILDINGS ⬘"
		lbl_header_edificios.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_header_edificios.add_theme_font_size_override("font_size", 14)
		lbl_header_edificios.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		vbox_const_scroll.add_child(lbl_header_edificios)

		var grid_edificios = GridContainer.new()
		grid_edificios.columns = 5; grid_edificios.add_theme_constant_override("h_separation", 14); grid_edificios.add_theme_constant_override("v_separation", 10)
		grid_edificios.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox_const_scroll.add_child(grid_edificios)
	
		var lbl_header_maravillas = Label.new()
		lbl_header_maravillas.text = "⬘ WONDERS ⬘"
		lbl_header_maravillas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_header_maravillas.add_theme_font_size_override("font_size", 14)
		lbl_header_maravillas.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		vbox_const_scroll.add_child(lbl_header_maravillas)

		var grid_maravillas = GridContainer.new()
		grid_maravillas.columns = 5; grid_maravillas.add_theme_constant_override("h_separation", 14); grid_maravillas.add_theme_constant_override("v_separation", 10)
		grid_maravillas.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox_const_scroll.add_child(grid_maravillas)
	
		vbox_const_scroll.add_child(HSeparator.new())
	
		var contenedor_borrar_edificios = VBoxContainer.new()
		contenedor_borrar_edificios.add_theme_constant_override("separation", 6)
		vbox_const_scroll.add_child(contenedor_borrar_edificios)

		# --- PANTALLA EXTERNOS ---
		var panel_externos = VBoxContainer.new()
		panel_externos.visible = false
		panel_externos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel_externos.size_flags_vertical = Control.SIZE_EXPAND_FILL
		panel_externos.add_theme_constant_override("separation", 6)
		contenedor_contenido_desplegable.add_child(panel_externos)

		var lbl_ext_edif = Label.new()
		lbl_ext_edif.text = "External buildings:"
		panel_externos.add_child(lbl_ext_edif)

		var scroll_ext_edif = ScrollContainer.new()
		scroll_ext_edif.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll_ext_edif.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll_ext_edif.size_flags_stretch_ratio = 0.6
		panel_externos.add_child(scroll_ext_edif)

		var contenedor_edificios_externos = GridContainer.new()
		contenedor_edificios_externos.columns = 5; contenedor_edificios_externos.add_theme_constant_override("h_separation", 14); contenedor_edificios_externos.add_theme_constant_override("v_separation", 10)
		contenedor_edificios_externos.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		scroll_ext_edif.add_child(contenedor_edificios_externos)

		var lbl_ext_mej = Label.new()
		lbl_ext_mej.text = "External improvements:"
		panel_externos.add_child(lbl_ext_mej)

		var scroll_ext_mej = ScrollContainer.new()
		scroll_ext_mej.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll_ext_mej.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll_ext_mej.size_flags_stretch_ratio = 0.4
		panel_externos.add_child(scroll_ext_mej)

		var contenedor_mejoras_externas = GridContainer.new()
		contenedor_mejoras_externas.columns = 5; contenedor_mejoras_externas.add_theme_constant_override("h_separation", 14); contenedor_mejoras_externas.add_theme_constant_override("v_separation", 10)
		contenedor_mejoras_externas.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		scroll_ext_mej.add_child(contenedor_mejoras_externas)

		var btn_del_ext = Button.new()
		btn_del_ext.text = "❌ DELETE EXTERNAL CONTENT"
		btn_del_ext.custom_minimum_size = Vector2(0, 36)
		btn_del_ext.pressed.connect(main._borrar_externo)
		panel_externos.add_child(btn_del_ext)

		# 2b. VISOR DE FELICIDAD (modo lectura: sin edición, solo cambia appeal al clicar)
		var panel_felicidad = VBoxContainer.new()
		panel_felicidad.name = "PanelFelicidad"
		panel_felicidad.visible = false
		panel_felicidad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel_felicidad.size_flags_vertical = Control.SIZE_EXPAND_FILL
		panel_felicidad.add_theme_constant_override("separation", 10)
		contenedor_contenido_desplegable.add_child(panel_felicidad)

		var lbl_fel_titulo = Label.new()
		lbl_fel_titulo.text = "😊 HAPPINESS VIEWER"
		lbl_fel_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_fel_titulo.add_theme_font_size_override("font_size", 14)
		lbl_fel_titulo.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
		panel_felicidad.add_child(lbl_fel_titulo)

		var lbl_fel_info = Label.new()
		lbl_fel_info.name = "LblFelicidadInfo"
		lbl_fel_info.text = "Click a cell to cycle:\nNormal → Appealing → Charming → Normal.\nGray = Normal, light green = Appealing, dark green = Charming."
		lbl_fel_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_fel_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_fel_info.add_theme_font_size_override("font_size", 13)
		panel_felicidad.add_child(lbl_fel_info)

		var hbox_fel_salir = HBoxContainer.new()
		hbox_fel_salir.alignment = BoxContainer.ALIGNMENT_CENTER
		panel_felicidad.add_child(hbox_fel_salir)

		var btn_salir_felicidad = Button.new()
		btn_salir_felicidad.text = "⬅ Back to Settlements"
		btn_salir_felicidad.custom_minimum_size = Vector2(220, 40)
		btn_salir_felicidad.pressed.connect(func(): main.cambiar_seccion("ASENTAMIENTOS"))
		hbox_fel_salir.add_child(btn_salir_felicidad)

		# 3. ASENTAMIENTOS, GUARDADO Y ERA
		var panel_asentamientos_ui = VBoxContainer.new()
		panel_asentamientos_ui.visible = false
		panel_asentamientos_ui.size_flags_vertical = Control.SIZE_EXPAND_FILL
		panel_asentamientos_ui.add_theme_constant_override("separation", 12)
		contenedor_contenido_desplegable.add_child(panel_asentamientos_ui)
	
		var hbox_top_actions = HBoxContainer.new()
		hbox_top_actions.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox_top_actions.add_theme_constant_override("separation", 8)
		panel_asentamientos_ui.add_child(hbox_top_actions)
	
		var btn_nueva_partida = Button.new()
		btn_nueva_partida.text = "🌟 New Game"
		btn_nueva_partida.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_nueva_partida.custom_minimum_size = Vector2(0, 38)
		var style_nv = StyleBoxFlat.new()
		style_nv.bg_color = Color(0.2, 0.6, 0.2)
		style_nv.set_corner_radius_all(6)
		btn_nueva_partida.add_theme_stylebox_override("normal", style_nv)
		btn_nueva_partida.pressed.connect(main.mostrar_dialogo_lideres_inicio) # <-- Modificado para ir a Lider primero
		hbox_top_actions.add_child(btn_nueva_partida)
	
		var btn_guardar = Button.new()
		btn_guardar.text = "💾 Save"
		btn_guardar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_guardar.custom_minimum_size = Vector2(0, 38)
		var style_sv = StyleBoxFlat.new()
		style_sv.bg_color = Color(0.2, 0.45, 0.8)
		style_sv.set_corner_radius_all(6)
		btn_guardar.add_theme_stylebox_override("normal", style_sv)
		btn_guardar.pressed.connect(main.mostrar_dialogo_guardar_como)
		hbox_top_actions.add_child(btn_guardar)
	
		var btn_cargar = Button.new()
		btn_cargar.text = "📁 Load"
		btn_cargar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_cargar.custom_minimum_size = Vector2(0, 38)
		var style_ld = StyleBoxFlat.new()
		style_ld.bg_color = Color(0.75, 0.2, 0.2)
		style_ld.set_corner_radius_all(6)
		btn_cargar.add_theme_stylebox_override("normal", style_ld)
		btn_cargar.pressed.connect(main.mostrar_dialogo_cargar)
		hbox_top_actions.add_child(btn_cargar)

		# --- Panel Compacto Superior (Era + Lider + Civ + Botones) ---
		var panel_estado_era = PanelContainer.new()
		aplicar_estilo_moderno_panel(panel_estado_era)
		panel_asentamientos_ui.add_child(panel_estado_era)
	
		var margin_ee = MarginContainer.new()
		margin_ee.add_theme_constant_override("margin_left", 8)
		margin_ee.add_theme_constant_override("margin_top", 8)
		margin_ee.add_theme_constant_override("margin_right", 8)
		margin_ee.add_theme_constant_override("margin_bottom", 8)
		panel_estado_era.add_child(margin_ee)
	
		var hbox_ee = HBoxContainer.new()
		hbox_ee.add_theme_constant_override("separation", 16)
		hbox_ee.alignment = BoxContainer.ALIGNMENT_CENTER
		margin_ee.add_child(hbox_ee)
	
		# Columna 1: Textos (Save/Era)
		var vbox_labels = VBoxContainer.new()
		vbox_labels.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox_labels.add_theme_constant_override("separation", 6)
		hbox_ee.add_child(vbox_labels)
	
		var lbl_nombre_partida = Label.new()
		lbl_nombre_partida.text = "💾 Autosave"
		lbl_nombre_partida.add_theme_font_size_override("font_size", 12)
		vbox_labels.add_child(lbl_nombre_partida)
	
		var lbl_era_actual = Label.new()
		lbl_era_actual.text = "🏛️ Antiquity"
		lbl_era_actual.add_theme_font_size_override("font_size", 12)
		vbox_labels.add_child(lbl_era_actual)

		# Columna 2: Visual Líder (Entre Era y Civ)
		var vbox_lider = VBoxContainer.new()
		vbox_lider.alignment = BoxContainer.ALIGNMENT_CENTER
		var tex_lider = TextureRect.new()
		tex_lider.custom_minimum_size = Vector2(40, 40)
		tex_lider.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_lider.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vbox_lider.add_child(tex_lider)
		var lbl_lider_nombre = Label.new()
		lbl_lider_nombre.add_theme_font_size_override("font_size", 11)
		lbl_lider_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox_lider.add_child(lbl_lider_nombre)
		hbox_ee.add_child(vbox_lider)
	
		# Columna 3: Visual Civ
		var lbl_civ_actual = HBoxContainer.new()
		lbl_civ_actual.add_theme_constant_override("separation", 8)
		lbl_civ_actual.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox_ee.add_child(lbl_civ_actual)
	
		var contenedor_civs_visual = HBoxContainer.new()
		contenedor_civs_visual.name = "ContenedorCivsVisual"
		contenedor_civs_visual.add_theme_constant_override("separation", 8)
		lbl_civ_actual.add_child(contenedor_civs_visual)
	
		# Columna 4: Botones
		var buttons_vbox = VBoxContainer.new()
		buttons_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		buttons_vbox.add_theme_constant_override("separation", 6)
		hbox_ee.add_child(buttons_vbox)
	
		var btn_sincretismo = Button.new()
		btn_sincretismo.text = "Syncretism"
		btn_sincretismo.custom_minimum_size = Vector2(100, 26)
		btn_sincretismo.add_theme_font_size_override("font_size", 11)
		var style_sync = StyleBoxFlat.new()
		style_sync.bg_color = Color(0.18, 0.18, 0.22)
		style_sync.border_color = Color(0.4, 0.4, 0.45)
		style_sync.set_border_width_all(1)
		style_sync.set_corner_radius_all(6)
		btn_sincretismo.add_theme_stylebox_override("normal", style_sync)
		btn_sincretismo.pressed.connect(main.mostrar_dialogo_sincretismo)
		buttons_vbox.add_child(btn_sincretismo)
	
		var btn_avanzar_era = Button.new()
		btn_avanzar_era.text = "Exploration"
		btn_avanzar_era.custom_minimum_size = Vector2(100, 26)
		btn_avanzar_era.add_theme_font_size_override("font_size", 11)
		var style_btn = StyleBoxFlat.new()
		style_btn.set_corner_radius_all(6)
		btn_avanzar_era.add_theme_stylebox_override("normal", style_btn)
		btn_avanzar_era.pressed.connect(main.mostrar_panel_politicas_cambio_era)
		buttons_vbox.add_child(btn_avanzar_era)

		var lbl_asent_title = Label.new()
		lbl_asent_title.text = "🏛️ SETTLEMENT MANAGEMENT"
		lbl_asent_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel_asentamientos_ui.add_child(lbl_asent_title)
	
		var hbox_add = HBoxContainer.new()
		hbox_add.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox_add.add_theme_constant_override("separation", 10)
		panel_asentamientos_ui.add_child(hbox_add)
	
		var btn_add_pueblo = Button.new()
		btn_add_pueblo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_add_pueblo.custom_minimum_size = Vector2(0, 42)
	
		var hb_p = HBoxContainer.new()
		hb_p.set_anchors_preset(Control.PRESET_FULL_RECT)
		hb_p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb_p.alignment = BoxContainer.ALIGNMENT_CENTER
		hb_p.add_theme_constant_override("separation", 8)
	
		var tex_p = TextureRect.new()
		tex_p.custom_minimum_size = Vector2(24, 24)
		tex_p.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_p.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if ResourceLoader.exists("res://assets/town.png"): tex_p.texture = load("res://assets/town.png")
		hb_p.add_child(tex_p)
	
		var lbl_p = Label.new()
		lbl_p.text = "Town"
		hb_p.add_child(lbl_p)
		btn_add_pueblo.add_child(hb_p)
		btn_add_pueblo.pressed.connect(func(): main.crear_nuevo_asentamiento("Town"))
		hbox_add.add_child(btn_add_pueblo)
	
		var btn_add_ciudad = Button.new()
		btn_add_ciudad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_add_ciudad.custom_minimum_size = Vector2(0, 42)
	
		var hb_c = HBoxContainer.new()
		hb_c.set_anchors_preset(Control.PRESET_FULL_RECT)
		hb_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb_c.alignment = BoxContainer.ALIGNMENT_CENTER
		hb_c.add_theme_constant_override("separation", 8)
	
		var tex_c = TextureRect.new()
		tex_c.custom_minimum_size = Vector2(24, 24)
		tex_c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_c.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if ResourceLoader.exists("res://assets/settlement.png"): tex_c.texture = load("res://assets/settlement.png")
		hb_c.add_child(tex_c)
	
		var lbl_c = Label.new()
		lbl_c.text = "City"
		hb_c.add_child(lbl_c)
		btn_add_ciudad.add_child(hb_c)
		btn_add_ciudad.pressed.connect(func(): main.crear_nuevo_asentamiento("City"))
		hbox_add.add_child(btn_add_ciudad)
	
		var scroll_lista_asent = ScrollContainer.new()
		scroll_lista_asent.size_flags_vertical = Control.SIZE_EXPAND_FILL
		panel_asentamientos_ui.add_child(scroll_lista_asent)
	
		var contenedor_lista_asentamientos = VBoxContainer.new()
		contenedor_lista_asentamientos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		contenedor_lista_asentamientos.add_theme_constant_override("separation", 6)
		scroll_lista_asent.add_child(contenedor_lista_asentamientos)

		btn_menu_asentamientos.pressed.connect(func(): main.cambiar_seccion("ASENTAMIENTOS"))
		btn_menu_pincel.pressed.connect(func(): main.cambiar_seccion("PINCEL"))
		btn_modo_construccion.pressed.connect(func(): main.cambiar_seccion("CONSTRUCCION"))
		btn_modo_externos.pressed.connect(func(): main.cambiar_seccion("EXTERNOS"))
		btn_menu_felicidad.pressed.connect(func(): main.cambiar_seccion("FELICIDAD"))
		btn_mementos.pressed.connect(func(): main.mostrar_dialogo_mementos())
		btn_rivales.pressed.connect(func(): main.mostrar_dialogo_rivales())
		btn_politicas.pressed.connect(func(): main.mostrar_dialogo_politicas())
		btn_quitar_recurso.pressed.connect(func(): main._aplicar_recurso(""))

		return {
			"btn_menu_pincel": btn_menu_pincel,
			"btn_menu_asentamientos": btn_menu_asentamientos,
			"btn_modo_construccion": btn_modo_construccion,
			"btn_modo_externos": btn_modo_externos,
			"btn_menu_felicidad": btn_menu_felicidad,
			"panel_felicidad": panel_felicidad,
			"panel_biomas": panel_biomas,
			"panel_construccion": panel_construccion,
			"grid_biomas": grid_biomas,
			"grid_terrenos": grid_terrenos,
			"grid_carac": grid_carac,
			"grid_recursos": grid_recursos,
			"grid_mejoras": grid_mejoras,
			"lbl_header_mejoras": lbl_header_mejoras,
			"grid_edificios": grid_edificios,
			"lbl_header_edificios": lbl_header_edificios,
			"grid_maravillas": grid_maravillas,
			"lbl_header_maravillas": lbl_header_maravillas,
			"contenedor_borrar_edificios": contenedor_borrar_edificios,
			"panel_externos": panel_externos,
			"contenedor_edificios_externos": contenedor_edificios_externos,
			"contenedor_mejoras_externas": contenedor_mejoras_externas,
			"panel_asentamientos_ui": panel_asentamientos_ui,
			"contenedor_lista_asentamientos": contenedor_lista_asentamientos,
			"btn_quitar_recurso": btn_quitar_recurso,
			"lbl_era_actual": lbl_era_actual,
			"lbl_civ_actual": lbl_civ_actual,
			"btn_avanzar_era": btn_avanzar_era,
			"btn_sincretismo": btn_sincretismo,
			"tex_lider": tex_lider,
			"lbl_lider_nombre": lbl_lider_nombre,
			"panel_info": panel_info,
			"lbl_info": lbl_info,
			"lbl_nombre_partida": lbl_nombre_partida,
			"scroll_biomas": scroll_biomas,
			"lbl_ext_edif": lbl_ext_edif,
			"lbl_ext_mej": lbl_ext_mej,
			"scroll_ext_edif": scroll_ext_edif,
			"scroll_ext_mej": scroll_ext_mej,
			"btn_del_ext": btn_del_ext
		}
