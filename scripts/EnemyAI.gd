extends CharacterBody2D

enum State { PATROL, DETECT, CHASE, ATTACK, DEAD }

@export_group("AI Settings")
@export var patrol_range := 200.0
@export var detection_range := 300.0
@export var attack_range := 50.0
@export var move_speed := 100.0
@export var attack_speed := 1.5
@export var max_health := 3

@onready var ray_detector := $RayCast2D
@onready var attack_area := $AttackArea

var current_state := State.PATROL
var target_player : CharacterBody2D = null
var patrol_start_pos : Vector2
var patrol_direction := 1
var _attack_timer := 0.0
var health := max_health

func _ready() -> void:
	patrol_start_pos = position
	attack_area.body_entered.connect(_on_attack_area_entered)
	attack_area.body_exited.connect(_on_attack_area_exited)
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	match current_state:
		State.PATROL:
			_state_patrol(delta)
		State.DETECT:
			_state_detect(delta)
		State.CHASE:
			_state_chase(delta)
		State.ATTACK:
			_state_attack(delta)

# --- STATES ---

func _state_patrol(delta: float) -> void:
	velocity.x = patrol_direction * move_speed
	move_and_slide()
	
	if abs(position.x - patrol_start_pos.x) > patrol_range:
		patrol_direction *= -1
	
	if _can_see_player():
		current_state = State.DETECT

func _state_detect(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, move_speed * delta)
	move_and_slide()
	
	if target_player:
		current_state = State.CHASE
	elif not _can_see_player():
		current_state = State.PATROL

func _state_chase(delta: float) -> void:
	if not target_player or not is_instance_valid(target_player):
		current_state = State.PATROL
		return
		
	var dir = sign(target_player.global_position.x - global_position.x)
	velocity.x = dir * (move_speed * 1.5)
	move_and_slide()
	
	if global_position.distance_to(target_player.global_position) < attack_range:
		current_state = State.ATTACK
	elif not _can_see_player():
		current_state = State.DETECT

func _state_attack(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, move_speed * delta)
	
	_attack_timer += delta
	if _attack_timer >= attack_speed:
		_perform_attack()
		_attack_timer = 0.0
		
	if not target_player or global_position.distance_to(target_player.global_position) > attack_range:
		current_state = State.CHASE

# --- ACTIONS ---

func _can_see_player() -> bool:
	if target_player == null: return false
	
	var dist = global_position.distance_to(target_player.global_position)
	if dist < detection_range:
		ray_detector.target_position = to_local(target_player.global_position)
		ray_detector.force_raycast_update()
		if ray_detector.is_colliding():
			var collider = ray_detector.get_collider()
			if collider.is_in_group("player"):
				return true
	return false

func _perform_attack() -> void:
	if target_player and target_player.has_method("take_damage"):
		target_player.take_damage(1)

func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO) -> void:
	health -= amount
	
	if source_position != Vector2.ZERO:
		var push_dir = (global_position - source_position).normalized()
		velocity += push_dir * 400.0
	
	if health <= 0:
		_die()

func _die() -> void:
	current_state = State.DEAD
	queue_free()

func _on_attack_area_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target_player = body

func _on_attack_area_exited(body: Node2D) -> void:
	if body == target_player:
		target_player = null
