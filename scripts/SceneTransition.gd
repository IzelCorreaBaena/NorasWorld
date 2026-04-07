extends CanvasLayer
# Autoload: SceneTransition
# Fade negro entre cambios de escena. Uso:
#   SceneTransition.go_to("res://scenes/World1.tscn")

const FADE_TIME := 0.35

var _overlay : ColorRect
var _busy    := false

func _ready() -> void:
	layer = 100
	_overlay = ColorRect.new()
	_overlay.color        = Color.BLACK
	_overlay.modulate.a   = 1.0                        # empieza en negro
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	# Fade-in al arrancar el juego: negro → transparente
	var tw := create_tween()
	tw.tween_property(_overlay, "modulate:a", 0.0, FADE_TIME)

func go_to(path: String) -> void:
	if _busy:
		return
	_busy = true
	var tw := create_tween()
	# 1. Fade a negro
	tw.tween_property(_overlay, "modulate:a", 1.0, FADE_TIME)
	# 2. Cambiar escena mientras la pantalla está negra
	tw.tween_callback(func():
		get_tree().change_scene_to_file(path)
	)
	# 3. Fade de vuelta a transparente (revela la nueva escena)
	tw.tween_property(_overlay, "modulate:a", 0.0, FADE_TIME)
	# 4. Liberar bloqueo
	tw.tween_callback(func(): _busy = false)

func flash_white(duration: float = 0.2) -> void:
	var orig := _overlay.color
	_overlay.color      = Color.WHITE
	_overlay.modulate.a = 0.6
	var tw := create_tween()
	tw.tween_property(_overlay, "modulate:a", 0.0, duration)
	tw.tween_callback(func(): _overlay.color = orig)
