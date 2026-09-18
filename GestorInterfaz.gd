extends Node

func aplicar_estilo_moderno_panel(panel: Control):
	if panel is PanelContainer:
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color("#181820")
		sb.border_color = Color("#2a2a38")
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(10)
		sb.shadow_color = Color(0, 0, 0, 0.4)
		sb.shadow_size = 8
		panel.add_theme_stylebox_override("panel", sb)

func crear_boton_menu(icono: String, tooltip: String) -> Button:
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

func construir_interfaz_principal(main: Node2D) -> Dictionary:
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
	
	vbox_navegacion.add_child(btn_menu_asentamientos)
	vbox_navegacion.add_child(btn_menu_pincel)
	vbox_navegacion.add_child(btn_modo_construccion)
	vbox_navegacion.add_child(btn_modo_externos)
	
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
	
	vbox_biomas.add_child(crear_titulo.call("💖 Happiness and Appeal"))
	var hbox_favs = HBoxContainer.new()
	hbox_favs.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_favs.add_theme_constant_override("separation", 6)
	vbox_biomas.add_child(hbox_favs)
			
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

	var lbl_header_genericos = Label.new()
	lbl_header_genericos.text = "⬘ GENERIC MARKERS ⬘"
	lbl_header_genericos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_header_genericos.add_theme_font_size_override("font_size", 14)
	lbl_header_genericos.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vbox_const_scroll.add_child(lbl_header_genericos)
	
	var grid_genericos = GridContainer.new()
	grid_genericos.columns = 5; grid_genericos.add_theme_constant_override("h_separation", 14); grid_genericos.add_theme_constant_override("v_separation", 10)
	grid_genericos.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox_const_scroll.add_child(grid_genericos)

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
	btn_avanzar_era.pressed.connect(main.mostrar_dialogo_confirmar_siguiente_era)
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
	btn_quitar_recurso.pressed.connect(func(): main._aplicar_recurso(""))

	return {
		"btn_menu_pincel": btn_menu_pincel,
		"btn_menu_asentamientos": btn_menu_asentamientos,
		"btn_modo_construccion": btn_modo_construccion,
		"btn_modo_externos": btn_modo_externos,
		"panel_biomas": panel_biomas,
		"panel_construccion": panel_construccion,
		"grid_biomas": grid_biomas,
		"grid_terrenos": grid_terrenos,
		"grid_carac": grid_carac,
		"hbox_favs": hbox_favs,
		"grid_recursos": grid_recursos,
		"grid_genericos": grid_genericos,
		"lbl_header_genericos": lbl_header_genericos,
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
