extends CharacterBody2D

enum Estado { ESPERA, ACTIVO, FASE2 }

const UMBRAL_LLEGADA := 1.0
const VIDA_MAXIMA := 100
const VELOCIDAD_FASE1 := 55.0
const VELOCIDAD_FASE2 := 85.0
const TIEMPO_GRANADA_FASE1 := 8.0
const TIEMPO_GRANADA_FASE2 := 5.0
const TIEMPO_INVOCAR_FASE1 := 20.0
const TIEMPO_INVOCAR_FASE2 := 13.0
const MAX_ELITES_ACTIVOS := 2

@onready var linea_de_vista: RayCast2D = $LineaDeVista
@onready var relleno_barra: ColorRect = $BarraVida/RellenoBarra
@onready var area_contacto: Area2D = $AreaContacto

var jugador: Node2D = null
var mapa: Mapa = null
var estado: Estado = Estado.ESPERA
var vida: int = VIDA_MAXIMA
var inicio: Vector2
var destino: Vector2
var moviendose := false
var ruta: Array = []
var ultima_direccion := Vector2.RIGHT
var _timer_granada := TIEMPO_GRANADA_FASE1
var _timer_invocar := TIEMPO_INVOCAR_FASE1
var _escena_proyectil: PackedScene = null
var _escena_cazador: PackedScene = null

func _ready() -> void:
	inicio = global_position
	destino = global_position
	_escena_proyectil = load("res://actors/Proyectil.tscn")
	_escena_cazador = load("res://actors/Cazador.tscn")
	area_contacto.body_entered.connect(_on_contacto)
	add_to_group("boss")

func activar() -> void:
	estado = Estado.ACTIVO

func recibir_danio(cantidad: int) -> void:
	vida = maxi(0, vida - cantidad)
	_actualizar_barra()
	if vida <= 0:
		_morir()
		return
	if vida <= VIDA_MAXIMA / 2 and estado == Estado.ACTIVO:
		estado = Estado.FASE2
		_timer_granada = TIEMPO_GRANADA_FASE2
		_timer_invocar = TIEMPO_INVOCAR_FASE2
		$Sprite2D.modulate = Color(1.0, 0.05, 0.05, 1.0)

func _actualizar_barra() -> void:
	var porcentaje := float(vida) / float(VIDA_MAXIMA)
	relleno_barra.size.x = 24.0 * porcentaje

func _physics_process(delta: float) -> void:
	if estado == Estado.ESPERA:
		return
	_actualizar_timers(delta)
	if moviendose:
		var vel := VELOCIDAD_FASE2 if estado == Estado.FASE2 else VELOCIDAD_FASE1
		global_position = global_position.move_toward(destino, vel * delta)
		if global_position.distance_to(destino) < UMBRAL_LLEGADA:
			global_position = destino
			moviendose = false
	if not moviendose and not ruta.is_empty():
		_avanzar_ruta()
	velocity = Vector2.ZERO
	move_and_slide()
	$Sprite2D.rotation = ultima_direccion.angle()
	queue_redraw()

func _actualizar_timers(delta: float) -> void:
	_timer_granada -= delta
	if _timer_granada <= 0.0:
		var t := TIEMPO_GRANADA_FASE2 if estado == Estado.FASE2 else TIEMPO_GRANADA_FASE1
		_timer_granada = t
		_lanzar_granada()
	_timer_invocar -= delta
	if _timer_invocar <= 0.0:
		var t := TIEMPO_INVOCAR_FASE2 if estado == Estado.FASE2 else TIEMPO_INVOCAR_FASE1
		_timer_invocar = t
		_invocar_elite()
	if jugador != null and not moviendose and ruta.is_empty():
		ruta = _calcular_ruta(_celda_actual(), _celda_de(jugador.global_position))

func _lanzar_granada() -> void:
	if jugador == null or _escena_proyectil == null:
		return
	var proyectil = _escena_proyectil.instantiate()
	get_parent().add_child(proyectil)
	proyectil.global_position = global_position
	proyectil.objetivo = jugador.global_position

func _invocar_elite() -> void:
	if _escena_cazador == null:
		return
	var elites_activos := get_tree().get_nodes_in_group("elite_boss")
	if elites_activos.size() >= MAX_ELITES_ACTIVOS:
		return
	var caminables := mapa.celdas_caminables()
	if caminables.is_empty():
		return
	caminables.shuffle()
	var tilemap: TileMapLayer = get_parent().get_node("Suelo")
	var elite = _escena_cazador.instantiate()
	elite.add_to_group("cazadores")
	elite.add_to_group("elite_boss")
	get_parent().add_child(elite)
	elite.jugador = jugador
	elite.mapa = mapa
	var celda: Vector2i = caminables[0]
	elite.global_position = tilemap.map_to_local(Vector2i(celda.y, celda.x))
	elite.inicio = elite.global_position
	elite.destino = elite.global_position
	elite.get_node("Sprite2D").modulate = Color(1.0, 0.6, 0.1, 1.0)

func _morir() -> void:
	for elite in get_tree().get_nodes_in_group("elite_boss"):
		elite.queue_free()
	queue_free()
	get_parent()._on_boss_muerto()

func _avanzar_ruta() -> void:
	if ruta.is_empty():
		return
	var siguiente: Vector2i = ruta[0]
	var tilemap: TileMapLayer = get_parent().get_node("Suelo")
	var pos_siguiente: Vector2 = tilemap.map_to_local(Vector2i(siguiente.y, siguiente.x))
	ruta.remove_at(0)
	var dir := global_position.direction_to(pos_siguiente)
	if dir.length() > 0.01:
		ultima_direccion = dir
	destino = pos_siguiente
	moviendose = true

func _celda_actual() -> Vector2i:
	var tilemap: TileMapLayer = get_parent().get_node("Suelo")
	var c: Vector2i = tilemap.local_to_map(global_position)
	return Vector2i(c.y, c.x)

func _celda_de(pos: Vector2) -> Vector2i:
	var tilemap: TileMapLayer = get_parent().get_node("Suelo")
	var c: Vector2i = tilemap.local_to_map(pos)
	return Vector2i(c.y, c.x)

func _calcular_ruta(desde: Vector2i, hasta: Vector2i) -> Array:
	if mapa == null:
		return []
	if not mapa.es_caminable(desde.x, desde.y):
		return []
	if not mapa.es_caminable(hasta.x, hasta.y):
		return []
	var cola: Array = [desde]
	var vino_de: Dictionary = {desde: desde}
	while not cola.is_empty():
		var actual: Vector2i = cola.pop_front()
		if actual == hasta:
			break
		for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var vecino: Vector2i = actual + dir
			if vino_de.has(vecino):
				continue
			if not mapa.es_caminable(vecino.x, vecino.y):
				continue
			vino_de[vecino] = actual
			cola.append(vecino)
	if not vino_de.has(hasta):
		return []
	var camino: Array = []
	var paso: Vector2i = hasta
	while paso != desde:
		camino.push_front(paso)
		paso = vino_de[paso]
	return camino

func _on_contacto(cuerpo: Node2D) -> void:
	if cuerpo != jugador:
		return
	get_parent()._on_danio_jugador("aplastado por el General Karimi")

func _draw() -> void:
	if estado == Estado.ESPERA:
		return
	var color := Color(1.0, 0.1, 0.1, 0.35) if estado == Estado.FASE2 else Color(1.0, 0.4, 0.1, 0.25)
	draw_circle(Vector2.ZERO, 40.0, color)
