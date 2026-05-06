extends AnimatableBody2D

# Puerta o barrera que se abre/cierra mediante una señal
@export_group("Configuración")
@export var open_direction := Vector2.UP
@export var open_distance := 100.0
@export var open_speed := 2.0

var _is_open := false
var _original_position : Vector2
var _tween : Tween

func _ready() -> void:
	_original_position = position

func toggle(should_open: bool) -> void:
	if _is_open == should_open: return
	_is_open = should_open
	
	if _tween:
		_tween.kill()
	
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var target_pos = _original_position + (open_direction * open_distance if _is_open else Vector2.ZERO)
	_tween.tween_property(self, "position", target_pos, 1.0 / open_speed)
