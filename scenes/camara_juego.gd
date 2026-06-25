extends Camera2D

const MARGEN := 0.85

func _ready() -> void:
	zoom = Vector2(4.0, 4.0)

func configurar_limites(tilemap: TileMapLayer) -> void:
	var rect := tilemap.get_used_rect()
	var tam_celda := Vector2(tilemap.tile_set.tile_size)
	var mapa_px := Vector2(rect.size) * tam_celda

	var viewport_sz := get_viewport_rect().size
	var zoom_ajustado := minf(
		viewport_sz.x / mapa_px.x,
		viewport_sz.y / mapa_px.y
	) * MARGEN * (1920.0 / viewport_sz.x)

	zoom_ajustado = clampf(zoom_ajustado, 2.5, 5.5)
	zoom = Vector2(zoom_ajustado, zoom_ajustado)

	var margen_px := int(tam_celda.x * 0.5)
	limit_left   = int(rect.position.x * tam_celda.x) - margen_px
	limit_top    = int(rect.position.y * tam_celda.y) - margen_px
	limit_right  = int((rect.position.x + rect.size.x) * tam_celda.x) + margen_px
	limit_bottom = int((rect.position.y + rect.size.y) * tam_celda.y) + margen_px
