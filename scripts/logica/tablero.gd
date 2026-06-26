class_name Tablero
extends RefCounted

var filas: int
var columnas: int
var celdas: Array = []
var bloqueadas: Dictionary = {}


func _init(f: int, c: int) -> void:
	filas = f
	columnas = c
	_crear_celdas_vacias()


func marcar_bloqueadas(celdas_muro: Array) -> void:
	bloqueadas = {}
	for c in celdas_muro:
		bloqueadas[c] = true

func _crear_celdas_vacias() -> void:
	celdas = []
	for fila in range(filas):
		var fila_celdas: Array = []
		for col in range(columnas):
			fila_celdas.append({
				"mina": false,
				"numero": 0,
				"revelada": false,
				"abanderada": false,
			})
		celdas.append(fila_celdas)


func _dentro(fila: int, col: int) -> bool:
	return fila >= 0 and fila < filas and col >= 0 and col < columnas


func _vecinas(fila: int, col: int) -> Array:
	var resultado: Array = []
	for df in range(-1, 2):
		for dc in range(-1, 2):
			if df == 0 and dc == 0:
				continue
			var nf := fila + df
			var nc := col + dc
			if _dentro(nf, nc):
				resultado.append(Vector2i(nf, nc))
	return resultado


func colocar_minas(cantidad: int, casilla_segura: Vector2i, caminables: Array) -> void:
	var prohibidas := {}
	if casilla_segura != Vector2i(-1, -1):
		prohibidas[casilla_segura] = true
		for v in _vecinas(casilla_segura.x, casilla_segura.y):
			prohibidas[v] = true

	var disponibles: Array = []
	for celda in caminables:
		if not prohibidas.has(celda):
			disponibles.append(celda)

	disponibles.shuffle()
	var a_colocar: int = min(cantidad, disponibles.size())
	for i in range(a_colocar):
		var p: Vector2i = disponibles[i]
		celdas[p.x][p.y]["mina"] = true

	_calcular_numeros()


func _calcular_numeros() -> void:
	for fila in range(filas):
		for col in range(columnas):
			if celdas[fila][col]["mina"]:
				continue
			if bloqueadas.has(Vector2i(fila, col)):
				continue
			var cuenta := 0
			for v in _vecinas(fila, col):
				if bloqueadas.has(v):
					continue
				if celdas[v.x][v.y]["mina"]:
					cuenta += 1
			celdas[fila][col]["numero"] = cuenta


func revelar(fila: int, col: int) -> void:
	var cola: Array[Vector2i] = [Vector2i(fila, col)]
	while not cola.is_empty():
		var actual: Vector2i = cola.pop_front()
		if not _dentro(actual.x, actual.y):
			continue
		if bloqueadas.has(actual):
			continue
		var celda = celdas[actual.x][actual.y]
		if celda["revelada"] or celda["abanderada"]:
			continue
		celda["revelada"] = true
		if celda["mina"]:
			continue
		if celda["numero"] == 0:
			for dir in [Vector2i(0,1), Vector2i(0,-1), Vector2i(1,0), Vector2i(-1,0)]:
				var vecino : Vector2i = actual + dir
				if not bloqueadas.has(vecino):
					cola.append(vecino)

func abanderar(fila: int, col: int) -> void:
	if not _dentro(fila, col):
		return
	if bloqueadas.has(Vector2i(fila, col)):
		return
	var celda = celdas[fila][col]
	if celda["revelada"]:
		return
	celda["abanderada"] = not celda["abanderada"]


func contar_minas() -> int:
	var total := 0
	for fila in range(filas):
		for col in range(columnas):
			if celdas[fila][col]["mina"]:
				total += 1
	return total


func minas_sin_abanderar() -> int:
	var faltan := 0
	for fila in range(filas):
		for col in range(columnas):
			var celda = celdas[fila][col]
			if celda["mina"] and not celda["abanderada"]:
				faltan += 1
	return faltan

func es_victoria() -> bool:
	for fila in range(filas):
		for col in range(columnas):
			if bloqueadas.has(Vector2i(fila, col)):
				continue
			var celda = celdas[fila][col]
			if not celda["mina"] and not celda["revelada"]:
				return false
	return true

func imprimir() -> void:
	for fila in range(filas):
		var linea := ""
		for col in range(columnas):
			var celda = celdas[fila][col]
			if celda["abanderada"]:
				linea += "P "
			elif not celda["revelada"]:
				linea += "? "
			elif celda["mina"]:
				linea += "* "
			elif celda["numero"] == 0:
				linea += ". "
			else:
				linea += str(celda["numero"]) + " "
		print(linea)
	print("")

func contar_banderas() -> int:
	var total := 0
	for fila in range(filas):
		for col in range(columnas):
			if celdas[fila][col]["abanderada"]:
				total += 1
	return total
