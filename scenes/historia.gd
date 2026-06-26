extends Control

@onready var btn_nivel_0: Button = $Contenedor/Niveles/BtnNivel0
@onready var btn_nivel_1: Button = $Contenedor/Niveles/BtnNivel1
@onready var btn_nivel_2: Button = $Contenedor/Niveles/BtnNivel2
@onready var btn_nueva_partida: Button = $Contenedor/FilaInferior/BtnNuevaPartida
@onready var btn_volver: Button = $Contenedor/FilaInferior/BtnVolver
@onready var fade_fondo: ColorRect = $FadeEntrada/Fondo

const COLOR_DESBLOQUEADO := Color(0.6, 0.78, 0.93, 1)
const COLOR_BLOQUEADO := Color(0.3, 0.35, 0.42, 1)
const NOMBRES_NIVEL := [
	"NIVEL 1 — La Emboscada",
	"NIVEL 2 — Zona de Guerra",
	"NIVEL 3 — El Último Bastión",
]

func _ready() -> void:
	btn_nivel_0.pressed.connect(_on_nivel.bind(0))
	btn_nivel_1.pressed.connect(_on_nivel.bind(1))
	btn_nivel_2.pressed.connect(_on_nivel.bind(2))
	btn_nueva_partida.pressed.connect(_on_nueva_partida)
	btn_volver.pressed.connect(_on_volver)
	_actualizar_botones()
	_iniciar_fade()

func _actualizar_botones() -> void:
	var maximo: int = GameManager.nivel_maximo_desbloqueado
	var botones := [btn_nivel_0, btn_nivel_1, btn_nivel_2]
	for i in botones.size():
		var btn: Button = botones[i]
		var desbloqueado: bool = i <= maximo
		btn.disabled = not desbloqueado
		btn.add_theme_color_override(
			"font_color",
			COLOR_DESBLOQUEADO if desbloqueado else COLOR_BLOQUEADO
		)
		if not desbloqueado:
			btn.text = "🔒 " + NOMBRES_NIVEL[i]
		else:
			btn.text = NOMBRES_NIVEL[i]

func _on_nivel(indice: int) -> void:
	GameManager.iniciar_nivel_historia(indice)
	_fade_salida("res://scenes/01_juego.tscn")

func _on_nueva_partida() -> void:
	GameManager.reiniciar_progreso()
	_actualizar_botones()

func _on_volver() -> void:
	_fade_salida("res://scenes/00_menu.tscn")

func _iniciar_fade() -> void:
	fade_fondo.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(fade_fondo, "modulate:a", 0.0, 0.8)
	tween.tween_callback(func(): fade_fondo.get_parent().visible = false)

func _fade_salida(destino: String) -> void:
	fade_fondo.get_parent().visible = true
	fade_fondo.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(fade_fondo, "modulate:a", 1.0, 0.5)
	tween.tween_callback(func(): get_tree().change_scene_to_file(destino))
