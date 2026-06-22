extends Control


func _ready() -> void:
	print("--- prueba de mapa ---")

	var layout := [
		"##########",
		"#........#",
		"#.##..##.#",
		"#.#....#.#",
		"#....##..#",
		"#.#....#.#",
		"#.##..##.#",
		"#........#",
		"##########",
	]

	var m := Mapa.new()
	m.cargar(layout)

	print("dimensiones: ", m.filas, " x ", m.columnas)
	m.imprimir()

	print("caminables totales: ", m.celdas_caminables().size())
	print("paredes totales: ", m.celdas_pared().size())

	print("es_caminable(1,1) [zona]: ", m.es_caminable(1, 1))
	print("es_caminable(0,0) [borde]: ", m.es_caminable(0, 0))
	print("es_caminable(2,2) [muro interno]: ", m.es_caminable(2, 2))
	print("es_caminable(-1,5) [fuera]: ", m.es_caminable(-1, 5))

	print("--- fin de prueba ---")
