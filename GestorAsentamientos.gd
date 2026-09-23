extends Node

func iniciar_nueva_partida(main: Node2D, era: String, civ: String):
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

func crear_asentamiento_inicial(main: Node2D, nombre: String, tipo: String, centro: Vector2i, es_capital: bool):
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
			
			var hbox_terreno = HBoxContainer.new()
			hbox_terreno.custom_minimum_size = Vector2(40, 40)
			hbox_terreno.alignment = BoxContainer.ALIGNMENT_CENTER
			hbox_terreno.position = centro_px - Vector2(20, -main.radio_hex * 0.15)
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

func cambiar_asentamiento_activo(main: Node2D, idx: int):
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

func crear_nuevo_asentamiento(main: Node2D, tipo: String):
	var nombre = "Town " + str(main.asentamientos.size()) if tipo == "Town" else "City " + str(main.asentamientos.size())
	crear_asentamiento_inicial(main, nombre, tipo, Vector2i(0, 0), false)

func resetear_asentamiento(main: Node2D, idx: int):
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

func ejecutar_borrado_asentamiento(main: Node2D, idx: int):
	if idx >= 0 and idx < main.asentamientos.size():
		main.asentamientos.remove_at(idx)
		if main.asentamiento_activo_idx >= main.asentamientos.size():
			main.asentamiento_activo_idx = max(0, main.asentamientos.size() - 1)
		cambiar_asentamiento_activo(main, main.asentamiento_activo_idx)
		main.guardar_partida_actual()

func cambiar_era(main: Node2D, nueva_era: String, nueva_civ: String, idx_nueva_capital: int, dorados_seleccionados: Array = []):
	main.era_actual = nueva_era
	main.civ_actual = nueva_civ
	main.civ_sincretismo = "None"
	main.era_transicionada = true
	
	for i in range(main.asentamientos.size()):
		var asent = main.asentamientos[i]
		for coord in asent.grid.keys():
			var c = asent.grid[coord]
			c.recurso = ""
			c.edificios_dorados.clear()
			for edif_oro in dorados_seleccionados:
				if c.edificios.has(edif_oro): c.edificios_dorados.append(edif_oro)
		
		var c_datos = asent.grid[asent.centro]
		if i == idx_nueva_capital:
			asent.tipo = "Capital"
			if c_datos.edificios.has("Town Hall"): c_datos.edificios.erase("Town Hall")
			if not c_datos.edificios.has("Palace"): c_datos.edificios.append("Palace")
		else:
			asent.tipo = "Town"
			if c_datos.edificios.has("Palace"): c_datos.edificios.erase("Palace")
			if not c_datos.edificios.has("Town Hall"): c_datos.edificios.append("Town Hall")
			
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
