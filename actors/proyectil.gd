extends Node2D

var objetivo: Vector2
var _tiempo_vuelo := 1.2
var _elapsed := 0.0
var _origen: Vector2
var _activo := true

func _ready() -> void:
	_origen = global_position
	$Area2D.body_entered.connect(_on_cuerpo)

func _process(delta: float) -> void:
	if not _activo:
		return
	_elapsed += delta
	var t := minf(_elapsed / _tiempo_vuelo, 1.0)
	var pos_lineal := _origen.lerp(objetivo, t)
	var arco := sin(t * PI) * 20.0
	global_position = pos_lineal + Vector2(0, -arco)
	if t >= 1.0:
		_explotar()

func _on_cuerpo(cuerpo: Node) -> void:
	if not _activo:
		return
	if cuerpo.is_in_group("jugador"):
		_explotar()

func _explotar() -> void:
	if not _activo:
		return
	_activo = false
	var juego = get_parent()
	if juego.has_method("_on_impacto_granada"):
		juego._on_impacto_granada(global_position)
	queue_free()
