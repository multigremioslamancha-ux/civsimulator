extends Node

func mostrar_dialogo_renombrar(main: Node2D, idx: int):
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
	main.get_tree().root.add_child(dialog)
	dialog.popup_centered(Vector2(300, 150))

func mostrar_dialogo_borrar_asentamiento(main: Node2D, idx: int):
	var dialog = ConfirmationDialog.new()
	dialog.title = "Delete Settlement"
	dialog.dialog_text = "¿Are you sure you want to delete '" + main.asentamientos[idx].nombre + "' and all its terrain?"
	dialog.confirmed.connect(func():
		GestorAsentamientos.ejecutar_borrado_asentamiento(main, idx)
		dialog.queue_free()
	)
	main.get_tree().root.add_child(dialog)
	dialog.popup_centered(Vector2(320, 150))

func mostrar_dialogo_lideres_inicio(main: Node2D, iniciar_nueva_partida_despues: bool = true):
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
			mostrar_dialogo_nueva_partida(main)
			
		dialog.queue_free()
	)
	
	dialog.close_requested.connect(func(): dialog.queue_free())
	main.get_tree().root.add_child(dialog)
	dialog.popup_centered(Vector2(620, 380))

func mostrar_dialogo_nueva_partida(main: Node2D):
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
	main.get_tree().root.add_child(dialog)
	dialog.popup_centered(Vector2(620, 460))

func mostrar_dialogo_sincretismo(main: Node2D):
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
	main.get_tree().root.add_child(dialog)
	dialog.popup_centered(Vector2(700, 480))

func mostrar_dialogo_confirmar_siguiente_era(main: Node2D):
	var siguiente = ""
	if main.era_actual == "Antiquity": siguiente = "Exploration"
	elif main.era_actual == "Exploration": siguiente = "Modern Age"
	if siguiente == "": return
	
	var dialog = ConfirmationDialog.new()
	dialog.title = "New Era: " + siguiente + "!"
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	
	var lbl_adv = Label.new()
	lbl_adv.text = "All resources will be cleared from the map."
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
	main.get_tree().root.add_child(dialog)
	dialog.popup_centered(Vector2(700, 600))
