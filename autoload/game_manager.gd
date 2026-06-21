extends Node

enum Estado { MENU, JUGANDO, PAUSA, GAME_OVER }

var estado: Estado = Estado.MENU


func _ready() -> void:
	print("GameManager listo")
