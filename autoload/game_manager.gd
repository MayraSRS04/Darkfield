extends Node

enum Estado { MENU, JUGANDO, PAUSA, GAME_OVER }
enum TipoItem { RADAR, BOOST, CONGELADO, ESCUDO, PISTOLA, BAZUKA }

const VELOCIDAD_JUGADOR := 120.0
const VELOCIDAD_CAZADOR := 70.0
const ALCANCE_VISION := 4
const ANGULO_CONO := 35.0
const DURACION_CONGELAR := 3.0
const RADIO_RADAR := 2
const MAX_PAUSA := 5.0
const RECARGA_PAUSA := 1.0
const TIEMPO_ESPERA_PATRULLA := 3.0

const VELOCIDAD_BOOST := 220.0
const DURACION_BOOST := 5.0
const DURACION_RADAR := 3.0
const DURACION_CONGELADO_ITEM := 3.0
const BALAS_POR_PISTOLA := 10
const VIDA_BOSS := 100
const DANIO_PISTOLA := 10
const DANIO_BAZUKA := 50

const CONFIGURACIONES := [
	{"filas": 31, "columnas": 31, "minas": 95, "cazadores": 6},
	{"filas": 61, "columnas": 61, "minas": 125, "cazadores": 10},
	{"filas": 81, "columnas": 81, "minas": 180, "cazadores": 14},
]

const ITEMS_POR_NIVEL := [
	[TipoItem.RADAR, TipoItem.ESCUDO],
	[TipoItem.BOOST, TipoItem.CONGELADO, TipoItem.PISTOLA],
	[TipoItem.BAZUKA, TipoItem.ESCUDO],
]

const RUTA_GUARDADO := "user://progreso_historia.cfg"

signal estado_cambiado(nuevo: Estado)
signal minas_restantes_cambiado(cantidad: int)
signal jugador_detectado(detectado: bool)
signal nivel_completado
signal jugador_murio
signal inventario_cambiado

var estado: Estado = Estado.MENU
var nivel_actual: int = 0
var minas_restantes: int = 0
var celdas_reservadas: Dictionary = {}
var modo_historia: bool = false
var inventario: Array = []
var nivel_maximo_desbloqueado: int = 0

func _ready() -> void:
	_cargar_progreso()

func iniciar_nivel(indice: int) -> void:
	nivel_actual = indice
	get_tree().paused = false
	celdas_reservadas.clear()
	_cambiar_estado(Estado.JUGANDO)

func iniciar_nivel_historia(indice: int) -> void:
	modo_historia = true
	iniciar_nivel(indice)

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
	if modo_historia:
		_registrar_progreso_nivel()
	nivel_completado.emit()

func morir() -> void:
	_cambiar_estado(Estado.GAME_OVER)
	jugador_murio.emit()

func agregar_item(tipo: TipoItem) -> void:
	inventario.append(tipo)
	inventario_cambiado.emit()

func consumir_item(tipo: TipoItem) -> bool:
	var idx := inventario.find(tipo)
	if idx == -1:
		return false
	inventario.remove_at(idx)
	inventario_cambiado.emit()
	return true

func tiene_item(tipo: TipoItem) -> bool:
	return inventario.has(tipo)

func cantidad_item(tipo: TipoItem) -> int:
	var cuenta := 0
	for i in inventario:
		if i == tipo:
			cuenta += 1
	return cuenta

func _registrar_progreso_nivel() -> void:
	if nivel_actual >= nivel_maximo_desbloqueado:
		nivel_maximo_desbloqueado = nivel_actual + 1
	var items_ganados: Array = ITEMS_POR_NIVEL[nivel_actual] if nivel_actual < ITEMS_POR_NIVEL.size() else []
	for item in items_ganados:
		inventario.append(item)
	inventario_cambiado.emit()
	_guardar_progreso()

func _guardar_progreso() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("historia", "nivel_maximo", nivel_maximo_desbloqueado)
	cfg.set_value("historia", "inventario", inventario)
	cfg.save(RUTA_GUARDADO)

func _cargar_progreso() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(RUTA_GUARDADO) != OK:
		return
	nivel_maximo_desbloqueado = cfg.get_value("historia", "nivel_maximo", 0)
	inventario = cfg.get_value("historia", "inventario", [])

func reiniciar_progreso() -> void:
	nivel_maximo_desbloqueado = 0
	inventario = []
	inventario_cambiado.emit()
	var cfg := ConfigFile.new()
	cfg.save(RUTA_GUARDADO)

func _cambiar_estado(nuevo: Estado) -> void:
	estado = nuevo
	estado_cambiado.emit(nuevo)
