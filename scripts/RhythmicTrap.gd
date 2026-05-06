extends Area2D

# Trampa rítmica que empuja al jugador sin matarlo
@export_group("Configuración de Ritmo")
@export var push_force := 400.0
@export var push_duration := 0.2
@export var interval_start := 2.0
@export var interval_end := 4.0

@export_group("Movimiento de la Trampa")
@export var movement_range := 50.0
@export var movement_speed := 100.0

var _start_time := 0.0
var _direction := 1
var _initial_pos : Vector2

func _ready() -> void:
	_initial_pos = position
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	var elapsed = Time.get_ticks_msec() / 1000.0 - _start_time
	var cycle = fmod(elapsed, interval_start + interval_end)
	
	if cycle < interval_start:
		# Fase de espera
		pass
	else:
		# Fase de activación (empuje)
		_apply_trap_movement(delta)

func _apply_trap_movement(delta: float) -> void:
	# Movimiento oscilatorio simple para la trampa
	position.x += _direction * movement_speed * delta
	if abs(position.x - _initial_pos.x) > movement_range:
		_direction *= -1

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Empujar al jugador físicamente
		var push_dir = (body.global_position - global_position).normalized()
		if body.has_method("apply_impulse"):
			body.apply_impulse(push_dir * push_force)
		elif "velocity" in body:
			body.velocity += push_dir * push_force
