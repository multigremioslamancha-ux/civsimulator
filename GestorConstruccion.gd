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

func calcular_sugerencias_edificios(main: Node) -> Dictionary:
	var sugerencias = {}
	if main.asentamientos.size() == 0 or main.asentamiento_activo_idx >= main.asentamientos.size():
		return sugerencias
	
	var asent = main.asentamientos[main.asentamiento_activo_idx]
	var asent_centro = asent.centro
	var asent_tipo = asent.tipo
	var era = main.era_actual
	var civ = main.civ_actual
	
	var edificios_construidos = {}
	for c in main.city_grid.values():
		for e in c.edificios:
			if not es_edificio_obsoleto(e, c.q * Vector2i.RIGHT + c.r * Vector2i.DOWN, era, main.city_grid):
				edificios_construidos[e] = true
				
	var rendimiento_tiene_edificios_disponibles = func(r_tipo: String) -> bool:
		for edif_nombre in Constantes.DATOS_EDIFICIOS.keys():
			var d = Constantes.DATOS_EDIFICIOS[edif_nombre]
			if d.get("is_generic", false) and d.get("rendimiento", "") == r_tipo:
				var era_edif = d.get("era", "All")
				if era_edif == "All" or Constantes.ORDEN_ERAS.get(era_edif, 0) <= Constantes.ORDEN_ERAS.get(era, 0):
					return true
					
		for edif_nombre in Constantes.DATOS_EDIFICIOS.keys():
			var d = Constantes.DATOS_EDIFICIOS[edif_nombre]
			if d.get("is_wonder", false) or d.get("is_generic", false): continue
			if edif_nombre in ["Palace", "Town Hall"]: continue
			
			var rend = d.get("rendimiento", "")
			var rend_sec = d.get("rendimiento_secundario", "")
			if rend == r_tipo or rend_sec == r_tipo:
				var era_edif = d.get("era", "All")
				if era_edif != "All" and Constantes.ORDEN_ERAS.get(era_edif, 0) > Constantes.ORDEN_ERAS.get(era, 0): continue
				if d.has("civ") and d.civ != civ and d.civ != main.civ_sincretismo: continue
				if edificios_construidos.has(edif_nombre): continue
				return true
				
		return false

	var maravillas_construidas = {}
	for c in main.city_grid.values():
		for e in c.edificios:
			var d_e = Constantes.DATOS_EDIFICIOS.get(e, {})
			if d_e.get("is_wonder", false):
				maravillas_construidas[e] = true
				
	var top_por_rend = {
		"Food": [], "Production": [], "Gold": [], "Science": [], "Culture": [], "Happiness": [], "Influence": []
	}
	var top_warehouses = []
	
	for coord in main.city_grid.keys():
		var dist = HexMath.dist_hex(coord, asent_centro)
		if dist < 1 or dist > 3: continue
		
		var datos = main.city_grid[coord]
		if datos.get("ajeno", false): continue
		if datos.edificios.size() > 0 or datos.mejora_tipo != "": continue
		if datos.get("caracteristica", "") == "NATURAL_WONDER" or datos.terreno == "NATURAL_WONDER": continue
		
		for edif_nombre in Constantes.DATOS_EDIFICIOS.keys():
			var d_edif = Constantes.DATOS_EDIFICIOS[edif_nombre]
			var is_generic = d_edif.get("is_generic", false)
			var is_warehouse = d_edif.get("tipo", "") == "Warehouse"
			
			if not is_generic and not is_warehouse: continue
			
			var era_edif = d_edif.get("era", "All")
			if era_edif != "All" and Constantes.ORDEN_ERAS.get(era_edif, 0) > Constantes.ORDEN_ERAS.get(era, 0): continue
			if not es_ubicacion_valida_para_edificio(coord, edif_nombre, asent_centro, era, civ, main.city_grid, asent_tipo, main.asentamientos): continue
			
			var ady = calcular_bono_edificio(coord, edif_nombre, era, main.city_grid)
			var total = d_edif.get("base", 0) + ady
			
			if is_warehouse:
				top_warehouses.append({"coord": coord, "score": total + ady, "edificio": edif_nombre})
			elif is_generic:
				var rend = d_edif.get("rendimiento", "")
				if top_por_rend.has(rend) and rendimiento_tiene_edificios_disponibles.call(rend):
					top_por_rend[rend].append({"coord": coord, "score": total, "edificio": edif_nombre})
					
	var celdas_optimas_rendimiento = {}
	for r_key in top_por_rend.keys():
		var arr = top_por_rend[r_key]
		arr.sort_custom(func(a, b): return a.score > b.score)
		var limit = min(3, arr.size())
		for i in range(limit):
			if arr[i].score > 0:
				var c = arr[i].coord
				celdas_optimas_rendimiento[c] = true
				if not sugerencias.has(c): sugerencias[c] = []
				sugerencias[c].append({"edificio": arr[i].edificio})
				
	top_warehouses.sort_custom(func(a, b): return a.score > b.score)
	var count_w = 0
	for w in top_warehouses:
		if not celdas_optimas_rendimiento.has(w.coord):
			if not sugerencias.has(w.coord): sugerencias[w.coord] = []
			var existe = false
			for s in sugerencias[w.coord]:
				if s.edificio == w.edificio: existe = true
			if not existe:
				sugerencias[w.coord].append({"edificio": w.edificio})
				count_w += 1
			if count_w >= 3: break
			
	var maravillas_candidatas = []
	for edif_nombre in Constantes.DATOS_EDIFICIOS.keys():
		var d_edif = Constantes.DATOS_EDIFICIOS[edif_nombre]
		if not d_edif.get("is_wonder", false) or d_edif.get("is_generic", false): continue 
		if maravillas_construidas.has(edif_nombre): continue
		
		var era_edif = d_edif.get("era", "All")
		if era_edif != "All" and Constantes.ORDEN_ERAS.get(era_edif, 0) > Constantes.ORDEN_ERAS.get(era, 0): continue
		if d_edif.has("civ") and d_edif.civ != civ and d_edif.civ != main.civ_sincretismo: continue
		
		maravillas_candidatas.append(edif_nombre)
		
	for coord_optima in celdas_optimas_rendimiento.keys():
		for vec in HexMath.VECINOS_HEX:
			var n = coord_optima + vec
			
			if celdas_optimas_rendimiento.has(n): continue 
			
			var dist = HexMath.dist_hex(n, asent_centro)
			if dist < 1 or dist > 3: continue
			if not main.city_grid.has(n): continue
			
			var datos_n = main.city_grid[n]
			if datos_n.get("ajeno", false): continue
			if datos_n.edificios.size() > 0 or datos_n.mejora_tipo != "": continue
			if datos_n.get("caracteristica", "") == "NATURAL_WONDER" or datos_n.terreno == "NATURAL_WONDER": continue
			
			for mar_nombre in maravillas_candidatas:
				if es_ubicacion_valida_para_edificio(n, mar_nombre, asent_centro, era, civ, main.city_grid, asent_tipo, main.asentamientos):
					if not sugerencias.has(n): sugerencias[n] = []
					var existe = false
					for s in sugerencias[n]:
						if s.edificio == mar_nombre: existe = true
					if not existe:
						sugerencias[n].append({"edificio": mar_nombre})
						
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
