extends Control

@onready var slider_brillo: HSlider = $Contenedor/FilaBrillo/SliderBrillo
@onready var lbl_valor: Label = $Contenedor/FilaBrillo/LblValor
@onready var overlay_brillo: ColorRect = $OverlayBrillo
@onready var btn_volver: Button = $Contenedor/BtnVolver
@onready var fade: ColorRect = $FadeEntrada/Fondo

func _ready() -> void:
	slider_brillo.value = GameManager.brillo
	_aplicar_brillo(GameManager.brillo)
	slider_brillo.value_changed.connect(_on_brillo_cambiado)
	btn_volver.pressed.connect(_on_volver)
	_iniciar_fade()

func _on_brillo_cambiado(valor: float) -> void:
	GameManager.brillo = valor
	_aplicar_brillo(valor)

func _aplicar_brillo(valor: float) -> void:
	overlay_brillo.color.a = 1.0 - valor
	lbl_valor.text = str(int(valor * 100)) + "%"

func _on_volver() -> void:
	fade.get_parent().visible = true
	fade.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 0.4)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/00_menu.tscn"))

func _iniciar_fade() -> void:
	fade.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func(): fade.get_parent().visible = false)
