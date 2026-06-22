class_name Mapa
extends RefCounted

var filas: int
var columnas: int
var paredes: Dictionary = {}


func cargar(layout: Array) -> void:
	paredes = {}
	filas = layout.size()
	columnas = 0
	for fila in range(filas):
		var texto: String = layout[fila]
		columnas = max(columnas, texto.length())
		for col in range(texto.length()):
			if texto[col] == "#":
				paredes[Vector2i(fila, col)] = true


func es_pared(fila: int, col: int) -> bool:
	return paredes.has(Vector2i(fila, col))


func es_caminable(fila: int, col: int) -> bool:
	if fila < 0 or fila >= filas or col < 0 or col >= columnas:
		return false
	return not paredes.has(Vector2i(fila, col))

func dentro(fila: int, col: int) -> bool:
	return fila >= 0 and fila < filas and col >= 0 and col < columnas

func celdas_caminables() -> Array:
	var resultado: Array = []
	for fila in range(filas):
		for col in range(columnas):
			if es_caminable(fila, col):
				resultado.append(Vector2i(fila, col))
	return resultado


func celdas_pared() -> Array:
	return paredes.keys()


func imprimir() -> void:
	for fila in range(filas):
		var linea := ""
		for col in range(columnas):
			if es_pared(fila, col):
				linea += "# "
			else:
				linea += ". "
		print(linea)
	print("")
