extends CanvasLayer

func _process(_delta: float) -> void:
	if not Input.is_action_just_pressed("pausa"):
		return
	if GameManager.estado == GameManager.Estado.JUGANDO:
		get_parent()._on_pausa()
	elif GameManager.estado == GameManager.Estado.PAUSA:
		get_parent()._on_reanudar()
