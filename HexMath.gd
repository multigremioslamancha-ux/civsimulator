extends Node

const VECINOS_HEX = [
	Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1), 
	Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1)
]

func dist_hex(coord1: Vector2i, coord2: Vector2i) -> int:
	var diff = coord1 - coord2
	return max(abs(diff.x), abs(diff.y), abs(-diff.x - diff.y))

func cubo_a_pixel(radio_hex: float, q: int, r: int, _s: int) -> Vector2:
	var x = radio_hex * (sqrt(3.0) * q + sqrt(3.0)/2.0 * r)
	var y = radio_hex * (3.0/2.0 * r)
	return Vector2(x, y)

func pixel_a_cubo(radio_hex: float, punto_pantalla: Vector2) -> Vector2i:
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

func obtener_puntos_hex(centro: Vector2, radio_hex: float, escala: float = 1.0) -> PackedVector2Array:
	var puntos = PackedVector2Array()
	for i in range(6):
		var angulo_deg = 60 * i - 30
		var angulo_rad = deg_to_rad(angulo_deg)
		puntos.push_back(centro + Vector2(radio_hex * escala * cos(angulo_rad), radio_hex * escala * sin(angulo_rad)))
	return puntos
