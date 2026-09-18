extends Node
class_name GestorGuardado

func guardar_partida(nombre: String, era: String, civ: String, asentamientos: Array, partidas_guardadas: Dictionary):
	var datos_serializados = []
	for asent in asentamientos:
		var grid_serializado = {}
		for coord in asent.grid.keys():
			var c = asent.grid[coord]
			grid_serializado[str(coord.x) + "," + str(coord.y)] = {
				"bioma": c.bioma,
				"terreno": c.terreno,
				"caracteristica": c.get("caracteristica", "NONE"),
				"rio": c.rio,
				"edificios": c.edificios,
				"edificios_dorados": c.get("edificios_dorados", []),
				"mejora_tipo": c.mejora_tipo,
				"recurso": c.recurso,
				"favorita": c.get("favorita", 0),
				"ajeno": c.get("ajeno", false)
			}
		datos_serializados.append({
			"nombre": asent.nombre,
			"tipo": asent.tipo,
			"centro": [asent.centro.x, asent.centro.y],
			"grid": grid_serializado
		})
	
	partidas_guardadas[nombre] = {
		"era_actual": era,
		"civ_actual": civ,
		"asentamientos": datos_serializados
	}
	
	var archivo = FileAccess.open("user://saves_civ7.json", FileAccess.WRITE)
	if archivo:
		archivo.store_string(JSON.stringify(partidas_guardadas))

func cargar_datos_sistema() -> Dictionary:
	if not FileAccess.file_exists("user://saves_civ7.json"): return {}
	var archivo = FileAccess.open("user://saves_civ7.json", FileAccess.READ)
	if not archivo: return {}
	
	var json = JSON.new()
	if json.parse(archivo.get_as_text()) != OK: return {}
	
	var json_data = json.get_data()
	if not json_data is Dictionary: return {}
	return json_data
