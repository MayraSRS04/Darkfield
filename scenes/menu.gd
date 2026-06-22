extends Control


func _ready() -> void:
	print("Menu cargado")

	GameManager.estado_cambiado.connect(_on_estado_cambiado)
	GameManager.minas_restantes_cambiado.connect(_on_minas_cambiado)
	GameManager.jugador_detectado.connect(_on_deteccion)
	GameManager.nivel_completado.connect(_on_nivel_completado)
	GameManager.jugador_murio.connect(_on_jugador_murio)

	print("--- prueba de señales ---")
	GameManager.iniciar_nivel(0)
	GameManager.actualizar_minas_restantes(12)
	GameManager.reportar_deteccion(true)
	GameManager.pausar()
	GameManager.reanudar()
	GameManager.nivel_ganado()
	GameManager.morir()
	print("--- fin de prueba ---")


func _on_estado_cambiado(nuevo: int) -> void:
	print("estado cambiado a: ", nuevo)


func _on_minas_cambiado(cantidad: int) -> void:
	print("minas restantes: ", cantidad)


func _on_deteccion(detectado: bool) -> void:
	print("detectado: ", detectado)


func _on_nivel_completado() -> void:
	print("nivel completado")


func _on_jugador_murio() -> void:
	print("jugador murio")
