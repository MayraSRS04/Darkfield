extends Node

enum Estado { MENU, JUGANDO, PAUSA, GAME_OVER }

const VELOCIDAD_JUGADOR := 120.0
const VELOCIDAD_CAZADOR := 70.0
const ALCANCE_VISION := 4
const ANGULO_CONO := 35.0
const DURACION_CONGELAR := 3.0
const RADIO_RADAR := 2
const MAX_PAUSA := 5.0
const RECARGA_PAUSA := 1.0
const TIEMPO_ESPERA_PATRULLA := 3.0

signal estado_cambiado(nuevo: Estado)
signal minas_restantes_cambiado(cantidad: int)
signal jugador_detectado(detectado: bool)
signal nivel_completado
signal jugador_murio

var estado: Estado = Estado.MENU
var nivel_actual: int = 0
var minas_restantes: int = 0


func _ready() -> void:
	print("GameManager listo")


func iniciar_nivel(indice: int) -> void:
	nivel_actual = indice
	get_tree().paused = false
	_cambiar_estado(Estado.JUGANDO)


func pausar() -> void:
	if estado != Estado.JUGANDO:
		return
	get_tree().paused = true
	_cambiar_estado(Estado.PAUSA)


func reanudar() -> void:
	if estado != Estado.PAUSA:
		return
	get_tree().paused = false
	_cambiar_estado(Estado.JUGANDO)


func actualizar_minas_restantes(cantidad: int) -> void:
	minas_restantes = cantidad
	minas_restantes_cambiado.emit(cantidad)


func reportar_deteccion(detectado: bool) -> void:
	jugador_detectado.emit(detectado)


func nivel_ganado() -> void:
	_cambiar_estado(Estado.GAME_OVER)
	nivel_completado.emit()


func morir() -> void:
	_cambiar_estado(Estado.GAME_OVER)
	jugador_murio.emit()


func _cambiar_estado(nuevo: Estado) -> void:
	estado = nuevo
	estado_cambiado.emit(nuevo)
