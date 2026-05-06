extends Area2D

# Placa que detecta peso y emite una señal
@export_group("Configuración")
@export var active_color := Color(0, 1, 0, 0.5)
@export var inactive_color := Color(1, 0, 0, 0.5)

signal plate_activated(is_active: bool)

@onready var visual := $Visual
var _is_active := false

func _ready() -> void:
	visual.color = inactive_color
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("heavy_object"):
		_set_state(true)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("heavy_object"):
		_set_state(false)

func _set_state(active: bool) -> void:
	if _is_active == active: return
	_is_active = active
	visual.color = active_color if active else inactive_color
	plate_activated.emit(_is_active)
