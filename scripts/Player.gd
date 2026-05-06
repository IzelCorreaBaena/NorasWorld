extends CharacterBody2D

## --- ENUMS ---
enum State { IDLE, MOVE, AIR, WALL_SLIDE, LEDGE_HANG, DASH }

## --- CONFIGURACIÓN (Ajustable desde el Inspector) ---
@export_group("Movimiento Base")
@export var SPEED := 300.0
@export var ACCELERATION := 1500.0
@export var FRICTION := 1200.0
@export var GRAVITY := 1100.0
@export var FALL_GRAVITY_MULT := 1.5

@export_group("Salto y Parkour")
@export var JUMP_VELOCITY := -450.0
@export var WALL_JUMP_VELOCITY := Vector2(350.0, -400.0)
@export var WALL_SLIDE_SPEED := 80.0
@export var COYOTE_TIME := 0.15
@export var JUMP_BUFFER := 0.15

@export_group("Dash")
@export var DASH_SPEED := 600.0
@export var DASH_DURATION := 0.2
@export var DASH_COOLDOWN := 0.8
@export var THROW_FORCE := 500.0

@export_group("Interacción")
@export var INTERACTION_RANGE := 50.0
@export var THROW_FORCE := 500.0

## --- VARIABLES DE ESTADO ---
var current_state := State.IDLE
var facing_direction := 1 # 1: Derecha, -1: Izquierda
var is_dead := false
var held_object : Node2D = null
var dash_timer := 0.0
var dash_cooldown_timer := 0.0

## --- NODOS ---
@onready var sprite := $AnimatedSprite2D
@onready var collision := $CollisionShape2D
@onready var wall_detector := $WallDetector
@onready var ledge_detector := $LedgeDetector
@onready var coyote_timer := $CoyoteTimer
@onready var jump_buffer_timer := $JumpBufferTimer

# Nodos de interacción dinámicos
var interaction_ray : RayCast2D
var hold_socket : Marker2D



## --- SEÑALES ---
signal player_died
signal collectible_found(id: String)

func _ready() -> void:
	add_to_group("player")
	GameManager.game_over.connect(_on_game_over)
	
	# Configuración de Timers
	coyote_timer.wait_time = COYOTE_TIME
	jump_buffer_timer.wait_time = JUMP_BUFFER
	coyote_timer.one_shot = true
	jump_buffer_timer.one_shot = true
	
	_setup_interaction_nodes()

func _setup_interaction_nodes() -> void:
	# Crear RayCast para interacción
	interaction_ray = RayCast2D.new()
	interaction_ray.enabled = true
	interaction_ray.target_position = Vector2(INTERACTION_RANGE, 0)
	add_child(interaction_ray)
	
	# Crear Socket para sostener objetos
	hold_socket = Marker2D.new()
	hold_socket.position = Vector2(0, -30)
	add_child(hold_socket)

func _physics_process(delta: float) -> void:
	if is_dead: return
	
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# 1. Gestión de Inputs y Buffers
	_process_inputs()
	
	# 2. Máquina de Estados
	match current_state:
		State.IDLE, State.MOVE:
			_state_ground(delta)
		State.AIR:
			_state_air(delta)
		State.WALL_SLIDE:
			_state_wall_slide(delta)
		State.LEDGE_HANG:
			_state_ledge_hang(delta)
		State.DASH:
			_state_dash(delta)

	# 3. Ejecución de Movimiento
	move_and_slide()
	
	# 4. Actualización de Visuales
	_update_visuals()


# --- LÓGICA DE ESTADOS ---

func _process_inputs() -> void:
	# Jump Buffer
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer.start()
	
	# Coyote Time
	if is_on_floor():
		coyote_timer.start()
	
	# Dash
	if Input.is_action_just_pressed("ui_select") and can_dash():
		_start_dash()

	# Interaction: Recoger/Soltar (ui_context para interactuar)
	if Input.is_action_just_pressed("ui_context"):
		if held_object:
			_throw_object()
		else:
			_try_pickup()




func _state_ground(delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	
	# Movimiento
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
		facing_direction = direction
		current_state = State.MOVE
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		current_state = State.IDLE
	
	# Salto
	if jump_buffer_timer.is_stopped() == false and not coyote_timer.is_stopped():
		_perform_jump()
	
	if not is_on_floor():
		current_state = State.AIR
	
	if Input.is_action_just_pressed("ui_select") and can_dash():
		_start_dash()

func _state_air(delta: float) -> void:
	var gravity_to_apply = GRAVITY
	if velocity.y > 0: gravity_to_apply *= FALL_GRAVITY_MULT
	velocity.y += gravity_to_apply * delta
	
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * 0.5 * delta)
		facing_direction = direction
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * 0.5 * delta)
		
	if is_on_floor():
		current_state = State.IDLE
	elif is_on_wall() and velocity.y > 0:
		current_state = State.WALL_SLIDE
	elif wall_detector.is_colliding() and not ledge_detector.is_colliding():
		current_state = State.LEDGE_HANG

func _state_wall_slide(delta: float) -> void:
	velocity.y = min(velocity.y + GRAVITY * delta, WALL_SLIDE_SPEED)
	
	if jump_buffer_timer.is_stopped() == false:
		var normal = get_wall_normal()
		velocity.x = normal.x * WALL_JUMP_VELOCITY.x
		velocity.y = WALL_JUMP_VELOCITY.y
		jump_buffer_timer.stop()
		current_state = State.AIR
		
	if is_on_floor():
		current_state = State.IDLE
	elif not is_on_wall():
		current_state = State.AIR

func _state_ledge_hang(delta: float) -> void:
	velocity = Vector2.ZERO
	if jump_buffer_timer.is_stopped() == false:
		_perform_jump()
		current_state = State.AIR
	if Input.is_action_just_pressed("ui_down"):
		current_state = State.AIR
	if not wall_detector.is_colliding():
		current_state = State.AIR

func _state_dash(delta: float) -> void:
	dash_timer -= delta
	velocity.x = facing_direction * DASH_SPEED
	velocity.y = 0
	
	if dash_timer <= 0:
		_end_dash()

func _end_dash() -> void:
	current_state = State.AIR

func _update_visuals() -> void:
	sprite.flip_h = (facing_direction == -1)
	wall_detector.target_position.x = abs(wall_detector.target_position.x) * facing_direction
	ledge_detector.target_position.x = abs(ledge_detector.target_position.x) * facing_direction
	
	if current_state == State.LEDGE_HANG:
		sprite.modulate = Color(0.7, 0.7, 0.7)
	else:
		sprite.modulate = Color.WHITE
	
	_update_animation()


func _update_animation() -> void:
	if not sprite.sprite_frames: return
	
	match current_state:
		State.IDLE:
			sprite.play("idle")
		State.MOVE:
			sprite.play("walk")
		State.AIR:
			if velocity.y < 0: sprite.play("jump")
			else: sprite.play("fall")
		State.WALL_SLIDE:
			sprite.play("wall_slide")
		State.DASH:
			sprite.play("dash")
		State.LEDGE_HANG:
			sprite.play("ledge_hang")
	
	# Speed scale for dash
	if current_state == State.DASH:
		sprite.speed_scale = 2.0
	else:
		sprite.speed_scale = 1.0



func _on_game_over() -> void:
	die()

func die() -> void:
	if is_dead: return
	is_dead = true
	player_died.emit()
