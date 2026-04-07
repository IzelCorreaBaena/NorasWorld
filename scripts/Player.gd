extends CharacterBody2D

# === CONSTANTS ===
const SPEED           := 200.0
const JUMP_VELOCITY   := -460.0
const GRAVITY         := 900.0
const FALL_GRAVITY_MULT := 1.5
const MAX_FALL_SPEED  := 700.0
const COYOTE_TIME     := 0.15
const JUMP_BUFFER     := 0.12
const INVINCIBLE_TIME := 1.5
const KNOCKBACK       := 200.0
const DASH_SPEED      := 500.0
const DASH_TIME       := 0.18
const WALL_JUMP_VX    := 250.0
const WALL_JUMP_VY    := -380.0
const WALL_SLIDE_MAX  := 80.0
const CROUCH_SPEED_MULT := 0.6
const CROUCH_HEIGHT   := 20.0   # reduced from 36
const STAND_HEIGHT    := 36.0   # original capsule height

# === STATE ===
var coyote_timer     := 0.0
var jump_buffer      := 0.0
var was_on_floor     := false
var facing_right     := true
var is_dead          := false
var is_invincible    := false
var invincible_timer := 0.0
var jumps_left       := 1
var is_dashing       := false
var dash_timer       := 0.0
var dash_cooldown    := 0.0
var can_dash         := true
var dashes_left      := 1
var in_water         := false
var on_wall_left     := false
var on_wall_right    := false
var wall_jump_timer  := 0.0
const WALL_JUMP_GRACE := 0.15
var is_crouching     := false

# === ONREADY NODES ===
@onready var sprite    : AnimatedSprite2D = $AnimatedSprite2D
@onready var camera    : Camera2D         = $Camera
@onready var collision : CollisionShape2D = $Collision

# === SIGNALS ===
signal player_died
signal collectible_found(id: String)
signal crouch_changed(crouching: bool)

func _ready() -> void:
	add_to_group("player")
	GameManager.game_over.connect(_on_game_over)
	_update_abilities()
	if collision == null:
		push_error("Player: Collision node not found")
	for zone in get_tree().get_nodes_in_group("water_zone"):
		if zone is Area2D:
			zone.body_entered.connect(func(b): if b == self: in_water = true)
			zone.body_exited.connect(func(b): if b == self: in_water = false)

func _update_abilities() -> void:
	jumps_left = 2 if GameManager.nora["has_double_jump"] else 1

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_handle_invincibility(delta)
	_handle_crouch()
	_handle_dash(delta)
	if not is_dashing:
		_apply_gravity(delta)
		_handle_coyote(delta)
		_handle_jump_buffer(delta)
		_handle_movement()
		_handle_jump()
		_handle_wall_jump(delta)
	_flip_sprite()
	_update_animation()
	move_and_slide()

	if is_on_floor():
		jumps_left  = 2 if GameManager.nora["has_double_jump"] else 1
		dashes_left = 2 if OutfitManager.has_double_dash() else 1
		wall_jump_timer = 0.0
	was_on_floor = is_on_floor()
	_detect_walls()

func _detect_walls() -> void:
	on_wall_left  = is_on_wall() and get_wall_normal().x > 0
	on_wall_right = is_on_wall() and get_wall_normal().x < 0

# --- CROUCH ---
func _handle_crouch() -> void:
	var wants_crouch := Input.is_action_pressed("ui_down") and is_on_floor() and not is_dashing
	if wants_crouch and not is_crouching:
		_set_crouch(true)
	elif not wants_crouch and is_crouching:
		# Check if there is a ceiling preventing us from standing up
		if _can_stand_up():
			_set_crouch(false)
		# else: stay crouching, ceiling is blocking

func _set_crouch(crouch: bool) -> void:
	if collision == null or collision.shape == null:
		return
	is_crouching = crouch
	var shape: CapsuleShape2D = collision.shape as CapsuleShape2D
	if shape == null:
		push_error("Player: Collision shape is not CapsuleShape2D")
		return

	if crouch:
		# Shrink capsule: reduce height, keep same radius
		# Shift collision down so feet stay on ground
		var height_diff := (STAND_HEIGHT - CROUCH_HEIGHT) * 0.5
		shape.height = CROUCH_HEIGHT
		collision.position.y += height_diff
	else:
		# Restore capsule to standing size
		var height_diff := (STAND_HEIGHT - CROUCH_HEIGHT) * 0.5
		shape.height = STAND_HEIGHT
		collision.position.y -= height_diff

	crouch_changed.emit(is_crouching)

func _can_stand_up() -> bool:
	if collision == null or collision.shape == null:
		return true
	# Temporarily restore shape to standing to test if we fit
	var shape: CapsuleShape2D = collision.shape as CapsuleShape2D
	if shape == null:
		return true
	var old_height := shape.height
	var old_pos    := collision.position
	var height_diff := (STAND_HEIGHT - CROUCH_HEIGHT) * 0.5

	shape.height = STAND_HEIGHT
	collision.position.y = old_pos.y - height_diff

	# test_move checks if moving by zero would cause a collision
	var blocked := test_move(global_transform, Vector2.ZERO)

	# Restore crouch shape
	shape.height = old_height
	collision.position = old_pos
	return not blocked

# --- GRAVITY ---
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		var max_fall := MAX_FALL_SPEED
		var grav     := GRAVITY
		# Apply stronger gravity when falling (not rising)
		if velocity.y > 0:
			grav *= FALL_GRAVITY_MULT
		# Outfit surfera: slow fall in water
		if in_water and OutfitManager.has_water_slow_fall():
			max_fall = 80.0
			grav     = GRAVITY * 0.3
		if _is_wall_sliding():
			velocity.y = min(velocity.y + grav * delta, WALL_SLIDE_MAX)
		else:
			velocity.y = min(velocity.y + grav * delta, max_fall)
	else:
		velocity.y = 0.0

func _is_wall_sliding() -> bool:
	if not GameManager.nora["has_wall_jump"]:
		return false
	if wall_jump_timer > 0:
		return false
	return is_on_wall() and not is_on_floor() and velocity.y > 0

func _handle_coyote(delta: float) -> void:
	if was_on_floor and not is_on_floor():
		coyote_timer = COYOTE_TIME
	elif coyote_timer > 0:
		coyote_timer -= delta

func _handle_jump_buffer(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer = JUMP_BUFFER
	elif jump_buffer > 0:
		jump_buffer -= delta

func _handle_movement() -> void:
	var dir := Input.get_axis("move_left", "move_right")
	var current_speed := SPEED
	if is_crouching:
		current_speed *= CROUCH_SPEED_MULT
	if dir != 0:
		velocity.x = dir * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed * 0.25)

func _handle_jump() -> void:
	# Cannot jump while crouching
	if is_crouching:
		return
	var can_jump_coyote := is_on_floor() or coyote_timer > 0
	if jump_buffer > 0:
		if can_jump_coyote and jumps_left > 0:
			_do_jump()
		elif GameManager.nora["has_double_jump"] and jumps_left > 0 and not can_jump_coyote and not is_on_wall():
			_do_jump()
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.45

func _handle_wall_jump(delta: float) -> void:
	if wall_jump_timer > 0:
		wall_jump_timer -= delta
	if not GameManager.nora["has_wall_jump"]:
		return
	if is_on_floor() or wall_jump_timer > 0:
		return
	if not is_on_wall():
		return
	if jump_buffer > 0:
		var wall_normal := get_wall_normal()
		velocity.x = wall_normal.x * WALL_JUMP_VX
		velocity.y = WALL_JUMP_VY
		jumps_left      = 1
		jump_buffer     = 0.0
		wall_jump_timer = WALL_JUMP_GRACE
		facing_right = velocity.x > 0
		sprite.flip_h = not facing_right

func _do_jump() -> void:
	velocity.y   = JUMP_VELOCITY
	jumps_left  -= 1
	coyote_timer = 0
	jump_buffer  = 0

func _handle_dash(delta: float) -> void:
	if not GameManager.nora["has_dash"]:
		return
	if dash_cooldown > 0:
		dash_cooldown -= delta
		can_dash = false
	else:
		can_dash = dashes_left > 0
	if Input.is_action_just_pressed("dash") and can_dash and not is_dashing:
		is_dashing    = true
		dash_timer    = DASH_TIME
		dashes_left  -= 1
		can_dash      = false
		if OutfitManager.has_star_dash():
			_spawn_star_trail()
	if is_dashing:
		dash_timer -= delta
		velocity.x = (1.0 if facing_right else -1.0) * DASH_SPEED
		velocity.y = 0
		if dash_timer <= 0:
			is_dashing    = false
			dash_cooldown = 0.6

func _spawn_star_trail() -> void:
	var particles := CPUParticles2D.new()
	particles.one_shot             = true
	particles.emitting             = true
	particles.amount               = 12
	particles.lifetime             = 0.4
	particles.spread               = 30.0
	particles.direction            = Vector2(-1.0 if facing_right else 1.0, 0.0)
	particles.gravity              = Vector2.ZERO
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 120.0
	particles.scale_amount_min     = 2.0
	particles.scale_amount_max     = 4.0
	particles.color                = Color(1.0, 0.3, 0.7, 1.0)
	get_parent().add_child(particles)
	particles.global_position = global_position
	get_tree().create_timer(0.5).timeout.connect(particles.queue_free)

func _flip_sprite() -> void:
	# Wall slide: face toward the wall
	if _is_wall_sliding():
		if on_wall_left:
			sprite.flip_h = true
			facing_right = false
		elif on_wall_right:
			sprite.flip_h = false
			facing_right = true
		return
	if velocity.x > 0.1:
		sprite.flip_h = false
		facing_right  = true
	elif velocity.x < -0.1:
		sprite.flip_h = true
		facing_right  = false

func _update_animation() -> void:
	if not sprite.sprite_frames:
		return
	if is_dashing:
		if sprite.sprite_frames.has_animation("walk"):
			if sprite.animation != "walk":
				sprite.play("walk")
			sprite.speed_scale = 2.5
		return
	sprite.speed_scale = 1.0

	# Crouch animation
	if is_crouching:
		if sprite.sprite_frames.has_animation("crouch"):
			if sprite.animation != "crouch":
				sprite.play("crouch")
		else:
			# Fallback: use idle with squash tint
			if sprite.animation != "idle":
				sprite.play("idle")
			sprite.modulate = Color(0.85, 0.85, 0.95, 1.0) if not is_invincible else sprite.modulate
		return
	else:
		# Restore modulate when not crouching (only if not invincible)
		if not is_invincible:
			sprite.modulate = Color.WHITE

	if _is_wall_sliding():
		if sprite.sprite_frames.has_animation("fall") and sprite.animation != "fall":
			sprite.play("fall")
	elif not is_on_floor():
		if velocity.y < 0:
			if sprite.sprite_frames.has_animation("jump") and sprite.animation != "jump":
				sprite.play("jump")
		else:
			if sprite.sprite_frames.has_animation("fall") and sprite.animation != "fall":
				sprite.play("fall")
	elif abs(velocity.x) > 10:
		if sprite.sprite_frames.has_animation("walk") and sprite.animation != "walk":
			sprite.play("walk")
	else:
		if sprite.sprite_frames.has_animation("idle") and sprite.animation != "idle":
			sprite.play("idle")

func _handle_invincibility(delta: float) -> void:
	if is_invincible:
		invincible_timer -= delta
		sprite.modulate.a = 0.4 if fmod(invincible_timer, 0.15) > 0.075 else 1.0
		if invincible_timer <= 0:
			is_invincible     = false
			sprite.modulate.a = 1.0

func take_damage(from_position: Vector2 = Vector2.ZERO) -> void:
	if is_invincible or is_dead:
		return
	# Force stand up when taking damage
	if is_crouching:
		_set_crouch(false)
	is_invincible    = true
	invincible_timer = INVINCIBLE_TIME
	var dir := int(sign(global_position.x - from_position.x))
	if dir == 0:
		dir = 1
	velocity = Vector2(float(dir) * KNOCKBACK, -220.0)
	GameManager.take_damage()

func _on_game_over() -> void:
	die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	emit_signal("player_died")
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/GameOver.tscn")
	)

func collect(id: String) -> void:
	emit_signal("collectible_found", id)
