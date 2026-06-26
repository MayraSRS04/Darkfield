class_name GeneradorDungeon
extends RefCounted

static func generar(filas: int, columnas: int, semilla: int = -1) -> Array:
	if semilla >= 0:
		seed(semilla)
	var grid := _inicializar(filas, columnas)
	grid = _garantizar_zona_segura(grid, Vector2i(1, 1), 3)
	grid = _suavizar(grid, filas, columnas, 4)
	grid = _garantizar_borde(grid, filas, columnas)
	grid = _conectar(grid, filas, columnas, Vector2i(1, 1))
	return _a_layout(grid, filas, columnas)

static func _inicializar(filas: int, columnas: int) -> Array:
	var grid := []
	for f in range(filas):
		var fila := []
		for c in range(columnas):
			if f == 0 or f == filas - 1 or c == 0 or c == columnas - 1:
				fila.append(1)
			else:
				fila.append(1 if randf() < 0.42 else 0)
		grid.append(fila)
	return grid

static func _suavizar(grid: Array, filas: int, columnas: int, pasos: int) -> Array:
	for _p in range(pasos):
		var nuevo := []
		for f in range(filas):
			var fila := []
			for c in range(columnas):
				if f == 0 or f == filas - 1 or c == 0 or c == columnas - 1:
					fila.append(1)
					continue
				var vecinas_pared := _contar_paredes(grid, filas, columnas, f, c)
				if vecinas_pared > 4:
					fila.append(1)
				elif vecinas_pared < 4:
					fila.append(0)
				else:
					fila.append(grid[f][c])
			nuevo.append(fila)
		grid = nuevo
	return grid

static func _contar_paredes(grid: Array, filas: int, columnas: int, f: int, c: int) -> int:
	var cuenta := 0
	for df in range(-1, 2):
		for dc in range(-1, 2):
			if df == 0 and dc == 0:
				continue
			var nf := f + df
			var nc := c + dc
			if nf < 0 or nf >= filas or nc < 0 or nc >= columnas:
				cuenta += 1
			else:
				cuenta += grid[nf][nc]
	return cuenta

static func _garantizar_borde(grid: Array, filas: int, columnas: int) -> Array:
	for f in range(filas):
		grid[f][0] = 1
		grid[f][columnas - 1] = 1
	for c in range(columnas):
		grid[0][c] = 1
		grid[filas - 1][c] = 1
	return grid

static func _flood_fill(grid: Array, filas: int, columnas: int, inicio: Vector2i) -> Dictionary:
	var visitado := {}
	var cola: Array[Vector2i] = [inicio]
	visitado[inicio] = true
	while not cola.is_empty():
		var actual: Vector2i = cola.pop_front()
		for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var vecino: Vector2i = actual + dir
			if vecino.x < 0 or vecino.x >= filas or vecino.y < 0 or vecino.y >= columnas:
				continue
			if visitado.has(vecino):
				continue
			if grid[vecino.x][vecino.y] == 1:
				continue
			visitado[vecino] = true
			cola.append(vecino)
	return visitado

static func _conectar(grid: Array, filas: int, columnas: int, inicio: Vector2i) -> Array:
	if grid[inicio.x][inicio.y] == 1:
		grid[inicio.x][inicio.y] = 0
	var alcanzables := _flood_fill(grid, filas, columnas, inicio)
	for f in range(1, filas - 1):
		for c in range(1, columnas - 1):
			if grid[f][c] == 0 and not alcanzables.has(Vector2i(f, c)):
				grid[f][c] = 1
	return grid

static func _garantizar_zona_segura(grid: Array, centro: Vector2i, radio: int) -> Array:
	for df in range(-radio, radio + 1):
		for dc in range(-radio, radio + 1):
			var f := centro.x + df
			var c := centro.y + dc
			if f > 0 and c > 0 and f < grid.size() - 1 and c < grid[0].size() - 1:
				grid[f][c] = 0
	return grid

static func _a_layout(grid: Array, filas: int, columnas: int) -> Array:
	var layout := []
	for f in range(filas):
		var linea := ""
		for c in range(columnas):
			linea += "#" if grid[f][c] == 1 else "."
		layout.append(linea)
	return layout
