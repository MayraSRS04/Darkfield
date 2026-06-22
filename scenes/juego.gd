extends Node2D

@onready var suelo: TileMapLayer = $Suelo
@onready var paredes: TileMapLayer = $Paredes
@onready var overlay: Node2D = $Overlay

const FUENTE_SUELO := 0
const FUENTE_PARED := 1

var mapa: Mapa
var tablero: Tablero


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

	tablero = Tablero.new(mapa.filas, mapa.columnas)
	tablero.marcar_bloqueadas(mapa.celdas_pared())
	tablero.colocar_minas(8, Vector2i(1, 1), mapa.celdas_caminables())

	_pintar_mapa()

	tablero.revelar(1, 1)
	_forzar_revelar_fila(4)
	tablero.abanderar(7, 4)

	_dibujar_overlay()


func _pintar_mapa() -> void:
	for fila in range(mapa.filas):
		for col in range(mapa.columnas):
			var celda := Vector2i(col, fila)
			if mapa.es_pared(fila, col):
				paredes.set_cell(celda, FUENTE_PARED, Vector2i(0, 0))
			else:
				suelo.set_cell(celda, FUENTE_SUELO, Vector2i(0, 0))


func _forzar_revelar_fila(fila: int) -> void:
	for col in range(mapa.columnas):
		if mapa.es_caminable(fila, col):
			tablero.revelar(fila, col)


func _dibujar_overlay() -> void:
	for hijo in overlay.get_children():
		hijo.queue_free()

	for fila in range(tablero.filas):
		for col in range(tablero.columnas):
			var celda = tablero.celdas[fila][col]
			var texto := ""
			var color := Color.WHITE

			if celda["abanderada"]:
				texto = "P"
				color = Color(1.0, 0.4, 0.4)
			elif celda["revelada"]:
				if celda["mina"]:
					texto = "*"
					color = Color(1.0, 0.3, 0.3)
				elif celda["numero"] > 0:
					texto = str(celda["numero"])
					color = Color(0.6, 0.85, 1.0)

			if texto != "":
				_crear_etiqueta(fila, col, texto, color)


func _crear_etiqueta(fila: int, col: int, texto: String, color: Color) -> void:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_color_override("font_color", color)
	var pos := suelo.map_to_local(Vector2i(col, fila))
	etiqueta.position = pos - Vector2(4, 8)
	overlay.add_child(etiqueta)
