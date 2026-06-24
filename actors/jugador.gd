extends CharacterBody2D

signal solicito_revelar
signal solicito_abanderar

var destino: Vector2
var moviendose := false
var ultima_direccion := Vector2.RIGHT

func _ready() -> void:
	destino = global_position

func _physics_process(delta: float) -> void:
	if moviendose:
		global_position = global_position.move_toward(destino, GameManager.VELOCIDAD_JUGADOR * delta)
		if global_position.distance_to(destino) < 1.0:
			global_position = destino
			moviendose = false
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var direccion := Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		direccion = Vector2.LEFT
	elif Input.is_action_pressed("ui_right"):
		direccion = Vector2.RIGHT
	elif Input.is_action_pressed("ui_up"):
		direccion = Vector2.UP
	elif Input.is_action_pressed("ui_down"):
		direccion = Vector2.DOWN
	if direccion != Vector2.ZERO:
		var celda_actual: Vector2i = get_parent().get_node("Suelo").local_to_map(global_position)
		var celda_destino: Vector2i = celda_actual + Vector2i(direccion)
		var pos_destino: Vector2 = get_parent().get_node("Suelo").map_to_local(celda_destino)
		if not get_parent().get_node("Paredes").get_cell_source_id(celda_destino) != -1:
			destino = pos_destino
			moviendose = true
		ultima_direccion = direccion
		$Sprite2D.rotation = ultima_direccion.angle()
	velocity = Vector2.ZERO
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			solicito_revelar.emit()
		elif event.keycode == KEY_F:
			solicito_abanderar.emit()
