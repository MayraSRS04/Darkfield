extends CharacterBody2D

enum Estado { PATRULLA, PERSIGUE, REGRESA }

const UMBRAL_LLEGADA := 1.0

@onready var linea_de_vista: RayCast2D = $LineaDeVista

var jugador: Node2D = null
var mapa: Mapa = null
var estado: Estado = Estado.PATRULLA
var inicio: Vector2
var destino: Vector2
var moviendose := false
var ruta: Array = []
var ultima_direccion := Vector2.RIGHT

func _ready() -> void:
	inicio = global_position
	destino = global_position

func _physics_process(delta: float) -> void:
	if moviendose:
		global_position = global_position.move_toward(destino, GameManager.VELOCIDAD_CAZADOR * delta)
		if global_position.distance_to(destino) < UMBRAL_LLEGADA:
			global_position = destino
			moviendose = false
		velocity = Vector2.ZERO
		move_and_slide()
		queue_redraw()
		return
	match estado:
		Estado.PATRULLA:
			_patrullar()
		Estado.PERSIGUE:
			_perseguir()
		Estado.REGRESA:
			_regresar()
	velocity = Vector2.ZERO
	move_and_slide()
	queue_redraw()

func _patrullar() -> void:
	if _ve_al_jugador():
		estado = Estado.PERSIGUE
		ruta = []
		GameManager.reportar_deteccion(true)
		return
	if ruta.is_empty():
		_planear_ruta_aleatoria()
	_avanzar_ruta()

func _perseguir() -> void:
	if not _ve_al_jugador():
		estado = Estado.REGRESA
		ruta = []
		GameManager.reportar_deteccion(false)
		return
	ruta = _calcular_ruta(_celda_actual(), _celda_de(jugador.global_position))
	_avanzar_ruta()

func _regresar() -> void:
	if _ve_al_jugador():
		estado = Estado.PERSIGUE
		ruta = []
		GameManager.reportar_deteccion(true)
		return
	if _celda_actual() == _celda_de(inicio):
		estado = Estado.PATRULLA
		ruta = []
		return
	if ruta.is_empty():
		ruta = _calcular_ruta(_celda_actual(), _celda_de(inicio))
		if ruta.is_empty():
			estado = Estado.PATRULLA
			return
	_avanzar_ruta()

func _planear_ruta_aleatoria() -> void:
	if mapa == null:
		return
	var caminables := mapa.celdas_caminables()
	if caminables.is_empty():
		return
	for _intento in range(10):
		var meta: Vector2i = caminables[randi() % caminables.size()]
		var posible := _calcular_ruta(_celda_actual(), meta)
		if posible.size() > 1:
			ruta = posible
			return

func _avanzar_ruta() -> void:
	if ruta.is_empty():
		return
	var siguiente: Vector2i = ruta[0]
	ruta.remove_at(0)
	var tilemap: TileMapLayer = get_parent().get_node("Suelo")
	var pos_siguiente: Vector2 = tilemap.map_to_local(Vector2i(siguiente.y, siguiente.x))
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
		for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
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

func _ve_al_jugador() -> bool:
	if jugador == null:
		return false
	var alcance_px: float = GameManager.ALCANCE_VISION * 16.0
	if global_position.distance_to(jugador.global_position) > alcance_px:
		return false
	var angulo_a_jugador: float = (jugador.global_position - global_position).angle()
	var angulo_cazador: float = ultima_direccion.angle()
	var diferencia: float = abs(wrapf(angulo_a_jugador - angulo_cazador, -PI, PI))
	if diferencia > deg_to_rad(GameManager.ANGULO_CONO):
		return false
	linea_de_vista.target_position = linea_de_vista.to_local(jugador.global_position)
	linea_de_vista.force_raycast_update()
	return not linea_de_vista.is_colliding()

func _draw() -> void:
	var alcance_px: float = GameManager.ALCANCE_VISION * 16.0
	var angulo_base: float = ultima_direccion.angle()
	var medio_angulo: float = deg_to_rad(GameManager.ANGULO_CONO)
	var pasos := 16
	var puntos := PackedVector2Array()
	puntos.append(Vector2.ZERO)
	for i in range(pasos + 1):
		var t := float(i) / pasos
		var angulo := angulo_base - medio_angulo + t * medio_angulo * 2.0
		puntos.append(Vector2(cos(angulo), sin(angulo)) * alcance_px)
	puntos.append(Vector2.ZERO)
	var color_cono := Color(1.0, 0.85, 0.2, 0.18)
	if estado == Estado.PERSIGUE:
		color_cono = Color(1.0, 0.2, 0.2, 0.35)
	draw_polygon(puntos, PackedColorArray([color_cono]))
	draw_polyline(puntos, Color(1.0, 1.0, 1.0, 0.12), 0.8)
