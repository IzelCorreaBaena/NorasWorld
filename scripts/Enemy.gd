extends CharacterBody2D

@export var patrol_distance : float = 120.0
@export var speed           : float = 60.0
@export var damage          : int   = 1

var start_pos   : Vector2
var direction   := 1
var dist_moved  := 0.0

const GRAVITY := 900.0

@onready var sprite = $Sprite2D

func _ready() -> void:
	start_pos = global_position
	add_to_group("enemy")
	_draw_enemy()
	$DetectArea.body_entered.connect(_on_area_body_entered)

func _draw_enemy() -> void:
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.8, 0.3, 0.1, 1.0))
	sprite.texture = ImageTexture.create_from_image(img)

func _physics_process(delta: float) -> void:
	# Gravedad
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0

	# Patrulla
	velocity.x = direction * speed
	dist_moved += speed * delta

	if dist_moved >= patrol_distance:
		direction  *= -1
		dist_moved  = 0
		sprite.flip_h = direction < 0

	move_and_slide()

	# Detectar colision con paredes para girar
	if is_on_wall():
		direction  *= -1
		dist_moved  = 0

func _on_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(global_position)
