extends Control

@onready var slider_brillo: HSlider = $Contenedor/FilaBrillo/SliderBrillo
@onready var lbl_brillo: Label = $Contenedor/FilaBrillo/LblValor
@onready var slider_musica: HSlider = $Contenedor/FilaMusica/SliderMusica
@onready var lbl_musica: Label = $Contenedor/FilaMusica/LblValorMusica
@onready var slider_sfx: HSlider = $Contenedor/FilaSFX/SliderSFX
@onready var lbl_sfx: Label = $Contenedor/FilaSFX/LblValorSFX
@onready var chk_pantalla: CheckButton = $Contenedor/FilaPantalla/ChkPantalla
@onready var overlay_brillo: ColorRect = $OverlayBrillo
@onready var btn_volver: Button = $Contenedor/BtnVolver
@onready var fade: ColorRect = $FadeEntrada/Fondo

func _ready() -> void:
	slider_brillo.value = GameManager.brillo
	slider_musica.value = GameManager.vol_musica
	slider_sfx.value = GameManager.vol_sfx
	chk_pantalla.button_pressed = GameManager.pantalla_completa
	_aplicar_brillo(GameManager.brillo)
	_actualizar_labels()

	slider_brillo.value_changed.connect(_on_brillo_cambiado)
	slider_musica.value_changed.connect(_on_musica_cambiada)
	slider_sfx.value_changed.connect(_on_sfx_cambiado)
	chk_pantalla.toggled.connect(_on_pantalla_toggled)
	btn_volver.pressed.connect(_on_volver)
	_iniciar_fade()

func _actualizar_labels() -> void:
	lbl_brillo.text = str(int(GameManager.brillo * 100)) + "%"
	lbl_musica.text = str(int(GameManager.vol_musica * 100)) + "%"
	lbl_sfx.text = str(int(GameManager.vol_sfx * 100)) + "%"

func _on_brillo_cambiado(valor: float) -> void:
	GameManager.brillo = valor
	_aplicar_brillo(valor)
	lbl_brillo.text = str(int(valor * 100)) + "%"

func _on_musica_cambiada(valor: float) -> void:
	GameManager.vol_musica = valor
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Musica"),
		linear_to_db(valor)
	)
	lbl_musica.text = str(int(valor * 100)) + "%"

func _on_sfx_cambiado(valor: float) -> void:
	GameManager.vol_sfx = valor
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear_to_db(valor)
	)
	lbl_sfx.text = str(int(valor * 100)) + "%"

func _on_pantalla_toggled(activo: bool) -> void:
	GameManager.pantalla_completa = activo
	if activo:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _aplicar_brillo(valor: float) -> void:
	overlay_brillo.color.a = 1.0 - valor

func _on_volver() -> void:
	GameManager.guardar_opciones()
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
