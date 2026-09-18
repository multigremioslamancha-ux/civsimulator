extends Node

func verificar_expansion_territorio(main: Node2D, coord: Vector2i):
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

func calcular_sugerencias_edificios(main: Node2D) -> Dictionary:
	var sugerencias = {}
	if main.asentamientos.size() == 0 or main.asentamiento_activo_idx >= main.asentamientos.size(): return sugerencias
	var asent_centro = main.asentamientos[main.asentamiento_activo_idx].centro
	var era_actual = main.era_actual
	var civ_actual = main.civ_actual
	var civ_sincretismo = main.civ_sincretismo
	var asent_tipo = main.asentamientos[main.asentamiento_activo_idx].tipo
	
	for coord in main.city_grid.keys():
		var d = main.city_grid[coord]
		if d.ajeno: continue 
		if d.terreno == "NATURAL_WONDER" or d.get("caracteristica", "") == "NATURAL_WONDER": continue
		
		var normales = 0
		var tiene_wonder = false
		var es_centro = false
		
		# Contamos edificios, ignorando completamente las murallas
		for e in d.edificios:
			if e in ["Palace", "Town Hall"]:
				es_centro = true
			elif Constantes.DATOS_EDIFICIOS.get(e, {}).get("is_wonder", false):
				tiene_wonder = true
			elif not ReglasJuego.es_edificio_muralla(e):
				normales += 1
				
		var max_normales = 1 if es_centro else 2
		var llena_edificios = (tiene_wonder or normales >= max_normales)
		
		if llena_edificios:
			continue
		
		var lista_sug = []
		for edif_nombre in Constantes.DATOS_EDIFICIOS.keys():
			var datos_edif = Constantes.DATOS_EDIFICIOS[edif_nombre]
			if datos_edif.get("is_generic", false) or edif_nombre in ["Palace", "Town Hall"]: continue
			
			# EXCLUIMOS LAS MURALLAS DEL PANEL DE CONSTRUCCIÓN NORMAL
			if ReglasJuego.es_edificio_muralla(edif_nombre): continue
			
			var es_nueva_wonder = datos_edif.get("is_wonder", false)
			
			if es_nueva_wonder:
				if tiene_wonder or normales > 0 or es_centro: continue
			else:
				if tiene_wonder or normales >= max_normales: continue
			
			var era_edif = datos_edif.get("era", "All")
			if era_edif != "All" and Constantes.ORDEN_ERAS.get(era_edif, 0) > Constantes.ORDEN_ERAS.get(era_actual, 0): continue
			if datos_edif.has("civ") and datos_edif.civ != civ_actual and datos_edif.civ != civ_sincretismo: continue
			
			if ReglasJuego.es_ubicacion_valida_para_edificio(coord, edif_nombre, asent_centro, era_actual, civ_actual, main.city_grid, asent_tipo, main.asentamientos):
				lista_sug.append({"edificio": edif_nombre, "datos": datos_edif})
				
		if lista_sug.size() > 0:
			sugerencias[coord] = lista_sug
			
	return sugerencias

func aplicar_edificio(main: Node2D, edificio: String):
	if not main.city_grid.has(main.celda_seleccionada): return
	var datos = main.city_grid[main.celda_seleccionada]
	
	if datos.get("mejora_tipo", "") != "":
		datos.mejora_tipo = ""
	
	if not datos.edificios.has(edificio):
		datos.edificios.append(edificio)
		
	verificar_expansion_territorio(main, main.celda_seleccionada)
	
	main.actualizar_sugerencias_cache()
	main.actualizar_panel_construccion()
	main.actualizar_icono_celda(main.celda_seleccionada)
	main.actualizar_panel_ui()
	main.guardar_partida_actual()
	main.queue_redraw()

func aplicar_mejora(main: Node2D, tipo: String):
	if not main.city_grid.has(main.celda_seleccionada): return
	var datos = main.city_grid[main.celda_seleccionada]
	
	datos.mejora_tipo = tipo
	verificar_expansion_territorio(main, main.celda_seleccionada)
	
	main.actualizar_sugerencias_cache()
	main.actualizar_panel_construccion()
	main.actualizar_icono_celda(main.celda_seleccionada)
	main.actualizar_panel_ui()
	main.guardar_partida_actual()
	main.queue_redraw()

func borrar_edificio_especifico(main: Node2D, edificio_nombre: String):
	if not main.city_grid.has(main.celda_seleccionada): return
	var datos = main.city_grid[main.celda_seleccionada]
	if datos.edificios.has(edificio_nombre):
		datos.edificios.erase(edificio_nombre)
		main.actualizar_sugerencias_cache()
		main.actualizar_panel_construccion()
		main.actualizar_icono_celda(main.celda_seleccionada)
		main.actualizar_panel_ui()
		main.guardar_partida_actual()
		main.queue_redraw()

func borrar_mejora(main: Node2D):
	if not main.city_grid.has(main.celda_seleccionada): return
	var datos = main.city_grid[main.celda_seleccionada]
	datos.mejora_tipo = ""
	main.actualizar_sugerencias_cache()
	main.actualizar_panel_construccion()
	main.actualizar_icono_celda(main.celda_seleccionada)
	main.actualizar_panel_ui()
	main.guardar_partida_actual()
	main.queue_redraw()

func aplicar_edificio_externo(main: Node2D, edificio: String):
	if not main.city_grid.has(main.celda_seleccionada): return
	var datos = main.city_grid[main.celda_seleccionada]
	datos.ajeno = true
	
	if datos.get("mejora_tipo", "") != "":
		datos.mejora_tipo = ""
		
	if not datos.edificios.has(edificio): datos.edificios.append(edificio)
	
	verificar_expansion_territorio(main, main.celda_seleccionada)
	
	main.actualizar_panel_externos()
	main.actualizar_visibilidad_boton_externos()
	main.actualizar_icono_celda(main.celda_seleccionada)
	main.actualizar_panel_ui()
	main.guardar_partida_actual()
	main.queue_redraw()

func aplicar_mejora_externo(main: Node2D, mejora: String):
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

func borrar_externo(main: Node2D):
	if not main.city_grid.has(main.celda_seleccionada): return
	var datos = main.city_grid[main.celda_seleccionada]
	datos.ajeno = false
	datos.edificios.clear()
	datos.mejora_tipo = ""
	main.actualizar_panel_externos()
	main.actualizar_visibilidad_boton_externos()
	main.actualizar_icono_celda(main.celda_seleccionada)
	main.actualizar_panel_ui()
	main.guardar_partida_actual()
	main.queue_redraw()
