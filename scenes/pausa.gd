extends CanvasLayer

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pausa") and GameManager.estado == GameManager.Estado.PAUSA:
		get_tree().paused = false
		GameManager.reanudar()
