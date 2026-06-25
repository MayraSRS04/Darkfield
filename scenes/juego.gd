extends Node2D

@onready var suelo: TileMapLayer = $Suelo
@onready var paredes: TileMapLayer = $Paredes
@onready var reveladas: TileMapLayer = $Reveladas
@onready var overlay: Node2D = $Overlay
@onready var jugador: CharacterBody2D = $Jugador
@onready var pantalla_resultado: CanvasLayer = $PantallaResultado
@onready var lbl_titulo: Label = $PantallaResultado/Contenedor/LblTitulo
@onready var lbl_detalle: Label = $PantallaResultado/Contenedor/LblDetalle
@onready var btn_reintentar: Button = $PantallaResultado/Contenedor/BtnReintentar
@onready var btn_menu: Button = $PantallaResultado/Contenedor/BtnMenu

const FUENTE_SUELO := 0
const FUENTE_PARED := 1
const FUENTE_REVELADA := 2

var mapa: Mapa
var tablero: Tablero
var muerto := false
var causa_muerte := ""


func _ready() -> void:
	var cfg: Dictionary = GameManager.CONFIGURACIONES[GameManager.nivel_actual]
	var layout := _generar_layout(cfg["filas"], cfg["columnas"])
	mapa = Mapa.new()
	mapa.cargar(layout)

	tablero = Tablero.new(mapa.filas, mapa.columnas)
	tablero.marcar_bloqueadas(mapa.celdas_pared())
	tablero.colocar_minas(cfg["minas"], Vector2i(1, 1), mapa.celdas_caminables())
	
	_pintar_mapa()
	#print("hijos del jugador: ", jugador.get_children())
	jugador.get_node("Camera2D").configurar_limites(suelo)
	
	jugador.position = suelo.map_to_local(Vector2i(1, 1))
	jugador.solicito_revelar.connect(_on_solicito_revelar)
	jugador.solicito_abanderar.connect(_on_solicito_abanderar)
	
	var escena_cazador := preload("res://actors/Cazador.tscn")
	var celdas_usadas: Array = []
	for _i in range(cfg["cazadores"]):
		var cazador := escena_cazador.instantiate()
		cazador.add_to_group("cazadores")
		add_child(cazador)
		cazador.jugador = jugador
		cazador.mapa = mapa
		var caminables := mapa.celdas_caminables()
		caminables = caminables.filter(func(c): return not celdas_usadas.has(c))
		if not caminables.is_empty():
			var celda: Vector2i = caminables[randi() % caminables.size()]
			celdas_usadas.append(celda)
			cazador.global_position = suelo.map_to_local(Vector2i(celda.y, celda.x))
			cazador.inicio = cazador.global_position
			cazador.destino = cazador.global_position
	
	tablero.revelar(1, 1)
	#_forzar_revelar_fila(4)
	#tablero.abanderar(7, 4)

	_dibujar_overlay()
	GameManager.actualizar_minas_restantes(tablero.minas_sin_abanderar())
	
	btn_reintentar.pressed.connect(_on_reintentar)
	btn_menu.pressed.connect(_on_menu)

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
	reveladas.clear()

	for fila in range(tablero.filas):
		for col in range(tablero.columnas):
			var celda = tablero.celdas[fila][col]
			var es_pared := mapa.es_pared(fila, col)

			if celda["revelada"] and not es_pared:
				reveladas.set_cell(Vector2i(col, fila), FUENTE_REVELADA, Vector2i(0, 0))

			if not es_pared and not celda["revelada"]:
				_crear_niebla(fila, col)

			var texto := ""
			var color := Color.WHITE

			if celda["abanderada"]:
				texto = "🚩"
				color = Color(1.0, 0.3, 0.3)
			elif celda["revelada"]:
				if celda["mina"]:
					texto = "💣"
					color = Color(1.0, 0.2, 0.2)
				elif celda["numero"] > 0:
					texto = str(celda["numero"])
					color = _color_numero(celda["numero"])

			if texto != "":
				_crear_etiqueta(fila, col, texto, color)


func _color_numero(numero: int) -> Color:
	match numero:
		1: return Color(0.30, 0.55, 1.0)
		2: return Color(0.30, 0.80, 0.40)
		3: return Color(1.0, 0.40, 0.40)
		4: return Color(0.60, 0.40, 0.90)
		5: return Color(0.80, 0.45, 0.20)
		6: return Color(0.30, 0.80, 0.80)
		7: return Color(0.90, 0.90, 0.95)
		_: return Color(0.70, 0.70, 0.75)


func _crear_niebla(fila: int, col: int) -> void:
	var niebla := ColorRect.new()
	niebla.color = Color(0.05, 0.06, 0.10, 0.78)
	niebla.size = Vector2(16, 16)
	var pos := suelo.map_to_local(Vector2i(col, fila))
	niebla.position = pos - Vector2(8, 8)
	overlay.add_child(niebla)


func _crear_etiqueta(fila: int, col: int, texto: String, color: Color) -> void:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.add_theme_font_size_override("font_size", 14)
	etiqueta.size = Vector2(16, 16)
	etiqueta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var pos := suelo.map_to_local(Vector2i(col, fila))
	etiqueta.position = pos - etiqueta.size / 2

	overlay.add_child(etiqueta)


func _celda_del_jugador() -> Vector2i:
	var celda := suelo.local_to_map(jugador.position)
	return Vector2i(celda.y, celda.x)

func _on_solicito_revelar() -> void:
	if muerto:
		return
	var c := _celda_del_jugador()
	if tablero.celdas[c.x][c.y]["abanderada"]:
		return
	tablero.revelar(c.x, c.y)
	if tablero.celdas[c.x][c.y]["mina"]:
		causa_muerte = "pisaste una mina"
		_morir()
		return
	_dibujar_overlay()
	
	if tablero.es_victoria():
		_ganar()

func _morir() -> void:
	muerto = true
	GameManager.morir()
	_mostrar_resultado(false, causa_muerte)

func _on_solicito_abanderar() -> void:
	if muerto:
		return
	var c := _celda_del_jugador()
	tablero.abanderar(c.x, c.y)
	_dibujar_overlay()
	GameManager.actualizar_minas_restantes(tablero.minas_sin_abanderar())
	if tablero.es_victoria():
		_ganar()
		
func _process(_delta: float) -> void:
	if muerto:
		return
	for cazador in get_tree().get_nodes_in_group("cazadores"):
		if jugador.global_position.distance_to(cazador.global_position) < 12.0:
			causa_muerte = "atrapado por un cazador"
			_morir()
			break

func _ganar() -> void:
	muerto = true
	GameManager.nivel_ganado()
	_mostrar_resultado(true, "")

func _generar_layout(filas: int, columnas: int) -> Array:
	var layout: Array = []
	for fila in range(filas):
		var linea := ""
		for col in range(columnas):
			if fila == 0 or fila == filas - 1 or col == 0 or col == columnas - 1:
				linea += "#"
			elif fila % 2 == 0 and col % 2 == 0:
				linea += "#"
			else:
				linea += "."
		layout.append(linea)
	return layout

func _mostrar_resultado(victoria: bool, motivo: String) -> void:
	pantalla_resultado.visible = true
	if victoria:
		lbl_titulo.text = "VICTORIA"
		lbl_titulo.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5))
		lbl_detalle.text = "Todas las minas neutralizadas"
	else:
		lbl_titulo.text = "GAME OVER"
		lbl_titulo.add_theme_color_override("font_color", Color(0.9, 0.25, 0.25))
		lbl_detalle.text = motivo

func _on_reintentar() -> void:
	get_tree().change_scene_to_file("res://scenes/01_juego.tscn")

func _on_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/00_menu.tscn")
