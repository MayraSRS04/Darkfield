extends CharacterBody2D

enum Estado { NORMAL, SOSPECHANDO, PERSIGUIENDO, INVESTIGANDO, REGRESA }

const UMBRAL_LLEGADA := 1.0

@onready var linea_de_vista: RayCast2D = $LineaDeVista

var jugador: Node2D = null
var mapa: Mapa = null
var estado: Estado = Estado.NORMAL
var inicio: Vector2
var destino: Vector2
var moviendose := false
var ruta: Array = []
var ultima_direccion := Vector2.RIGHT
var ultima_pos_vista: Vector2
var timer_sospecha := 0.0
var timer_perdida := 0.0

func _ready() -> void:
	inicio = global_position
	destino = global_position
	ultima_pos_vista = global_position
	_configurar_linterna()

func _physics_process(delta: float) -> void:
	if _ve_al_jugador():
		ultima_pos_vista = jugador.global_position

	_actualizar_estado(delta)

	if moviendose:
		global_position = global_position.move_toward(destino, _velocidad_actual() * delta)
		if global_position.distance_to(destino) < UMBRAL_LLEGADA:
			global_position = destino
			moviendose = false
	velocity = Vector2.ZERO
	move_and_slide()
	$Linterna.rotation = ultima_direccion.angle()
	$Linterna.position = ultima_direccion * 4.0
	queue_redraw()

func _actualizar_estado(delta: float) -> void:
	match estado:
		Estado.NORMAL:
			_patrullar()
		Estado.SOSPECHANDO:
			_sospechar(delta)
		Estado.PERSIGUIENDO:
			_perseguir(delta)
		Estado.INVESTIGANDO:
			_investigar()
		Estado.REGRESA:
			_regresar()

func _velocidad_actual() -> float:
	match estado:
		Estado.PERSIGUIENDO:
			return GameManager.VELOCIDAD_CAZADOR * 1.0
		Estado.SOSPECHANDO:
			return GameManager.VELOCIDAD_CAZADOR * 0.6
		Estado.INVESTIGANDO:
			return GameManager.VELOCIDAD_CAZADOR * 0.8
		Estado.REGRESA:
			return GameManager.VELOCIDAD_CAZADOR * 0.6
		_:
			return GameManager.VELOCIDAD_CAZADOR * 0.4

func _alcance_actual() -> float:
	match estado:
		Estado.SOSPECHANDO:
			return GameManager.ALCANCE_VISION * 16.0 * 1.0
		Estado.PERSIGUIENDO, Estado.INVESTIGANDO:
			return GameManager.ALCANCE_VISION * 16.0 * 1.2
		_:
			return GameManager.ALCANCE_VISION * 16.0

func _angulo_actual() -> float:
	match estado:
		Estado.SOSPECHANDO:
			return GameManager.ANGULO_CONO * 1.5
		Estado.PERSIGUIENDO, Estado.INVESTIGANDO:
			return GameManager.ANGULO_CONO * 2.2
		_:
			return GameManager.ANGULO_CONO

func _patrullar() -> void:
	if _ve_al_jugador():
		estado = Estado.SOSPECHANDO
		timer_sospecha = 0.0
		ruta = []
		moviendose = false
		return
	if not moviendose:
		if ruta.is_empty():
			_planear_ruta_aleatoria()
		_avanzar_ruta()

func _sospechar(delta: float) -> void:
	if _ve_al_jugador():
		timer_sospecha += delta
		if timer_sospecha >= GameManager.TIEMPO_ESPERA_PATRULLA:
			estado = Estado.PERSIGUIENDO
			timer_perdida = 0.0
			ruta = []
			moviendose = false
			GameManager.reportar_deteccion(true)
			return
		if not moviendose:
			var ruta_hacia := _calcular_ruta(_celda_actual(), _celda_de(ultima_pos_vista))
			if not ruta_hacia.is_empty():
				ruta = ruta_hacia
				_avanzar_ruta()
	else:
		timer_sospecha -= delta * 2.5
		if timer_sospecha <= 0.0:
			timer_sospecha = 0.0
			estado = Estado.NORMAL
			ruta = []
			moviendose = false

func _perseguir(delta: float) -> void:
	if _ve_al_jugador():
		timer_perdida = 0.0
		if not moviendose:
			ruta = _calcular_ruta(_celda_actual(), _celda_de(jugador.global_position))
			_avanzar_ruta()
	else:
		timer_perdida += delta
		if timer_perdida >= 4.0:
			estado = Estado.INVESTIGANDO
			ruta = _calcular_ruta(_celda_actual(), _celda_de(ultima_pos_vista))
			moviendose = false
			GameManager.reportar_deteccion(false)
		else:
			if not moviendose:
				ruta = _calcular_ruta(_celda_actual(), _celda_de(ultima_pos_vista))
				_avanzar_ruta()

	if not moviendose:
		if ruta.is_empty() or _celda_actual() == _celda_de(ultima_pos_vista):
			estado = Estado.REGRESA
			ruta = []
			return
		_avanzar_ruta()

func _investigar() -> void:
	if _ve_al_jugador():
		estado = Estado.PERSIGUIENDO
		timer_perdida = 0.0
		ruta = []
		moviendose = false
		GameManager.reportar_deteccion(true)
		return
	if not moviendose:
		if ruta.is_empty() or _celda_actual() == _celda_de(ultima_pos_vista):
			estado = Estado.REGRESA
			ruta = []
			return
		_avanzar_ruta()

func _regresar() -> void:
	if _ve_al_jugador():
		estado = Estado.SOSPECHANDO
		timer_sospecha = 0.0
		ruta = []
		moviendose = false
		return
	if not moviendose:
		if _celda_actual() == _celda_de(inicio):
			estado = Estado.NORMAL
			ruta = []
			return
		if ruta.is_empty():
			ruta = _calcular_ruta(_celda_actual(), _celda_de(inicio))
			if ruta.is_empty():
				estado = Estado.NORMAL
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
	var tilemap: TileMapLayer = get_parent().get_node("Suelo")
	var pos_siguiente: Vector2 = tilemap.map_to_local(Vector2i(siguiente.y, siguiente.x))
	for otro in get_tree().get_nodes_in_group("cazadores"):
		if otro == self:
			continue
		if otro.global_position.distance_to(pos_siguiente) < 14.0:
			return
	ruta.remove_at(0)
	var dir := global_position.direction_to(pos_siguiente)
	if dir.length() > 0.01:
		ultima_direccion = dir
	$Sprite2D.rotation = ultima_direccion.angle()
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
	if global_position.distance_to(jugador.global_position) > _alcance_actual():
		return false
	var angulo_a_jugador: float = (jugador.global_position - global_position).angle()
	var angulo_cazador: float = ultima_direccion.angle()
	var diferencia: float = abs(wrapf(angulo_a_jugador - angulo_cazador, -PI, PI))
	if diferencia > deg_to_rad(_angulo_actual()):
		return false
	linea_de_vista.target_position = linea_de_vista.to_local(jugador.global_position)
	linea_de_vista.force_raycast_update()
	return not linea_de_vista.is_colliding()

func _color_estado() -> Color:
	match estado:
		Estado.SOSPECHANDO:
			return Color(1.0, 0.65, 0.0, 1.0)
		Estado.PERSIGUIENDO:
			return Color(1.0, 0.15, 0.15, 1.0)
		Estado.INVESTIGANDO:
			return Color(1.0, 0.45, 0.0, 1.0)
		_:
			return Color(0.2, 0.9, 0.3, 1.0)

func _color_cono() -> Color:
	match estado:
		Estado.SOSPECHANDO:
			return Color(1.0, 0.65, 0.0, 0.22)
		Estado.PERSIGUIENDO:
			return Color(1.0, 0.15, 0.15, 0.35)
		Estado.INVESTIGANDO:
			return Color(1.0, 0.45, 0.0, 0.28)
		_:
			return Color(0.2, 0.9, 0.3, 0.15)

func _draw() -> void:
	var alcance_px: float = _alcance_actual()
	var angulo_base: float = ultima_direccion.angle()
	var medio_angulo: float = deg_to_rad(_angulo_actual())
	var pasos := 16
	var puntos := PackedVector2Array()
	puntos.append(Vector2.ZERO)
	for i in range(pasos + 1):
		var t := float(i) / pasos
		var angulo := angulo_base - medio_angulo + t * medio_angulo * 2.0
		puntos.append(Vector2(cos(angulo), sin(angulo)) * alcance_px)
	puntos.append(Vector2.ZERO)
	draw_polygon(puntos, PackedColorArray([_color_cono()]))
	var color_luz := Color(0.75, 0.88, 1.0, 0.08)
	draw_polygon(puntos, PackedColorArray([color_luz]))
	draw_polyline(puntos, Color(1.0, 1.0, 1.0, 0.10), 0.8)
	if estado == Estado.SOSPECHANDO:
		var progreso: float = minf(timer_sospecha / GameManager.TIEMPO_ESPERA_PATRULLA, 1.0)
		draw_arc(Vector2.ZERO, 8.0, -PI / 2.0, -PI / 2.0 + progreso * TAU, 20, Color(1.0, 1.0, 0.2, 0.95), 2.0)


func _configurar_linterna() -> void:
	var tam := 128
	var imagen := Image.create(tam, tam, false, Image.FORMAT_RGBA8)
	var medio_angulo := deg_to_rad(GameManager.ANGULO_CONO)
	for y: int in range(tam):
		for x: int in range(tam):
			var dir := Vector2(float(x) - tam / 2.0, float(y) - float(tam))
			var dist := dir.length()
			if dist > tam or dist < 1.0:
				continue
			var angulo: float = abs(wrapf(dir.angle() + PI / 2.0, -PI, PI))
			if angulo > medio_angulo:
				continue
			var intensidad := 1.0 - (dist / float(tam))
			imagen.set_pixel(x, y, Color(1.0, 1.0, 1.0, intensidad))
	$Linterna.texture = ImageTexture.create_from_image(imagen)
