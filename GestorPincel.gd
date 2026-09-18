extends Node
class_name GestorPincel

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
	if celda_tiene_desarrollo(datos): return
	
	datos.bioma = bioma
	datos.terreno = terreno
	
	if terreno != "FLAT" and datos.caracteristica in ["WET", "VEGETATED", "FLOODPLAIN"]:
		datos.caracteristica = "NONE"
		
	if terreno in ["MOUNTAINOUS", "NAVIGABLE_RIVER", "OCEAN"]:
		datos.recurso = ""
		
	validar_y_refrescar_pincel(main)

static func aplicar_caracteristica(main: Node2D, c: String):
	if not main.city_grid.has(main.celda_seleccionada): return
	var datos = main.city_grid[main.celda_seleccionada]
	if celda_tiene_desarrollo(datos): return
	
	if c in ["WET", "VEGETATED", "FLOODPLAIN"] and datos.terreno != "FLAT":
		return
	datos.caracteristica = c
	validar_y_refrescar_pincel(main)

static func validar_y_refrescar_pincel(main: Node2D):
	var datos = main.city_grid[main.celda_seleccionada]
	
	var nom_rec = datos.get("recurso", "")
	if nom_rec != "" and Constantes.RECURSOS_POR_ERA.has(main.era_actual):
		var b_actual = datos.bioma
		var t_actual = datos.terreno
		var rec_data = Constantes.RECURSOS_POR_ERA[main.era_actual].get(nom_rec, [])
		var bioma_valido = ("TODOS" in rec_data) or (b_actual in rec_data) or ("AGUAS" in rec_data and t_actual in ["LAKE", "COASTAL", "OCEAN"])
		if not bioma_valido or t_actual in ["MOUNTAINOUS", "OCEAN", "NAVIGABLE_RIVER"] or datos.caracteristica in ["NATURAL_WONDER", "ICE"]:
			datos.recurso = ""

	main.actualizar_panel_pincel()
	main.actualizar_botones_recursos_ui()
	main.actualizar_sugerencias_cache()
	main.actualizar_iconos_todos()
	main.actualizar_panel_ui()
	main.guardar_partida_actual()
	main.queue_redraw()

static func marcar_favorita(main: Node2D, val: int):
	if main.seccion_actual != "PINCEL": return
	if not main.city_grid.has(main.celda_seleccionada): return
	var datos = main.city_grid[main.celda_seleccionada]
	if celda_tiene_desarrollo(datos): return
	
	datos.favorita = val
	main.actualizar_iconos_todos()
	main.actualizar_panel_pincel()
	main.actualizar_panel_ui()
	main.guardar_partida_actual()
	main.queue_redraw()

static func aplicar_recurso(main: Node2D, recurso_nombre: String):
	if not main.city_grid.has(main.celda_seleccionada): return
	var datos = main.city_grid[main.celda_seleccionada]
	if celda_tiene_desarrollo(datos): return
	
	if datos.edificios.has("Palace") or datos.edificios.has("Town Hall") or datos.ajeno: return
	
	# Restricción estricta de terreno para recursos
	if datos.terreno in ["MOUNTAINOUS", "OCEAN", "NAVIGABLE_RIVER"] or datos.caracteristica in ["NATURAL_WONDER", "ICE"]:
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
	if celda_tiene_desarrollo(datos): return
	
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
	main.actualizar_icono_celda(main.celda_seleccionada)
	main.actualizar_panel_ui()
	main.guardar_partida_actual()
	main.queue_redraw()

static func toggle_rio_celda(main: Node2D):
	if not main.city_grid.has(main.celda_seleccionada): return
	var datos = main.city_grid[main.celda_seleccionada]
	if celda_tiene_desarrollo(datos): return
	
	datos.rio = not datos.rio
	main.actualizar_panel_pincel()
	main.actualizar_sugerencias_cache()
	main.actualizar_iconos_todos()
	main.actualizar_panel_ui()
	main.guardar_partida_actual()
	main.queue_redraw()
