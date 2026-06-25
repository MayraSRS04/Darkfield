extends Control

@onready var btn_partida_rapida: Button = $Contenedor/BtnPartidaRapida
@onready var btn_modo_historia: Button = $Contenedor/BtnModoHistoria
@onready var btn_opciones: Button = $Contenedor/FilaInferior/BtnOpciones
@onready var btn_salir: Button = $Contenedor/FilaInferior/BtnSalir
@onready var popup_dificultad: PanelContainer = $PopupDificultad
@onready var btn_facil: Button = $PopupDificultad/Opciones/BtnFacil
@onready var btn_medio: Button = $PopupDificultad/Opciones/BtnMedio
@onready var btn_dificil: Button = $PopupDificultad/Opciones/BtnDificil
@onready var fade_menu: ColorRect = $FadeEntrada/Fondo

func _ready() -> void:
	btn_partida_rapida.pressed.connect(_on_partida_rapida)
	btn_modo_historia.pressed.connect(_on_modo_historia)
	btn_opciones.pressed.connect(_on_opciones)
	btn_salir.pressed.connect(_on_salir)
	btn_facil.pressed.connect(_on_dificultad.bind(0))
	btn_medio.pressed.connect(_on_dificultad.bind(1))
	btn_dificil.pressed.connect(_on_dificultad.bind(2))

func _on_partida_rapida() -> void:
	popup_dificultad.visible = not popup_dificultad.visible

func _on_dificultad(nivel: int) -> void:
	GameManager.iniciar_nivel(nivel)
	_fade_salida("res://scenes/01_juego.tscn")

func _on_modo_historia() -> void:
	pass

func _on_opciones() -> void:
	pass

func _on_salir() -> void:
	get_tree().quit()

func _fade_salida(destino: String) -> void:
	fade_menu.get_parent().visible = true
	fade_menu.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(fade_menu, "modulate:a", 1.0, 0.5)
	tween.tween_callback(func(): get_tree().change_scene_to_file(destino))
