extends Node2D

signal recogido(tipo)

var tipo: GameManager.TipoItem
var _activo := true

const ICONOS := {
	GameManager.TipoItem.RADAR: "📡",
	GameManager.TipoItem.BOOST: "⚡",
	GameManager.TipoItem.CONGELADO: "❄️",
	GameManager.TipoItem.ESCUDO: "🛡️",
	GameManager.TipoItem.PISTOLA: "🔫",
	GameManager.TipoItem.BAZUKA: "💥",
}

func _ready() -> void:
	var etiqueta := Label.new()
	etiqueta.text = ICONOS.get(tipo, "?")
	etiqueta.add_theme_font_size_override("font_size", 14)
	etiqueta.size = Vector2(16, 16)
	etiqueta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta.position = Vector2(-8, -8)
	add_child(etiqueta)

func intentar_recoger(pos_jugador: Vector2) -> void:
	if not _activo:
		return
	if global_position.distance_to(pos_jugador) < 10.0:
		_activo = false
		recogido.emit(tipo)
		queue_free()
