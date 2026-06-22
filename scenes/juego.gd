extends Node2D

@onready var suelo: TileMapLayer = $Suelo
@onready var paredes: TileMapLayer = $Paredes

const FUENTE_SUELO := 0
const FUENTE_PARED := 1

var mapa: Mapa


func _ready() -> void:
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
	mapa = Mapa.new()
	mapa.cargar(layout)
	_pintar_mapa()


func _pintar_mapa() -> void:
	for fila in range(mapa.filas):
		for col in range(mapa.columnas):
			var celda := Vector2i(col, fila)
			if mapa.es_pared(fila, col):
				paredes.set_cell(celda, FUENTE_PARED, Vector2i(0, 0))
			else:
				suelo.set_cell(celda, FUENTE_SUELO, Vector2i(0, 0))
