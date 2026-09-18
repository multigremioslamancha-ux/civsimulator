extends Node

func parsear_vector2i(valor) -> Vector2i:
	if typeof(valor) == TYPE_VECTOR2I:
		return valor
	if typeof(valor) == TYPE_ARRAY and valor.size() >= 2:
		return Vector2i(int(valor[0]), int(valor[1]))
		
	var limpia = str(valor).replace("Vector2i", "").replace("(", "").replace(")", "").replace(" ", "")
	var partes = limpia.split(",")
	if partes.size() >= 2:
		return Vector2i(partes[0].to_int(), partes[1].to_int())
	return Vector2i.ZERO

func cargar_local() -> Dictionary:
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

func guardar_partida_actual(main: Node2D):
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
		"asentamientos": asentamientos_limpios
	}
	
	main.partidas_guardadas[main.partida_actual_nombre] = extra_data
	var archivo = FileAccess.open("user://saves_civ7.json", FileAccess.WRITE)
	if archivo: 
		archivo.store_string(JSON.stringify(main.partidas_guardadas))
	
	if main.lbl_nombre_partida:
		main.lbl_nombre_partida.text = "💾 Game: " + main.partida_actual_nombre

func cargar_partida_especifica(main: Node2D, nombre: String) -> bool:
	if not main.partidas_guardadas.has(nombre): return false
	var datos_partida = main.partidas_guardadas[nombre]
	
	main.partida_actual_nombre = nombre
	main.era_actual = datos_partida.get("era_actual", "Antiquity")
	main.civ_actual = datos_partida.get("civ_actual", "None")
	main.civ_sincretismo = datos_partida.get("civ_sincretismo", "None")
	main.lider_actual = datos_partida.get("lider_actual", "Augustus") # ¡AQUÍ SE CARGA EL LÍDER!
	main.era_transicionada = datos_partida.get("era_transicionada", main.era_actual != "Antiquity")
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
			
			var hbox_terreno = HBoxContainer.new()
			hbox_terreno.custom_minimum_size = Vector2(40, 40)
			hbox_terreno.alignment = BoxContainer.ALIGNMENT_CENTER
			hbox_terreno.position = centro_px - Vector2(20, -main.radio_hex * 0.15)
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

func mostrar_dialogo_guardar_como(main: Node2D):
	var dialog = AcceptDialog.new()
	dialog.title = "Save Game As..."
	var vbox = VBoxContainer.new()
	var line_edit = LineEdit.new()
	line_edit.text = main.partida_actual_nombre
	line_edit.custom_minimum_size = Vector2(250, 40)
	vbox.add_child(line_edit)
	dialog.add_child(vbox)
	
	dialog.confirmed.connect(func():
		var n_name = line_edit.text.strip_edges()
		if n_name != "":
			main.partida_actual_nombre = n_name
			guardar_partida_actual(main)
			main.actualizar_panel_gestion_ui()
		dialog.queue_free()
	)
	main.get_tree().root.add_child(dialog)
	dialog.popup_centered(Vector2(300, 150))

func mostrar_dialogo_cargar(main: Node2D):
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
	main.get_tree().root.add_child(dialog)
	dialog.popup_centered(Vector2(380, 320))

func mostrar_dialogo_confirmar_borrado(main: Node2D, nombre_partida: String, parent_dialog: Window):
	var confirm = ConfirmationDialog.new()
	confirm.title = "Confirm Deletion"
	confirm.dialog_text = "Are you sure you want to delete the save '" + nombre_partida + "'?"
	
	confirm.confirmed.connect(func():
		main.partidas_guardadas.erase(nombre_partida)
		var archivo = FileAccess.open("user://saves_civ7.json", FileAccess.WRITE)
		if archivo: archivo.store_string(JSON.stringify(main.partidas_guardadas))
		confirm.queue_free()
		parent_dialog.queue_free()
		mostrar_dialogo_cargar(main)
	)
	
	main.get_tree().root.add_child(confirm)
	confirm.popup_centered(Vector2(340, 150))
