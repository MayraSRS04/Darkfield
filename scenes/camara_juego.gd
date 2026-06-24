extends Camera2D

const ZOOM_MAPA := Vector2(4.0, 4.0)

func _ready() -> void:
	zoom = ZOOM_MAPA
	call_deferred("_configurar_limites")

func _configurar_limites() -> void:
	var tilemap: TileMapLayer = get_tree().current_scene.get_node("Suelo")
	var rect := tilemap.get_used_rect()
	var tam_celda: Vector2 = Vector2(tilemap.tile_set.tile_size)
	limit_left   = int(rect.position.x * tam_celda.x)
	limit_top    = int(rect.position.y * tam_celda.y)
	limit_right  = int((rect.position.x + rect.size.x) * tam_celda.x)
	limit_bottom = int((rect.position.y + rect.size.y) * tam_celda.y)
