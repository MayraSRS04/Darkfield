extends CharacterBody2D

signal solicito_revelar


func _physics_process(_delta: float) -> void:
	var direccion := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direccion * GameManager.VELOCIDAD_JUGADOR
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			solicito_revelar.emit()
