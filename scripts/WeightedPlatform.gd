extends AnimatableBody2D

# Plataforma que se hunde o se mueve según el peso
@export_group("Configuración de Peso")
@export var max_sink_depth := 20.0
@export var sink_speed := 50.0
@export var recovery_speed := 30.0

var _original_position : Vector2
var _current_sink := 0.0
var _is_pressed := false

@onready var detection_area : Area2D = $DetectionArea

func _ready() -> void:
	_original_position = position
	if not detection_area:
		push_error("WeightedPlatform: No se encontró el nodo DetectionArea (Area2D)")
		return
	
	# Conectar señales de la detección
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if not detection_area: return

	if _is_pressed:
		_current_sink = move_toward(_current_sink, max_sink_depth, sink_speed * delta)
	else:
		_current_sink = move_toward(_current_sink, 0.0, recovery_speed * delta)
		
	position = _original_position + Vector2(0, _current_sink)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_is_pressed = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_is_pressed = false
