extends Control


func _ready() -> void:
	print("--- prueba de tablero ---")

	var t := Tablero.new(6, 6)

	var caminables: Array = []
	for fila in range(6):
		for col in range(6):
			caminables.append(Vector2i(fila, col))

	var segura := Vector2i(0, 0)
	t.colocar_minas(5, segura, caminables)

	print("minas totales: ", t.contar_minas())
	print("tablero resuelto (todo revelado):")
	_revelar_todo(t)
	t.imprimir()

	print("desde casilla segura ", segura, " con cascada:")
	var t2 := Tablero.new(6, 6)
	t2.colocar_minas(5, segura, caminables)
	t2.revelar(segura.x, segura.y)
	t2.imprimir()

	print("minas sin abanderar antes: ", t2.minas_sin_abanderar())
	print("es victoria antes: ", t2.es_victoria())
	_abanderar_todas_las_minas(t2)
	print("minas sin abanderar despues: ", t2.minas_sin_abanderar())
	print("es victoria despues: ", t2.es_victoria())

	print("--- fin de prueba ---")


func _revelar_todo(t: Tablero) -> void:
	for fila in range(t.filas):
		for col in range(t.columnas):
			t.celdas[fila][col]["revelada"] = true


func _abanderar_todas_las_minas(t: Tablero) -> void:
	for fila in range(t.filas):
		for col in range(t.columnas):
			if t.celdas[fila][col]["mina"]:
				t.abanderar(fila, col)
