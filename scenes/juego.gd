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
@onready var lbl_minas: Label = $HUD/BarraSuperior/LblMinas
@onready var lbl_alerta: Label = $HUD/BarraSuperior/LblAlerta
@onready var btn_pausa: Button = $HUD/BarraSuperior/BtnPausa
@onready var pausa: CanvasLayer = $Pausa
@onready var btn_reanudar: Button = $Pausa/Contenedor/BtnReanudar
@onready var btn_menu_principal: Button = $Pausa/Contenedor/BtnMenuPrincipal
@onready var oscuridad: CanvasModulate = $Oscuridad
@onready var fade_fondo: ColorRect = $FadeEntrada/Fondo
@onready var items_layer: Node2D = $ItemsLayer
@onready var hud_inventario: CanvasLayer = $HUDInventario
@onready var lbl_item_activo: Label = $HUDInventario/Contenedor/LblItemActivo
@onready var lbl_inventario: Label = $HUDInventario/Contenedor/LblInventario
@onready var pantalla_resultado_historia: CanvasLayer = $PantallaResultadoHistoria
@onready var lbl_titulo_h: Label = $PantallaResultadoHistoria/Contenedor/LblTituloH
@onready var lbl_items_ganados: Label = $PantallaResultadoHistoria/Contenedor/LblItemsGanados
@onready var btn_continuar: Button = $PantallaResultadoHistoria/Contenedor/BtnContinuar
@onready var btn_menu_historia: Button = $PantallaResultadoHistoria/Contenedor/BtnMenuHistoria
@onready var hud_vida_boss: CanvasLayer = $HUDVidaBoss
@onready var barra_vida_boss: ColorRect = $HUDVidaBoss/Contenedor/BarraVida
@onready var lbl_boss: Label = $HUDVidaBoss/Contenedor/LblBoss

const FUENTE_SUELO := 0
const FUENTE_PARED := 1
const FUENTE_REVELADA := 2

var mapa: Mapa
var tablero: Tablero
var muerto := false
var causa_muerte := ""
var item_seleccionado: int = 0
var _timer_congelado := 0.0
var _timer_radar := 0.0
var _celdas_radar: Array = []
var boss: Node2D = null
var fase_boss_activa := false
var boss_derrotado := false
var escudo_activo := false
var balas_totales := 0
var _cooldown_disparo := 0.0

func _ready() -> void:
	var cfg: Dictionary = GameManager.CONFIGURACIONES[GameManager.nivel_actual]
	var layout := _generar_layout(cfg["filas"], cfg["columnas"])
	mapa = Mapa.new()
	mapa.cargar(layout)

	tablero = Tablero.new(mapa.filas, mapa.columnas)
	tablero.marcar_bloqueadas(mapa.celdas_pared())
	var spawn := _primera_celda_caminable()
	tablero.colocar_minas(cfg["minas"], spawn, mapa.celdas_caminables())
	
	_pintar_mapa()
	jugador.get_node("Camera2D").configurar_limites(suelo)
	
	var celda_spawn := _primera_celda_caminable()
	jugador.position = suelo.map_to_local(Vector2i(celda_spawn.y, celda_spawn.x))
	tablero.revelar(celda_spawn.x, celda_spawn.y)
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
		var disponibles := caminables.filter(func(c: Vector2i) -> bool:
			for usada in celdas_usadas:
				if abs(c.x - usada.x) + abs(c.y - usada.y) < 4:
					return false
			return true
		)
		if disponibles.is_empty():
			disponibles = caminables
		var celda: Vector2i = disponibles[randi() % disponibles.size()]
		celdas_usadas.append(celda)
		cazador.global_position = suelo.map_to_local(Vector2i(celda.y, celda.x))
		cazador.inicio = cazador.global_position
		cazador.destino = cazador.global_position

	_dibujar_overlay()
	GameManager.actualizar_minas_restantes(tablero.contar_minas())
	
	btn_reintentar.pressed.connect(_on_reintentar)
	btn_menu.pressed.connect(_on_menu)
	btn_pausa.pressed.connect(_on_pausa)
	btn_reanudar.pressed.connect(_on_reanudar)
	GameManager.estado_cambiado.connect(_on_estado_cambiado)
	btn_menu_principal.pressed.connect(_on_menu)
	GameManager.minas_restantes_cambiado.connect(_on_minas_cambiado)
	GameManager.jugador_detectado.connect(_on_alerta_cambiada)
	_iniciar_fade()
	jugador.solicito_usar_item.connect(_on_usar_item)
	jugador.solicito_ciclar_item.connect(_on_ciclar_item)
	btn_continuar.pressed.connect(_on_continuar_historia)
	btn_menu_historia.pressed.connect(_on_menu_historia)
	GameManager.inventario_cambiado.connect(_on_inventario_cambiado)
	hud_inventario.visible = GameManager.modo_historia
	if GameManager.modo_historia:
		_spawnear_items()
		_on_inventario_cambiado()
		hud_vida_boss.visible = false
		balas_totales = GameManager.cantidad_item(GameManager.TipoItem.PISTOLA) * GameManager.BALAS_POR_PISTOLA

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
	_congelar_actores()
	GameManager.morir()
	_mostrar_resultado(false, causa_muerte)

func _ganar() -> void:
	if GameManager.modo_historia and GameManager.nivel_actual == 2 and not fase_boss_activa and not boss_derrotado:
		_iniciar_fase_boss()
		return
	muerto = true
	_congelar_actores()
	GameManager.nivel_ganado()
	if GameManager.modo_historia:
		_mostrar_resultado_historia()
	else:
		_mostrar_resultado(true, "")

func _congelar_actores() -> void:
	jugador.set_physics_process(false)
	jugador.set_process_unhandled_input(false)
	for c in get_tree().get_nodes_in_group("cazadores"):
		c.set_physics_process(false)

func _on_solicito_abanderar() -> void:
	if muerto:
		return
	var c := _celda_del_jugador()
	tablero.abanderar(c.x, c.y)
	_dibujar_overlay()
	GameManager.actualizar_minas_restantes(tablero.contar_minas() - tablero.contar_banderas())
	if tablero.es_victoria():
		_ganar()
		
func _process(delta: float) -> void:
	if muerto:
		return
	if _timer_congelado > 0.0:
		_timer_congelado -= delta
		if _timer_congelado <= 0.0:
			_descongelar_cazadores()
	if _timer_radar > 0.0:
		_timer_radar -= delta
		if _timer_radar <= 0.0:
			_limpiar_radar()
	if GameManager.modo_historia:
		for item in items_layer.get_children():
			item.intentar_recoger(jugador.global_position)
		if _cooldown_disparo > 0.0:
			_cooldown_disparo -= delta
		if fase_boss_activa and Input.is_action_pressed("ui_accept"):
			_disparar()
	for cazador in get_tree().get_nodes_in_group("cazadores"):
		if cazador.estado == cazador.Estado.PERSIGUIENDO:
			if jugador.global_position.distance_to(cazador.global_position) < 12.0:
				causa_muerte = "atrapado por un cazador"
				_morir()

func _generar_layout(filas: int, columnas: int) -> Array:
	return GeneradorDungeon.generar(filas, columnas)

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
	GameManager.iniciar_nivel(GameManager.nivel_actual)
	_fade_salida("res://scenes/01_juego.tscn")

func _on_menu() -> void:
	_fade_salida("res://scenes/00_menu.tscn")

func _on_pausa() -> void:
	if muerto:
		return
	pausa.visible = true
	get_tree().paused = true
	GameManager.pausar()

func _on_reanudar()-> void:
	pausa.visible = false
	get_tree().paused = false
	GameManager.reanudar()

func _on_estado_cambiado(nuevo: GameManager.Estado) -> void:
	if nuevo == GameManager.Estado.JUGANDO:
		pausa.visible = false

func _on_minas_cambiado(cantidad: int) -> void:
	lbl_minas.text = "🚩 " + str(cantidad)

func _on_alerta_cambiada(detectado: bool) -> void:
	if detectado:
		lbl_alerta.text = "⚠ ALERTA"
		lbl_alerta.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		lbl_alerta.text = "● SEGURO"
		lbl_alerta.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5))
	
func _iniciar_fade() -> void:
	fade_fondo.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(fade_fondo, "modulate:a", 0.0, 0.8)
	tween.tween_callback(func(): fade_fondo.get_parent().visible = false)

func _fade_salida(destino: String) -> void:
	get_tree().paused = false
	fade_fondo.get_parent().visible = true
	fade_fondo.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(fade_fondo, "modulate:a", 1.0, 0.5)
	tween.tween_callback(func(): get_tree().change_scene_to_file(destino))

func _spawnear_items() -> void:
	var escena_item := load("res://scripts/logica/item_mapa.gd")
	var caminables := mapa.celdas_caminables()
	caminables.shuffle()
	var cantidad := mini(3, caminables.size())
	var tipos_nivel: Array = GameManager.ITEMS_POR_NIVEL[GameManager.nivel_actual] if GameManager.nivel_actual < GameManager.ITEMS_POR_NIVEL.size() else []
	for i in mini(tipos_nivel.size(), cantidad):
		var celda: Vector2i = caminables[i + 2]
		var item := Node2D.new()
		item.set_script(escena_item)
		item.tipo = tipos_nivel[i]
		items_layer.add_child(item)
		item.global_position = suelo.map_to_local(Vector2i(celda.y, celda.x))
		item.recogido.connect(_on_item_recogido)

func _on_item_recogido(tipo: GameManager.TipoItem) -> void:
	GameManager.agregar_item(tipo)

func _on_inventario_cambiado() -> void:
	if GameManager.inventario.is_empty():
		lbl_item_activo.text = ""
		lbl_inventario.text = "Sin items"
		return
	if item_seleccionado >= GameManager.inventario.size():
		item_seleccionado = 0
	var tipo_actual: GameManager.TipoItem = GameManager.inventario[item_seleccionado]
	var iconos := {
		GameManager.TipoItem.RADAR: "📡 Radar",
		GameManager.TipoItem.BOOST: "⚡ Boost",
		GameManager.TipoItem.CONGELADO: "❄️ Congelar",
		GameManager.TipoItem.ESCUDO: "🛡️ Escudo",
		GameManager.TipoItem.PISTOLA: "🔫 Pistola",
		GameManager.TipoItem.BAZUKA: "💥 Bazuka",
	}
	lbl_item_activo.text = "► " + iconos.get(tipo_actual, "?")
	var resto := GameManager.inventario.duplicate()
	resto.remove_at(item_seleccionado)
	var nombres: Array = []
	for t in resto:
		nombres.append(iconos.get(t, "?"))
	lbl_inventario.text = "  ".join(nombres)

func _on_ciclar_item() -> void:
	if muerto or GameManager.inventario.is_empty():
		return
	item_seleccionado = (item_seleccionado + 1) % GameManager.inventario.size()
	_on_inventario_cambiado()

func _on_usar_item() -> void:
	if muerto or GameManager.inventario.is_empty():
		return
	if item_seleccionado >= GameManager.inventario.size():
		item_seleccionado = 0
	var tipo: GameManager.TipoItem = GameManager.inventario[item_seleccionado]
	match tipo:
		GameManager.TipoItem.RADAR:
			if GameManager.consumir_item(tipo):
				_activar_radar()
		GameManager.TipoItem.BOOST:
			if GameManager.consumir_item(tipo):
				jugador.activar_boost()
		GameManager.TipoItem.CONGELADO:
			if GameManager.consumir_item(tipo):
				_activar_congelado()
		GameManager.TipoItem.ESCUDO:
			if GameManager.consumir_item(tipo):
				escudo_activo = true
		GameManager.TipoItem.PISTOLA:
			if fase_boss_activa:
				_disparar()
		GameManager.TipoItem.BAZUKA:
			if fase_boss_activa:
				item_seleccionado = GameManager.inventario.find(GameManager.TipoItem.BAZUKA)
				_disparar()

func _activar_radar() -> void:
	var celda_j := _celda_del_jugador()
	var radio: int = GameManager.RADIO_RADAR
	_limpiar_radar()
	for df in range(-radio, radio + 1):
		for dc in range(-radio, radio + 1):
			var f := celda_j.x + df
			var c := celda_j.y + dc
			if f < 0 or f >= tablero.filas or c < 0 or c >= tablero.columnas:
				continue
			if mapa.es_pared(f, c):
				continue
			if tablero.celdas[f][c]["mina"] and not tablero.celdas[f][c]["revelada"]:
				_celdas_radar.append(Vector2i(f, c))
				_crear_etiqueta(f, c, "💣", Color(1.0, 0.5, 0.1, 0.85))
	_timer_radar = GameManager.DURACION_RADAR

func _limpiar_radar() -> void:
	_celdas_radar.clear()
	_dibujar_overlay()

func _activar_congelado() -> void:
	_timer_congelado = GameManager.DURACION_CONGELADO_ITEM
	for c in get_tree().get_nodes_in_group("cazadores"):
		c.set_physics_process(false)

func _descongelar_cazadores() -> void:
	for c in get_tree().get_nodes_in_group("cazadores"):
		c.set_physics_process(true)

func _mostrar_resultado_historia() -> void:
	var items_ganados: Array = GameManager.ITEMS_POR_NIVEL[GameManager.nivel_actual] if GameManager.nivel_actual < GameManager.ITEMS_POR_NIVEL.size() else []
	var iconos := {
		GameManager.TipoItem.RADAR: "📡 Radar",
		GameManager.TipoItem.BOOST: "⚡ Boost",
		GameManager.TipoItem.CONGELADO: "❄️ Congelar",
		GameManager.TipoItem.ESCUDO: "🛡️ Escudo",
		GameManager.TipoItem.PISTOLA: "🔫 Pistola",
		GameManager.TipoItem.BAZUKA: "💥 Bazuka",
	}
	var nombres: Array = []
	for t in items_ganados:
		nombres.append(iconos.get(t, "?"))
	if nombres.is_empty():
		lbl_items_ganados.text = ""
	else:
		lbl_items_ganados.text = "Items ganados: " + ", ".join(nombres)
	var es_ultimo := GameManager.nivel_actual >= GameManager.CONFIGURACIONES.size() - 1
	btn_continuar.visible = not es_ultimo
	btn_continuar.text = "SIGUIENTE NIVEL"
	pantalla_resultado_historia.visible = true

func _on_continuar_historia() -> void:
	var siguiente := GameManager.nivel_actual + 1
	GameManager.iniciar_nivel_historia(siguiente)
	_fade_salida("res://scenes/01_juego.tscn")

func _on_menu_historia() -> void:
	GameManager.modo_historia = false
	_fade_salida("res://scenes/02_historia.tscn")

func _iniciar_fase_boss() -> void:
	for c in get_tree().get_nodes_in_group("cazadores"):
		c.queue_free()
	fase_boss_activa = true
	hud_vida_boss.visible = true
	var escena_boss := load("res://actors/Boss.tscn")
	boss = escena_boss.instantiate()
	add_child(boss)
	boss.jugador = jugador
	boss.mapa = mapa
	var caminables := mapa.celdas_caminables()
	caminables.shuffle()
	var celda: Vector2i = caminables[caminables.size() / 2]
	boss.global_position = suelo.map_to_local(Vector2i(celda.y, celda.x))
	boss.activar()
	lbl_boss.text = "GENERAL KARIMI"
	_actualizar_hud_boss()

func _actualizar_hud_boss() -> void:
	if boss == null:
		return
	var porcentaje := float(boss.vida) / float(boss.VIDA_MAXIMA)
	barra_vida_boss.size.x = 300.0 * porcentaje

func _disparar() -> void:
	if _cooldown_disparo > 0.0:
		return
	var tiene_pistola := GameManager.cantidad_item(GameManager.TipoItem.PISTOLA) > 0
	var tiene_bazuka := GameManager.cantidad_item(GameManager.TipoItem.BAZUKA) > 0
	if not tiene_pistola and not tiene_bazuka:
		return
	_cooldown_disparo = 0.4
	var es_bazuka :bool = GameManager.inventario[item_seleccionado] == GameManager.TipoItem.BAZUKA
	var danio := GameManager.DANIO_BAZUKA if es_bazuka else GameManager.DANIO_PISTOLA
	if es_bazuka:
		GameManager.consumir_item(GameManager.TipoItem.BAZUKA)
	else:
		GameManager.consumir_item(GameManager.TipoItem.PISTOLA)
	if boss != null and boss.global_position.distance_to(jugador.global_position) < 80.0:
		boss.recibir_danio(danio)
		_actualizar_hud_boss()
	for elite in get_tree().get_nodes_in_group("elite_boss"):
		if elite.global_position.distance_to(jugador.global_position) < 80.0:
			elite.queue_free()

func _on_boss_muerto() -> void:
	boss = null
	fase_boss_activa = false
	boss_derrotado = true
	hud_vida_boss.visible = false
	_ganar()

func _on_danio_jugador(motivo: String) -> void:
	if muerto:
		return
	if escudo_activo:
		escudo_activo = false
		_on_inventario_cambiado()
		return
	causa_muerte = motivo
	_morir()

func _on_impacto_granada(pos: Vector2) -> void:
	if muerto:
		return
	if jugador.global_position.distance_to(pos) < 24.0:
		_on_danio_jugador("alcanzado por una granada")

func _primera_celda_caminable() -> Vector2i:
	for f in range(1, mapa.filas - 1):
		for c in range(1, mapa.columnas - 1):
			if mapa.es_caminable(f, c):
				return Vector2i(f, c)
	return Vector2i(1, 1)
