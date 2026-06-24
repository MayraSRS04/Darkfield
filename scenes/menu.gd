extends Control

@onready var btn_partida_rapida: Button = $Contenedor/BtnPartidaRapida
@onready var btn_modo_historia: Button = $Contenedor/BtnModoHistoria
@onready var btn_opciones: Button = $Contenedor/FilaInferior/BtnOpciones
@onready var btn_salir: Button = $Contenedor/FilaInferior/BtnSalir

func _ready() -> void:
	btn_partida_rapida.pressed.connect(_on_partida_rapida)
	btn_modo_historia.pressed.connect(_on_modo_historia)
	btn_opciones.pressed.connect(_on_opciones)
	btn_salir.pressed.connect(_on_salir)

func _on_partida_rapida() -> void:
	GameManager.iniciar_nivel(0)
	get_tree().change_scene_to_file("res://scenes/01_juego.tscn")

func _on_modo_historia() -> void:
	pass

func _on_opciones() -> void:
	pass

func _on_salir() -> void:
	get_tree().quit()
